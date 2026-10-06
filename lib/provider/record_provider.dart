import 'package:fino_app/models/finance_record.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Provider genérico sobre una caja de Hive con registros financieros.
///
/// Las operaciones usan la clave de Hive del registro y no su posición, de
/// modo que ordenar o filtrar la lista en la interfaz no afecta a qué se
/// edita o se borra.
class RecordProvider<T extends FinanceRecord> with ChangeNotifier {
  RecordProvider(String boxName, this.builder) : _box = Hive.box<T>(boxName) {
    _reload();
  }

  final Box<T> _box;
  final RecordBuilder<T> builder;

  List<T> _records = [];

  /// Registros ordenados del más reciente al más antiguo. Los registros
  /// antiguos sin fecha van al final.
  List<T> get records => _records;

  double get total => _records.fold(0.0, (sum, r) => sum + r.amount);

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

  Future<void> add(T record) async {
    await _box.add(record);
    _reload();
  }

  Future<void> update(T original, T updated) async {
    await _box.put(original.key, updated);
    _reload();
  }

  /// Borra [record] y devuelve una copia que se puede pasar a [add] para
  /// deshacer la operación.
  Future<T> delete(T record) async {
    final copy = builder(
      name: record.name,
      amount: record.amount,
      date: record.date,
      category: record.category,
      note: record.note,
    );
    await record.delete();
    _reload();
    return copy;
  }
}
