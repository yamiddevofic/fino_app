import 'dart:typed_data';

import 'package:fino_app/main.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/models/settings_model.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Avanza el reloj lo suficiente para que terminen las animaciones finitas.
/// No usa pumpAndSettle porque el fondo se anima en bucle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('es_CO');
    registerAdapters();
  });

  setUp(() async {
    // Cajas en memoria: no tocan el disco, así que funcionan con el reloj
    // simulado de testWidgets.
    await Hive.openBox<Income>(RecordKind.income.boxName, bytes: Uint8List(0));
    await Hive.openBox<Expense>(
      RecordKind.expense.boxName,
      bytes: Uint8List(0),
    );
    await Hive.openBox<Buy>(RecordKind.buy.boxName, bytes: Uint8List(0));
    await Hive.openBox<Debt>(RecordKind.debt.boxName, bytes: Uint8List(0));
    await Hive.openBox<Settings>(settingsBoxName, bytes: Uint8List(0));
    await Hive.openBox<List<dynamic>>(categoriesBoxName, bytes: Uint8List(0));
  });

  tearDown(() => Hive.close());

  Future<void> pumpApp(WidgetTester tester) async {
    // Tamaño de un teléfono típico.
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const AppProviders(child: FinoApp()));
    await settle(tester);
  }

  testWidgets('muestra el resumen y la navegación inferior', (tester) async {
    await pumpApp(tester);

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Balance general'), findsOneWidget);
    for (final label in ['Inicio', 'Ingresos', 'Gastos', 'Deudas', 'Compras']) {
      expect(navItem(label), findsOneWidget);
    }
    expect(find.text('Sin movimientos todavía'), findsOneWidget);
  });

  testWidgets('agregar un ingreso actualiza la lista y el balance', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(navItem('Ingresos'));
    await settle(tester);
    expect(find.text('Aún no hay ingresos'), findsOneWidget);

    await tester.tap(find.text('Agregar ingreso'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).at(0), '1.500.000');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nómina');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Salario'));
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await settle(tester);

    expect(find.text(r'+$ 1.500.000'), findsOneWidget);
    expect(find.text('1 registro'), findsOneWidget);

    await tester.tap(navItem('Inicio'));
    await settle(tester);
    expect(find.text('Nómina'), findsOneWidget);
    expect(find.text(r'$ 1.500.000'), findsWidgets);
  });

  testWidgets('el formulario rechaza datos inválidos', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Gastos'));
    await settle(tester);

    await tester.tap(find.text('Agregar gasto'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await settle(tester);

    expect(find.text('Ingresa un monto mayor que cero'), findsOneWidget);
    expect(find.text('Ingresa una descripción'), findsOneWidget);
  });

  testWidgets('pagar una deuda la pasa a gastos y actualiza el balance', (
    tester,
  ) async {
    await Hive.box<Income>(
      RecordKind.income.boxName,
    ).add(Income(name: 'Nómina', amount: 1000000, date: DateTime(2026, 9, 1)));
    await Hive.box<Debt>(
      RecordKind.debt.boxName,
    ).add(Debt(name: 'Tarjeta', amount: 300000, date: DateTime(2026, 9, 1)));
    await pumpApp(tester);

    // Pendiente: no afecta el balance, sí el proyectado.
    expect(find.text(r'$ 1.000.000'), findsWidgets);
    expect(find.text(r'Proyectado: $ 700.000'), findsOneWidget);

    await tester.tap(navItem('Deudas'));
    await settle(tester);
    expect(find.text('1 registro · 1 pendiente'), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar como pagada'));
    await settle(tester);
    expect(find.text('1 registro · todas pagadas'), findsOneWidget);
    expect(find.text(r'Se registró un gasto de $ 300.000'), findsOneWidget);
    final expense = Hive.box<Expense>(RecordKind.expense.boxName).values.single;
    expect(expense.category, 'Deudas');

    await tester.tap(navItem('Inicio'));
    await settle(tester);
    expect(find.text('Todas pagadas'), findsOneWidget);
    expect(find.text(r'$ 700.000'), findsOneWidget);
    expect(find.textContaining('Proyectado'), findsNothing);
  });

  testWidgets('marcar una compra sin precio pide el precio', (tester) async {
    await Hive.box<Buy>(RecordKind.buy.boxName).add(
      Buy(
        name: 'Nevera',
        amount: 0,
        date: DateTime(2026, 9, 1),
        pricePending: true,
      ),
    );
    await pumpApp(tester);
    await tester.tap(navItem('Compras'));
    await settle(tester);

    await tester.tap(find.byTooltip('Marcar como comprada'));
    await settle(tester);
    expect(find.text('¿Cuánto costó Nevera?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '2.500.000');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await settle(tester);

    final buy = Hive.box<Buy>(RecordKind.buy.boxName).values.single;
    expect(buy.done, isTrue);
    expect(buy.amount, 2500000);
    expect(
      Hive.box<Expense>(RecordKind.expense.boxName).values.single.amount,
      2500000,
    );
  });

  testWidgets('se puede crear una categoría desde el formulario', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(navItem('Gastos'));
    await settle(tester);
    await tester.tap(find.text('Agregar gasto'));
    await settle(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'Nueva'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, 'Mascotas');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
    await settle(tester);

    expect(find.widgetWithText(ChoiceChip, 'Mascotas'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Mascotas'),
    );
    expect(chip.selected, isTrue);
    expect(Hive.box<List<dynamic>>(categoriesBoxName).get('expense'), [
      'Mascotas',
    ]);
  });

  testWidgets('una compra se puede guardar con precio por definir', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(navItem('Compras'));
    await settle(tester);

    await tester.tap(find.text('Agregar compra'));
    await settle(tester);
    await tester.tap(find.text('Precio por definir'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), 'Nevera');
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await settle(tester);

    final buy = Hive.box<Buy>(RecordKind.buy.boxName).values.single;
    expect(buy.pricePending, isTrue);
    expect(buy.amount, 0);
    expect(find.text('Precio por definir'), findsOneWidget);
    expect(find.text('1 registro · 1 por comprar'), findsOneWidget);
  });

  testWidgets('el tema elegido se guarda', (tester) async {
    await pumpApp(tester);
    expect(Hive.box<Settings>(settingsBoxName).isEmpty, isTrue);

    await tester.tap(find.byTooltip('Modo oscuro'));
    await settle(tester);

    expect(
      Hive.box<Settings>(settingsBoxName).values.single.isDarkMode,
      isTrue,
    );
    expect(find.byTooltip('Modo claro'), findsOneWidget);
  });
}
