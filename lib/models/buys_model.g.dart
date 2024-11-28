// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buys_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BuyAdapter extends TypeAdapter<Buy> {
  @override
  final int typeId = 2;

  @override
  Buy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Buy(
      name: fields[0] as String,
      amount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Buy obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
