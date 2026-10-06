// Adaptador de Hive escrito a mano; la lógica está en FinanceRecordAdapter.

part of 'incomes_model.dart';

class IncomeAdapter extends FinanceRecordAdapter<Income> {
  IncomeAdapter() : super(1, Income.new);
}
