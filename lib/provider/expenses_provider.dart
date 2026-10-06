import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';

class ExpenseProvider extends RecordProvider<Expense> {
  ExpenseProvider() : super(RecordKind.expense.boxName, Expense.new);
}
