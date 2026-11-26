import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/provider/sync_outbox.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Provider genérico sobre una caja de Hive con registros financieros.
///
/// Las operaciones usan la clave de Hive del registro y no su posición, de
/// modo que ordenar o filtrar la lista en la interfaz no afecta a qué se
/// edita o se borra.
///
/// Cada cambio queda anotado en [SyncOutbox] para subirlo a Supabase.
class RecordProvider<T extends FinanceRecord> with ChangeNotifier {
  RecordProvider(String boxName, this.builder)
    : _box = Hive.box<T>(boxName),
      _outbox = SyncOutbox() {
    _reload();
  }

  final Box<T> _box;
  final SyncOutbox _outbox;
  final RecordBuilder<T> builder;

  List<T> _records = [];

  /// Registros ordenados del más reciente al más antiguo. Los registros
  /// antiguos sin fecha van al final.
  List<T> get records => _records;

  /// Suma de todos los registros. En deudas incluye las canceladas: el
  /// dinero con que se pagaron ya salió del balance.
  double get total => _records.fold(0.0, (sum, r) => sum + r.amount);

  /// Registros aún no marcados como hechos (deudas por pagar, compras por
  /// hacer).
  Iterable<T> get pending => _records.where((r) => !r.done);

  double get pendingTotal => pending.fold(0.0, (sum, r) => sum + r.amount);

  void _reload() {
    final entries = _box.values.toList().asMap().entries.toList();
    entries.sort((a, b) {
      final da = a.value.date, db = b.value.date;
      if (da == null && db == null) return b.key.compareTo(a.key);
      if (da == null) return 1;
      if (db == null) return -1;
      final byDate = db.compareTo(da);
      return byDate != 0 ? byDate : b.key.compareTo(a.key);
    });
    _records = entries.map((e) => e.value).toList();
    notifyListeners();
  }

  /// Registros con su clave en la caja, en el orden en que se guardaron.
  Map<int, T> get entries => {
    for (final key in _box.keys) key as int: _box.get(key) as T,
  };

  /// Clave en la caja del registro con [id], o `null` si no está.
  int? keyOf(String id) {
    for (final MapEntry(:key, :value) in entries.entries) {
      if (value.id == id) return key;
    }
    return null;
  }

  /// Devuelve [record] con un UUID, asignándole uno nuevo si no lo tiene.
  T _withId(T record, [String? id]) {
    final current = id ?? record.id;
    if (current != null && current == record.id) return record;
    return copyRecord(builder, record, id: current ?? newRecordId());
  }

  Future<void> _changed(Iterable<T> records) =>
      _outbox.recordsChanged(records.map((r) => r.id!), PendingChange.upsert);

  /// Sustituye todos los registros por [entries] conservando sus claves, de
  /// modo que los enlaces de deudas y compras con su gasto siguen valiendo.
  Future<void> replaceAll(Map<int, T> entries) async {
    final withIds = {
      for (final MapEntry(:key, :value) in entries.entries) key: _withId(value),
    };
    final kept = {for (final r in withIds.values) r.id};
    final removed = [
      for (final r in _box.values)
        if (!kept.contains(r.id)) ?r.id,
    ];
    await _box.clear();
    await _box.putAll(withIds);
    await _outbox.recordsChanged(removed, PendingChange.delete);
    await _changed(withIds.values);
    _reload();
  }

  /// Guarda [records] y devuelve sus claves, en el mismo orden.
  Future<List<int>> addAll(List<T> records) async {
    final withIds = records.map(_withId).toList();
    final keys = (await _box.addAll(withIds)).cast<int>().toList();
    await _changed(withIds);
    _reload();
    return keys;
  }

  /// Guarda [record] y devuelve su clave en la caja.
  Future<int> add(T record) async {
    final withId = _withId(record);
    final key = await _box.add(withId);
    await _changed([withId]);
    _reload();
    return key;
  }

  /// Reemplaza [original] por [updated], que sigue siendo el mismo registro
  /// aunque se haya construido de nuevo en el formulario.
  Future<void> update(T original, T updated) async {
    final withId = _withId(updated, original.id ?? updated.id);
    await _box.put(original.key, withId);
    await _changed([withId]);
    _reload();
  }

  /// Borra el registro con [key], si todavía existe.
  Future<void> deleteKey(int key) async {
    final record = _box.get(key);
    if (record == null) return;
    await _box.delete(key);
    if (record.id case final id?) {
      await _outbox.recordChanged(id, PendingChange.delete);
    }
    _reload();
  }

  /// Borra [record] y devuelve una copia que se puede pasar a [add] para
  /// deshacer la operación.
  Future<T> delete(T record) async {
    final copy = copyRecord(builder, record);
    await record.delete();
    if (record.id case final id?) {
      await _outbox.recordChanged(id, PendingChange.delete);
    }
    _reload();
    return copy;
  }

  /// Asigna un UUID a los registros de versiones anteriores que no lo
  /// tienen y los deja pendientes de subir.
  Future<void> ensureIds() async {
    final missing = {
      for (final MapEntry(:key, :value) in entries.entries)
        if (value.id == null) key: _withId(value),
    };
    if (missing.isEmpty) return;
    await _box.putAll(missing);
    await _changed(missing.values);
    _reload();
  }

  /// Aplica cambios bajados de Supabase sin volver a marcarlos como
  /// pendientes. [changes] asocia cada UUID con su contenido nuevo, o con
  /// `null` si se borró en otro dispositivo.
  Future<void> applyRemote(Map<String, T?> changes) async {
    if (changes.isEmpty) return;
    final keys = {
      for (final MapEntry(:key, :value) in entries.entries) ?value.id: key,
    };
    final deleted = <int>[];
    final updated = <int, T>{};
    final added = <T>[];
    for (final MapEntry(key: id, :value) in changes.entries) {
      final key = keys[id];
      if (value == null) {
        if (key != null) deleted.add(key);
      } else if (key != null) {
        updated[key] = value;
      } else {
        added.add(value);
      }
    }
    await _box.deleteAll(deleted);
    await _box.putAll(updated);
    await _box.addAll(added);
    _reload();
  }
}
