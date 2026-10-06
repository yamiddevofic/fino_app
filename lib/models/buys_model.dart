import 'package:fino_app/models/finance_record.dart';

part 'buys_model.g.dart';

/// Un compra registrado por el usuario.
class Buy extends FinanceRecord {
  Buy({
    required super.name,
    required super.amount,
    super.date,
    super.category,
    super.note,
  });
}
