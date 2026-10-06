import 'package:hive/hive.dart';

/// Base común de ingresos, gastos, deudas y compras.
///
/// Los campos 0 y 1 existen desde la primera versión de la app; los campos
/// 2 a 4 son opcionales para que los registros antiguos se sigan leyendo.
abstract class FinanceRecord extends HiveObject {
  FinanceRecord({
    required this.name,
    required this.amount,
    this.date,
    this.category,
    this.note,
  });

  final String name;
  final double amount;
  final DateTime? date;
  final String? category;
  final String? note;
}

typedef RecordBuilder<T extends FinanceRecord> =
    T Function({
      required String name,
      required double amount,
      DateTime? date,
      String? category,
      String? note,
    });

/// Adaptador de Hive compartido por todos los tipos de registro.
class FinanceRecordAdapter<T extends FinanceRecord> extends TypeAdapter<T> {
  FinanceRecordAdapter(this.typeId, this.builder);

  @override
  final int typeId;
  final RecordBuilder<T> builder;

  @override
  T read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return builder(
      name: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      date: fields[2] as DateTime?,
      category: fields[3] as String?,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.note);
  }
}
