import 'dart:math';

import 'package:hive/hive.dart';

/// Base común de ingresos, gastos, deudas y compras.
///
/// Campos de Hive, compatibles con todas las versiones publicadas:
///
/// | Campo | Contenido | Desde |
/// | --- | --- | --- |
/// | 0 | nombre | 1.0.0 |
/// | 1 | monto | 1.0.0 |
/// | 2 | fecha | v1.0.0 (rediseño) |
/// | 3 | hecho: deuda cancelada o compra realizada | v1.0.0 (rediseño) |
/// | 4 | compra con precio por definir | v1.0.0 (rediseño) |
/// | 5 | categoría | 1.1.0 |
/// | 6 | nota | 1.1.0 |
/// | 7 | clave del gasto generado al pagar la deuda o hacer la compra | 1.2.0 |
/// | 8 | identificador único para sincronizar con Supabase | 1.5.0 |
///
/// Todos los campos salvo 0 y 1 son opcionales, de modo que los registros
/// guardados por versiones anteriores se siguen leyendo.
abstract class FinanceRecord extends HiveObject {
  FinanceRecord({
    required this.name,
    required this.amount,
    this.date,
    this.category,
    this.note,
    this.done = false,
    this.pricePending = false,
    this.expenseKey,
    this.id,
  });

  final String name;
  final double amount;
  final DateTime? date;
  final String? category;
  final String? note;

  /// Deuda cancelada o compra realizada. No aplica a ingresos ni gastos.
  final bool done;

  /// Compra registrada sin precio; [amount] vale 0 hasta que se defina.
  final bool pricePending;

  /// Clave en la caja de gastos del gasto que se registró al marcar esta
  /// deuda o compra como lista. Se usa para borrarlo si se desmarca.
  final int? expenseKey;

  /// UUID con el que se sincroniza. Los registros de versiones anteriores
  /// no lo tienen hasta que [ensureRecordIds] se lo asigna.
  final String? id;
}

typedef RecordBuilder<T extends FinanceRecord> =
    T Function({
      required String name,
      required double amount,
      DateTime? date,
      String? category,
      String? note,
      bool done,
      bool pricePending,
      int? expenseKey,
      String? id,
    });

const _keep = Object();

final _random = Random.secure();

/// UUID versión 4 aleatorio.
String newRecordId() {
  final b = List<int>.generate(16, (_) => _random.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Copia [record] cambiando solo los valores indicados. [expenseKey] acepta
/// `null` para quitar el enlace con el gasto. La copia conserva el [id], de
/// modo que sigue siendo el mismo registro al sincronizar.
T copyRecord<T extends FinanceRecord>(
  RecordBuilder<T> builder,
  T record, {
  double? amount,
  bool? done,
  bool? pricePending,
  Object? expenseKey = _keep,
  String? id,
}) => builder(
  name: record.name,
  amount: amount ?? record.amount,
  date: record.date,
  category: record.category,
  note: record.note,
  done: done ?? record.done,
  pricePending: pricePending ?? record.pricePending,
  expenseKey: identical(expenseKey, _keep)
      ? record.expenseKey
      : expenseKey as int?,
  id: id ?? record.id,
);

/// Adaptador de Hive compartido por todos los tipos de registro.
class FinanceRecordAdapter<T extends FinanceRecord> extends TypeAdapter<T> {
  FinanceRecordAdapter(this.typeId, this.builder);

  @override
  final int typeId;
  final RecordBuilder<T> builder;

  @override
  T read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, Object?>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Lectura tolerante: un campo con un tipo inesperado se ignora en lugar
    // de impedir que se abra la caja.
    V? field<V>(int index) => switch (fields[index]) {
      final V value => value,
      _ => null,
    };
    return builder(
      name: field<String>(0) ?? '',
      amount: field<num>(1)?.toDouble() ?? 0,
      date: field<DateTime>(2),
      done: field<bool>(3) ?? false,
      pricePending: field<bool>(4) ?? false,
      category: field<String>(5),
      note: field<String>(6),
      expenseKey: field<int>(7),
      id: field<String>(8),
    );
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.done)
      ..writeByte(4)
      ..write(obj.pricePending)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.expenseKey)
      ..writeByte(8)
      ..write(obj.id);
  }
}
