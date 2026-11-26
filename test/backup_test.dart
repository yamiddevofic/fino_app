import 'dart:convert';
import 'dart:io';

import 'package:fino_app/main.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/backup.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/provider/settlement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fino_backup_test_');
    Hive.init(tempDir.path);
    registerAdapters();
  });

  setUp(openBoxes);

  tearDown(() => Hive.deleteFromDisk());

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  BackupSources sources() => BackupSources(
    incomes: IncomeProvider(),
    expenses: ExpenseProvider(),
    debts: DebtProvider(),
    buys: BuyProvider(),
    categories: CategoryProvider(),
  );

  test('exporta e importa registros y categorías propias', () async {
    final original = sources();
    await original.incomes.add(
      Income(
        name: 'Nómina',
        amount: 1500000,
        date: DateTime(2026, 9, 30),
        category: 'Salario',
        note: 'Septiembre',
      ),
    );
    await original.expenses.add(Expense(name: 'Sin fecha', amount: 20000));
    await original.buys.add(Buy(name: 'Silla', amount: 0, pricePending: true));
    await original.categories.add(RecordKind.expense, 'Mascotas');
    await original.categories.add(RecordKind.buy, 'Regalos');

    final json = original.export(now: DateTime(2026, 11, 26, 10, 30));
    final backup = parseBackup(json);
    expect(backup.recordCount, 3);
    expect(backup.categoryCount, 2);
    expect(backup.exportedAt, DateTime(2026, 11, 26, 10, 30));

    // Datos distintos que el respaldo debe reemplazar por completo.
    await Hive.deleteFromDisk();
    await openBoxes();
    final target = sources();
    await target.debts.add(Debt(name: 'Se reemplaza', amount: 1));
    await target.categories.add(RecordKind.income, 'Se reemplaza');

    await target.restore(backup);

    final income = target.incomes.records.single;
    expect(income.name, 'Nómina');
    expect(income.amount, 1500000);
    expect(income.date, DateTime(2026, 9, 30));
    expect(income.category, 'Salario');
    expect(income.note, 'Septiembre');
    expect(target.expenses.records.single.date, isNull);
    expect(target.buys.records.single.pricePending, isTrue);
    expect(target.debts.records, isEmpty);
    expect(target.categories.custom(RecordKind.expense), ['Mascotas']);
    expect(target.categories.custom(RecordKind.buy), ['Regalos']);
    expect(target.categories.custom(RecordKind.income), isEmpty);

    // Persistido en Hive, no solo en memoria.
    expect(Hive.box<Income>(RecordKind.income.boxName).length, 1);
    expect(Hive.box<List<dynamic>>(categoriesBoxName).get('expense'), [
      'Mascotas',
    ]);
  });

  test('una deuda pagada sigue enlazada con su gasto tras importar', () async {
    final original = sources();
    await original.expenses.add(Expense(name: 'Mercado', amount: 80000));
    await original.debts.add(Debt(name: 'Préstamo', amount: 300000));
    await toggleSettled(
      records: original.debts,
      expenses: original.expenses,
      kind: RecordKind.debt,
      record: original.debts.records.single,
    );
    final backup = parseBackup(original.export());

    await Hive.deleteFromDisk();
    await openBoxes();
    final target = sources();
    await target.restore(backup);

    final debt = target.debts.records.single;
    expect(debt.done, isTrue);
    expect(target.expenses.records, hasLength(2));

    // Al desmarcarla se quita su gasto, no el otro.
    await toggleSettled(
      records: target.debts,
      expenses: target.expenses,
      kind: RecordKind.debt,
      record: debt,
    );
    expect(target.expenses.records.single.name, 'Mercado');

    // Las claves siguen libres para registros nuevos.
    await target.expenses.add(Expense(name: 'Nuevo', amount: 1));
    expect(target.expenses.records, hasLength(2));
  });

  test('rechaza archivos que no son un respaldo de Fino', () {
    Matcher fails(String message) => throwsA(
      isA<BackupException>().having((e) => e.message, 'message', message),
    );

    expect(
      () => parseBackup('no es json'),
      fails('El archivo no es un respaldo válido.'),
    );
    expect(
      () => parseBackup('{"app": "otra", "version": 1}'),
      fails('El archivo no es un respaldo de Fino.'),
    );
    expect(
      () => parseBackup('{"app": "fino", "version": 99, "records": {}}'),
      fails(
        'El respaldo es de una versión más reciente de Fino. '
        'Actualiza la app.',
      ),
    );
    expect(
      () => parseBackup(
        jsonEncode({
          'app': 'fino',
          'version': 1,
          'records': {
            'expense': [
              {'name': 'Bien', 'amount': 1},
              {'name': 'Sin monto'},
            ],
          },
        }),
      ),
      fails('El registro 2 de Gastos no es válido: falta el monto.'),
    );
  });

  test('un respaldo inválido no modifica los datos actuales', () async {
    final current = sources();
    await current.incomes.add(Income(name: 'Conservar', amount: 10));

    expect(
      () => parseBackup('{"app": "fino", "version": 1, "records": []}'),
      throwsA(isA<BackupException>()),
    );
    expect(current.incomes.records.single.name, 'Conservar');
  });

  test('limpia datos dudosos de un respaldo editado a mano', () {
    final backup = parseBackup(
      jsonEncode({
        'app': 'fino',
        'version': 1,
        'categories': {
          'expense': ['Mascotas', ' mascotas ', 'Comida', '', 7],
          'otra': ['Ignorada'],
        },
        'records': {
          'income': [
            {'name': 'Sin clave', 'amount': 5, 'done': true},
          ],
          'debt': [
            {'key': 4, 'name': 'Huérfana', 'amount': 3, 'expenseKey': 9},
          ],
        },
      }),
    );

    // Sin duplicados ni categorías que ya existen por defecto.
    expect(backup.categories, {
      RecordKind.expense: ['Mascotas'],
    });
    // Un ingreso nunca queda marcado como hecho.
    expect(backup.incomes[0]!.done, isFalse);
    // El enlace a un gasto inexistente se descarta.
    expect(backup.debts[4]!.expenseKey, isNull);
  });
}
