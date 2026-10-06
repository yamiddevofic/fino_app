import 'dart:io';

import 'package:fino_app/models/incomes_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Adaptador idéntico al que generaba hive_generator en la versión 1.0.0,
/// cuando los registros solo tenían nombre y monto.
class _LegacyIncome {
  _LegacyIncome(this.name, this.amount);
  final String name;
  final double amount;
}

class _LegacyIncomeAdapter extends TypeAdapter<_LegacyIncome> {
  @override
  final int typeId = 1;

  @override
  _LegacyIncome read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, _LegacyIncome obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount);
  }
}

void main() {
  test(
    'los registros guardados por la versión anterior se siguen leyendo',
    () async {
      final dir = await Directory.systemTemp.createTemp('fino_legacy_');
      Hive.init(dir.path);

      Hive.registerAdapter(_LegacyIncomeAdapter());
      final legacy = await Hive.openBox<_LegacyIncome>('incomesBox');
      await legacy.add(_LegacyIncome('Salario', 1500000));
      await legacy.close();

      Hive.registerAdapter(IncomeAdapter(), override: true);
      final box = await Hive.openBox<Income>('incomesBox');
      final income = box.values.single;

      expect(income.name, 'Salario');
      expect(income.amount, 1500000);
      expect(income.date, isNull);
      expect(income.category, isNull);
      expect(income.note, isNull);

      await Hive.close();
      await dir.delete(recursive: true);
    },
  );
}
