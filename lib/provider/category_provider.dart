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

  /// Quita una categoría del usuario. Los registros que la usan la conservan.
  Future<void> remove(RecordKind kind, String name) async {
    await _box.put(kind.name, [...custom(kind)]..remove(name));
    notifyListeners();
  }
}
