import 'package:fino_app/models/record_kind.dart';
import 'package:hive/hive.dart';

const syncOutboxBoxName = 'syncOutbox';

/// Cambio local pendiente de subir a Supabase.
enum PendingChange { upsert, delete }

/// Cambios hechos en el dispositivo que aún no se han subido.
///
/// Guarda solo qué cambió, no el contenido: al sincronizar se lee el estado
/// actual de cada registro o categoría. Así, varios cambios seguidos del
/// mismo registro se suben una sola vez.
class SyncOutbox {
  SyncOutbox() : _box = Hive.box<String>(syncOutboxBoxName);

  final Box<String> _box;

  static const _record = 'r:';
  static const _category = 'c:';

  Future<void> recordChanged(String id, PendingChange change) =>
      _box.put('$_record$id', change.name);

  Future<void> recordsChanged(Iterable<String> ids, PendingChange change) =>
      _box.putAll({for (final id in ids) '$_record$id': change.name});

  Future<void> categoryChanged(
    RecordKind kind,
    String name,
    PendingChange change,
  ) => _box.put('$_category${kind.name}:$name', change.name);

  /// Registros pendientes: UUID y tipo de cambio.
  Map<String, PendingChange> get records => {
    for (final MapEntry(:key, :value) in _box.toMap().entries)
      if ((key as String).startsWith(_record))
        key.substring(_record.length): PendingChange.values.byName(value),
  };

  /// Categorías pendientes: sección, nombre y tipo de cambio.
  List<(RecordKind, String, PendingChange)> get categories => [
    for (final MapEntry(:key, :value) in _box.toMap().entries)
      if ((key as String).startsWith(_category))
        if (key.substring(_category.length).split(':') case [
          final kind,
          ...final rest,
        ])
          (
            RecordKind.values.byName(kind),
            rest.join(':'),
            PendingChange.values.byName(value),
          ),
  ];

  bool get isEmpty => _box.isEmpty;

  int get length => _box.length;

  bool hasRecord(String id) => _box.containsKey('$_record$id');

  /// Quita los cambios ya subidos, salvo los que volvieron a cambiar
  /// mientras se subían.
  Future<void> clearRecords(Map<String, PendingChange> uploaded) =>
      _box.deleteAll([
        for (final MapEntry(key: id, value: change) in uploaded.entries)
          if (_box.get('$_record$id') == change.name) '$_record$id',
      ]);

  Future<void> clearCategories(
    List<(RecordKind, String, PendingChange)> uploaded,
  ) => _box.deleteAll([
    for (final (kind, name, change) in uploaded)
      if (_box.get('$_category${kind.name}:$name') == change.name)
        '$_category${kind.name}:$name',
  ]);

  /// Avisa cada vez que cambia la bandeja.
  Stream<BoxEvent> watch() => _box.watch();
}
