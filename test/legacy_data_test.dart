import 'dart:io';

import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
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

  test('los registros guardados por v1.0.0 se siguen leyendo', () async {
    final dir = await Directory.systemTemp.createTemp('fino_v1_');
    Hive.init(dir.path);

    // Formato de v1.0.0: compra con fecha (2), completada (3) y precio
    // pendiente (4); deuda con fecha (2) y cancelada (3).
    Hive.registerAdapter(_V1BuyAdapter(), override: true);
    Hive.registerAdapter(_V1DebtAdapter(), override: true);
    final buys = await Hive.openBox<_V1Buy>('buysBox');
    await buys.add(_V1Buy('Leche', 5000, DateTime(2026, 9, 1), [true, false]));
    await buys.add(_V1Buy('Nevera', 0, DateTime(2026, 9, 2), [false, true]));
    await buys.close();
    final debts = await Hive.openBox<_V1Debt>('debtBox');
    await debts.add(_V1Debt('Tarjeta', 300, DateTime(2026, 8, 1), [true]));
    await debts.close();

    Hive.registerAdapter(BuyAdapter(), override: true);
    Hive.registerAdapter(DebtAdapter(), override: true);
    final newBuys = (await Hive.openBox<Buy>('buysBox')).values.toList();
    final debt = (await Hive.openBox<Debt>('debtBox')).values.single;

    expect(newBuys[0].name, 'Leche');
    expect(newBuys[0].done, isTrue);
    expect(newBuys[0].pricePending, isFalse);
    expect(newBuys[0].date, DateTime(2026, 9, 1));
    expect(newBuys[1].pricePending, isTrue);
    expect(newBuys[1].category, isNull);
    expect(debt.done, isTrue);
    expect(debt.note, isNull);

    await Hive.close();
    await dir.delete(recursive: true);
  });
}

class _V1Record {
  _V1Record(this.name, this.amount, this.date, this.flags);
  final String name;
  final double amount;
  final DateTime date;
  final List<bool> flags;
}

/// Escribe como los adaptadores generados de v1.0.0: campos 0-2 y después
/// los booleanos de estado a partir del campo 3.
abstract class _V1Adapter<R extends _V1Record> extends TypeAdapter<R> {
  @override
  R read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, R obj) {
    writer
      ..writeByte(3 + obj.flags.length)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date);
    for (var i = 0; i < obj.flags.length; i++) {
      writer
        ..writeByte(3 + i)
        ..write(obj.flags[i]);
    }
  }
}

class _V1Buy extends _V1Record {
  _V1Buy(super.name, super.amount, super.date, super.flags);
}

class _V1Debt extends _V1Record {
  _V1Debt(super.name, super.amount, super.date, super.flags);
}

class _V1BuyAdapter extends _V1Adapter<_V1Buy> {
  @override
  final int typeId = 2;
}

class _V1DebtAdapter extends _V1Adapter<_V1Debt> {
  @override
  final int typeId = 3;
}
