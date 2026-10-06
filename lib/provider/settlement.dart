import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:flutter/material.dart';

/// Marca una deuda como pagada o una compra como hecha, o lo deshace.
///
/// Las deudas y compras pendientes no afectan el balance. Al marcarlas como
/// listas se registra un gasto con su monto, porque es entonces cuando el
/// dinero sale; al desmarcarlas ese gasto se elimina. Es la misma lógica de
/// apps como Money Lover (pago de deuda) o Wallet (pagos planificados).
///
/// [price] es obligatorio para una compra con precio por definir.
Future<void> toggleSettled<T extends FinanceRecord>({
  required RecordProvider<T> records,
  required RecordProvider<Expense> expenses,
  required RecordKind kind,
  required T record,
  double? price,
}) async {
  assert(kind.canMarkDone);

  if (record.done) {
    final key = record.expenseKey;
    if (key != null) await expenses.deleteKey(key);
    await records.update(
      record,
      copyRecord(records.builder, record, done: false, expenseKey: null),
    );
    return;
  }

  final amount = price ?? record.amount;
  assert(!record.pricePending || price != null);
  final key = await expenses.add(
    Expense(
      name: record.name,
      amount: amount,
      date: DateUtils.dateOnly(DateTime.now()),
      category: kind.settledCategory,
      note: kind.settledNote,
    ),
  );
  await records.update(
    record,
    copyRecord(
      records.builder,
      record,
      amount: amount,
      done: true,
      pricePending: false,
      expenseKey: key,
    ),
  );
}
