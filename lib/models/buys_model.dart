import 'package:fino_app/models/finance_record.dart';

part 'buys_model.g.dart';

/// Una compra registrada por el usuario.
class Buy extends FinanceRecord {
  Buy({
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
