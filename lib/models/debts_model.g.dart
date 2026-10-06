// Adaptador de Hive escrito a mano; la lógica está en FinanceRecordAdapter.

part of 'debts_model.dart';

class DebtAdapter extends FinanceRecordAdapter<Debt> {
  DebtAdapter() : super(3, Debt.new);
}
