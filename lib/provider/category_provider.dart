import 'package:fino_app/models/record_kind.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

const categoriesBoxName = 'categoriesBox';
const maxCategoryLength = 24;

/// Categorías de cada sección: las predefinidas de [RecordKind] más las que
/// crea el usuario, guardadas como una lista de textos por sección.
class CategoryProvider with ChangeNotifier {
  CategoryProvider() : _box = Hive.box<List<dynamic>>(categoriesBoxName);

  final Box<List<dynamic>> _box;

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
    notifyListeners();
  }

  /// Sustituye las categorías del usuario de todas las secciones. Una
  /// sección ausente de [custom] queda sin categorías propias.
  Future<void> replaceAll(Map<RecordKind, List<String>> custom) async {
    await _box.clear();
    for (final MapEntry(:key, :value) in custom.entries) {
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
      added += fresh.length;
    }
    if (added > 0) notifyListeners();
    return added;
  }

  /// Quita una categoría del usuario. Los registros que la usan la conservan.
  Future<void> remove(RecordKind kind, String name) async {
    await _box.put(kind.name, [...custom(kind)]..remove(name));
    notifyListeners();
  }
}
