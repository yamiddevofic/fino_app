import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/sync_outbox.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

const categoriesBoxName = 'categoriesBox';
const maxCategoryLength = 24;

/// Categorías de cada sección: las predefinidas de [RecordKind] más las que
/// crea el usuario, guardadas como una lista de textos por sección.
class CategoryProvider with ChangeNotifier {
  CategoryProvider()
    : _box = Hive.box<List<dynamic>>(categoriesBoxName),
      _outbox = SyncOutbox();

  final Box<List<dynamic>> _box;
  final SyncOutbox _outbox;

  Future<void> _mark(
    RecordKind kind,
    Iterable<String> names,
    PendingChange change,
  ) async {
    for (final name in names) {
      await _outbox.categoryChanged(kind, name, change);
    }
  }

  List<String> custom(RecordKind kind) =>
      (_box.get(kind.name) ?? const []).cast<String>();

  /// Predefinidas, luego las del usuario y "Otro" siempre al final.
  List<String> all(RecordKind kind) => [
    ...kind.categories.where((c) => c != 'Otro'),
    ...custom(kind),
    if (kind.categories.contains('Otro')) 'Otro',
  ];

  bool isCustom(RecordKind kind, String name) => custom(kind).contains(name);

  /// Mensaje de error para un nombre nuevo, o `null` si es válido.
  String? validate(RecordKind kind, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Escribe un nombre';
    if (trimmed.length > maxCategoryLength) {
      return 'Máximo $maxCategoryLength caracteres';
    }
    final lower = trimmed.toLowerCase();
    if (all(kind).any((c) => c.toLowerCase() == lower)) {
      return 'Esa categoría ya existe';
    }
    return null;
  }

  Future<void> add(RecordKind kind, String name) async {
    assert(validate(kind, name) == null);
    await _box.put(kind.name, [...custom(kind), name.trim()]);
    await _mark(kind, [name.trim()], PendingChange.upsert);
    notifyListeners();
  }

  /// Sustituye las categorías del usuario de todas las secciones. Una
  /// sección ausente de [custom] queda sin categorías propias.
  Future<void> replaceAll(Map<RecordKind, List<String>> categories) async {
    for (final kind in RecordKind.values) {
      final kept = categories[kind] ?? const [];
      await _mark(
        kind,
        custom(kind).where((c) => !kept.contains(c)),
        PendingChange.delete,
      );
      await _mark(kind, kept, PendingChange.upsert);
    }
    await _box.clear();
    for (final MapEntry(:key, :value) in categories.entries) {
      if (value.isNotEmpty) await _box.put(key.name, value);
    }
    notifyListeners();
  }

  /// Agrega las categorías de [categories] que aún no existen en su sección
  /// y devuelve cuántas se agregaron.
  Future<int> addAll(Map<RecordKind, List<String>> categories) async {
    var added = 0;
    for (final MapEntry(key: kind, value: names) in categories.entries) {
      final current = custom(kind);
      final taken = {for (final c in all(kind)) c.toLowerCase()};
      final fresh = [
        for (final name in names.map((n) => n.trim()))
          if (name.isNotEmpty &&
              name.length <= maxCategoryLength &&
              taken.add(name.toLowerCase()))
            name,
      ];
      if (fresh.isEmpty) continue;
      await _box.put(kind.name, [...current, ...fresh]);
      await _mark(kind, fresh, PendingChange.upsert);
      added += fresh.length;
    }
    if (added > 0) notifyListeners();
    return added;
  }

  /// Quita una categoría del usuario. Los registros que la usan la conservan.
  Future<void> remove(RecordKind kind, String name) async {
    await _box.put(kind.name, [...custom(kind)]..remove(name));
    await _mark(kind, [name], PendingChange.delete);
    notifyListeners();
  }

  /// Deja todas las categorías propias pendientes de subir. Se usa en la
  /// primera sincronización de una cuenta.
  Future<void> markAllPending() async {
    for (final kind in RecordKind.values) {
      await _mark(kind, custom(kind), PendingChange.upsert);
    }
  }

  /// Aplica cambios bajados de Supabase sin volver a marcarlos como
  /// pendientes. [remote] asocia cada sección con sus categorías: nombre y
  /// `true` si se borró en otro dispositivo.
  Future<void> applyRemote(Map<RecordKind, Map<String, bool>> remote) async {
    if (remote.isEmpty) return;
    for (final MapEntry(key: kind, value: changes) in remote.entries) {
      final names = [...custom(kind)];
      for (final MapEntry(key: name, value: deleted) in changes.entries) {
        if (deleted) {
          names.remove(name);
        } else if (!names.contains(name)) {
          names.add(name);
        }
      }
      await _box.put(kind.name, names);
    }
    notifyListeners();
  }
}
