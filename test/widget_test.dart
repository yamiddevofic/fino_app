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
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fino_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(BuyAdapter());
    Hive.registerAdapter(DebtAdapter());
  });

  setUp(() async {
    await Hive.openBox<Income>('incomesBox');
    await Hive.openBox<Expense>('expensesBox');
    await Hive.openBox<Buy>('buysBox');
    await Hive.openBox<Debt>('debtBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('IncomeProvider', () {
    test('agrega, actualiza y elimina ingresos', () async {
      final provider = IncomeProvider();
      expect(provider.incomes, isEmpty);

      await provider.addIncome(Income(name: 'Salario', amount: 1000));
      expect(provider.incomes.single.name, 'Salario');

      await provider.updateIncome(0, Income(name: 'Salario', amount: 1500));
      expect(provider.incomes.single.amount, 1500);

      await provider.deleteIncome(0);
      expect(provider.incomes, isEmpty);
    });
  });

  group('ExpenseProvider', () {
    test('agrega y elimina gastos', () async {
      final provider = ExpenseProvider();
      await provider.addExpense(Expense(name: 'Arriendo', amount: 500));
      await provider.addExpense(Expense(name: 'Comida', amount: 200));
      expect(provider.expenses.length, 2);

      await provider.deleteExpense(0);
      expect(provider.expenses.single.name, 'Comida');
    });
  });

  group('DebtProvider', () {
    test('agrega y actualiza deudas', () async {
      final provider = DebtProvider();
      await provider.addDebt(Debt(name: 'Tarjeta', amount: 300));
      await provider.updateDebt(0, Debt(name: 'Tarjeta', amount: 250));
      expect(provider.debts.single.amount, 250);
    });
  });

  group('BuyProvider', () {
    test('los datos persisten en la caja de Hive', () async {
      await BuyProvider().addBuy(Buy(name: 'Leche', amount: 5));
      expect(BuyProvider().buys.single.name, 'Leche');
    });
  });

  testWidgets('la app muestra las cinco pestañas', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IncomeProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => BuyProvider()),
          ChangeNotifierProvider(create: (_) => DebtProvider()),
        ],
        child: const finoApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Fino App'), findsOneWidget);
    for (final label in ['Home', 'Ingresos', 'Gastos', 'Deudas', 'Compras']) {
      expect(find.text(label), findsWidgets);
    }
  });
}
