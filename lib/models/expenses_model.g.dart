// Adaptador de Hive escrito a mano; la lógica está en FinanceRecordAdapter.

part of 'expenses_model.dart';

class ExpenseAdapter extends FinanceRecordAdapter<Expense> {
  ExpenseAdapter() : super(0, Expense.new);
}
