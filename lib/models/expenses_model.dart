import 'package:fino_app/models/finance_record.dart';

part 'expenses_model.g.dart';

/// Un gasto registrado por el usuario.
class Expense extends FinanceRecord {
  Expense({
    required super.name,
    required super.amount,
    super.date,
    super.category,
    super.note,
    super.done,
    super.pricePending,
  });
}
