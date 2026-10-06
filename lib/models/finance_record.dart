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
    });

/// Copia [record] cambiando solo los valores indicados.
T copyRecord<T extends FinanceRecord>(
  RecordBuilder<T> builder,
  T record, {
  double? amount,
  bool? done,
  bool? pricePending,
}) => builder(
  name: record.name,
  amount: amount ?? record.amount,
  date: record.date,
  category: record.category,
  note: record.note,
  done: done ?? record.done,
  pricePending: pricePending ?? record.pricePending,
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
    );
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.note);
  }
}
