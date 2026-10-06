import 'dart:io';

import 'package:fino_app/app_colors.dart';
import 'package:fino_app/app_theme.dart';
import 'package:fino_app/main.dart' show FinoApp;
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/settings_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/widgets/history_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.path);
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(BuyAdapter());
    Hive.registerAdapter(DebtAdapter());
    await Hive.openBox<Income>('incomesBox');
    await Hive.openBox<Expense>('expensesBox');
    await Hive.openBox<Buy>('buysBox');
    await Hive.openBox<Debt>('debtBox');
    await initializeDateFormatting('es_CO', null);
  });

testWidgets('renders the current home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IncomeProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => BuyProvider()),
          ChangeNotifierProvider(create: (_) => DebtProvider()),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider()..load(),
          ),
        ],
        child: const FinoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fino App'), findsOneWidget);
    expect(find.byKey(const ValueKey('home')), findsOneWidget);
  });

  testWidgets('las secciones se adaptan al ancho de un celular',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IncomeProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => BuyProvider()),
          ChangeNotifierProvider(create: (_) => DebtProvider()),
          ChangeNotifierProvider(
            create: (_) => SettingsProvider()..load(),
          ),
        ],
        child: const FinoApp(),
      ),
    );
    await tester.pumpAndSettle();

    const destinations = {
      'incomes': 'Nuevo ingreso',
      'expenses': 'Nuevo gasto',
      'debts': 'Nueva deuda',
      'buys': 'Nueva compra',
    };
    for (final destination in destinations.entries) {
      await tester.tap(find.byKey(ValueKey(destination.key)));
      await tester.pumpAndSettle();
      expect(find.text(destination.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byTooltip('Usar tema oscuro'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final destination in destinations.entries) {
      await tester.tap(find.byKey(ValueKey(destination.key)));
      await tester.pumpAndSettle();
      expect(find.text(destination.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('el historial muestra con claridad registros antiguos sin fecha',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HistoryList(
            entries: const [
              HistoryEntry(
                title:
                    'Compra antigua con nombre largo para probar la tarjeta móvil',
                amount: 9999.99,
                date: null,
                index: 0,
              ),
            ],
            accentColor: AppColors.forSection(
              AppSection.purchase,
              Brightness.light,
            ),
            emptyMessage: 'Sin compras',
            deleteTitle: 'Eliminar compra',
            deleteMessage: '¿Eliminar esta compra?',
            deletedMessage: 'Compra eliminada',
            onDelete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sin fecha registrada'), findsOneWidget);
    expect(find.text('Fecha no disponible'), findsNothing);
    expect(
        find.textContaining('Compra antigua con nombre largo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('cancelar una deuda la conserva y la descuenta del total pendiente',
      () async {
    await Hive.box<Debt>('debtBox').clear();
    final provider = DebtProvider();
    await provider.addDebt(Debt(name: 'Servicio', amount: 125000));

    expect(provider.pendingTotal, 125000);

    await provider.toggleDebtCancelled(0);

    expect(provider.pendingTotal, 0);
    expect(provider.debts, hasLength(1));
    expect(provider.debts.single.isCancelled, isTrue);

    await provider.deleteDebt(0);
    expect(provider.debts, isEmpty);
    expect(provider.pendingTotal, 0);
  });

  test('los acentos y avisos mantienen contraste de texto accesible', () {
    for (final accent in [
      ...AppColors.lightAccents,
      ...AppColors.darkAccents,
      AppColors.success,
      AppColors.errorFor(Brightness.light),
      AppColors.errorFor(Brightness.dark),
    ]) {
      expect(
        AppColors.contrastRatio(accent, AppColors.onAccent(accent)),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
