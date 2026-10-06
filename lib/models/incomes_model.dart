import 'package:fino_app/models/finance_record.dart';

part 'incomes_model.g.dart';

/// Un ingreso registrado por el usuario.
class Income extends FinanceRecord {
  Income({
    required super.name,
    required super.amount,
    super.date,
    super.category,
    super.note,
    super.done,
    super.pricePending,
    super.expenseKey,
  });
}
