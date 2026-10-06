import 'dart:io';

import 'package:fino_app/main.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fino_test_');
    Hive.init(tempDir.path);
    registerAdapters();
  });

  setUp(openBoxes);

  tearDown(() => Hive.deleteFromDisk());

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('agrega, actualiza y elimina por registro, no por posición', () async {
    final provider = IncomeProvider();
    await provider.add(Income(name: 'Salario', amount: 1000));
    await provider.add(Income(name: 'Bono', amount: 200));

    final bono = provider.records.firstWhere((r) => r.name == 'Bono');
    await provider.update(bono, Income(name: 'Bono', amount: 250));
    expect(provider.total, 1250);

    await provider.delete(
      provider.records.firstWhere((r) => r.name == 'Salario'),
    );
    expect(provider.records.single.amount, 250);
  });

  test('ordena del más reciente al más antiguo; sin fecha al final', () async {
    final provider = ExpenseProvider();
    await provider.add(Expense(name: 'Viejo', amount: 1));
    await provider.add(
      Expense(name: 'Enero', amount: 1, date: DateTime(2026, 1, 10)),
    );
    await provider.add(
      Expense(name: 'Marzo', amount: 1, date: DateTime(2026, 3, 2)),
    );
    expect(provider.records.map((r) => r.name), ['Marzo', 'Enero', 'Viejo']);
  });

  test('delete devuelve una copia que permite deshacer', () async {
    final provider = DebtProvider();
    await provider.add(
      Debt(
        name: 'Tarjeta',
        amount: 300,
        date: DateTime(2026, 5, 1),
        category: 'Tarjeta',
        note: 'Cuota 3/12',
      ),
    );
    final copy = await provider.delete(provider.records.single);
    expect(provider.records, isEmpty);

    await provider.add(copy);
    final restored = provider.records.single;
    expect(restored.name, 'Tarjeta');
    expect(restored.category, 'Tarjeta');
    expect(restored.note, 'Cuota 3/12');
    expect(restored.date, DateTime(2026, 5, 1));
  });

  test('los campos nuevos se guardan en disco', () async {
    await BuyProvider().add(
      Buy(
        name: 'Leche',
        amount: 5,
        date: DateTime(2026, 2, 3),
        category: 'Mercado',
      ),
    );
    await Hive.box<Buy>('buysBox').close();
    await Hive.openBox<Buy>('buysBox');

    final buy = BuyProvider().records.single;
    expect(buy.category, 'Mercado');
    expect(buy.date, DateTime(2026, 2, 3));
  });

  test('toggleDone marca y desmarca sin perder datos', () async {
    final provider = DebtProvider();
    await provider.add(
      Debt(name: 'Préstamo', amount: 1000, category: 'Préstamo', note: 'Mamá'),
    );
    await provider.add(Debt(name: 'Tarjeta', amount: 500));

    await provider.toggleDone(
      provider.records.firstWhere((r) => r.name == 'Préstamo'),
    );
    final loan = provider.records.firstWhere((r) => r.name == 'Préstamo');
    expect(loan.done, isTrue);
    expect(loan.category, 'Préstamo');
    expect(loan.note, 'Mamá');
    expect(provider.total, 1500);
    expect(provider.pendingTotal, 500);

    await provider.toggleDone(loan);
    expect(provider.pendingTotal, 1500);
  });
}
