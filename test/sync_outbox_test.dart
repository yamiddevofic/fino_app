import 'dart:io';

import 'package:fino_app/main.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/app_lock.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/provider/settlement.dart';
import 'package:fino_app/provider/sync_outbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('fino_sync_test_');
    Hive.init(tempDir.path);
    registerAdapters();
  });

  setUp(openBoxes);

  tearDown(() => Hive.deleteFromDisk());

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('cada cambio de un registro queda pendiente de subir', () async {
    final outbox = SyncOutbox();
    final incomes = IncomeProvider();

    await incomes.add(Income(name: 'Salario', amount: 1000));
    final added = incomes.records.single;
    expect(added.id, isNotNull);
    expect(outbox.records, {added.id: PendingChange.upsert});

    // Editar desde el formulario construye un registro nuevo sin id; debe
    // seguir siendo el mismo.
    await incomes.update(added, Income(name: 'Salario', amount: 1200));
    expect(incomes.records.single.id, added.id);
    expect(outbox.records, hasLength(1));

    final copy = await incomes.delete(incomes.records.single);
    expect(outbox.records, {added.id: PendingChange.delete});

    // Deshacer el borrado vuelve a subirlo con el mismo id.
    await incomes.add(copy);
    expect(incomes.records.single.id, added.id);
    expect(outbox.records, {added.id: PendingChange.upsert});
  });

  test('aplicar cambios remotos no los marca como pendientes', () async {
    final outbox = SyncOutbox();
    final incomes = IncomeProvider();
    await incomes.add(Income(name: 'Local', amount: 1));
    final localId = incomes.records.single.id!;
    await outbox.clearRecords(outbox.records);

    const remoteId = '00000000-0000-4000-8000-000000000001';
    await incomes.applyRemote({
      remoteId: Income(name: 'Del navegador', amount: 5, id: remoteId),
      localId: Income(name: 'Local editado', amount: 2, id: localId),
    });
    expect(incomes.records.map((r) => r.name).toSet(), {
      'Del navegador',
      'Local editado',
    });
    expect(outbox.isEmpty, isTrue);

    await incomes.applyRemote({remoteId: null});
    expect(incomes.records.single.name, 'Local editado');
    expect(outbox.isEmpty, isTrue);
  });

  test('los registros antiguos reciben un id y quedan pendientes', () async {
    await Hive.box<Income>(
      RecordKind.income.boxName,
    ).add(Income(name: 'De la versión anterior', amount: 1));
    expect(IncomeProvider().records.single.id, isNull);

    await ensureRecordIds();

    final record = IncomeProvider().records.single;
    expect(record.id, isNotNull);
    expect(SyncOutbox().records, {record.id: PendingChange.upsert});
  });

  test('pagar una deuda deja pendientes la deuda y su gasto', () async {
    final outbox = SyncOutbox();
    final debts = DebtProvider();
    final expenses = ExpenseProvider();
    await debts.add(Debt(name: 'Préstamo', amount: 300));
    await outbox.clearRecords(outbox.records);

    await toggleSettled(
      records: debts,
      expenses: expenses,
      kind: RecordKind.debt,
      record: debts.records.single,
    );
    expect(outbox.records.keys.toSet(), {
      debts.records.single.id,
      expenses.records.single.id,
    });
    expect(expenses.records.single, isA<Expense>());
  });

  test('las categorías propias también quedan pendientes', () async {
    final outbox = SyncOutbox();
    final categories = CategoryProvider();
    await categories.add(RecordKind.expense, 'Mascotas');
    await categories.remove(RecordKind.expense, 'Mascotas');
    expect(outbox.categories, [
      (RecordKind.expense, 'Mascotas', PendingChange.delete),
    ]);

    await categories.applyRemote({
      RecordKind.buy: {'Regalos': false},
    });
    expect(categories.custom(RecordKind.buy), ['Regalos']);
    expect(outbox.categories, hasLength(1));
  });

  test('el PIN se guarda como hash y desbloquea la app', () async {
    final lock = AppLock();
    expect(lock.hasPin, isFalse);
    expect(AppLock.isValidPin('12a4'), isFalse);

    await lock.setPin('2468');
    expect(Hive.box<String>(securityBoxName).values, isNot(contains('2468')));

    lock.lock();
    expect(lock.isLocked, isTrue);
    expect(lock.unlock('1111'), isFalse);
    expect(lock.unlock('2468'), isTrue);
    expect(lock.isLocked, isFalse);

    // Olvidar el PIN exige volver a iniciar sesión, que lo borra.
    await lock.requestPinReset();
    expect(lock.hasPin, isTrue);
    await lock.signedIn();
    expect(lock.hasPin, isFalse);
  });
}
