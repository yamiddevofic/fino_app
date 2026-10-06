import 'package:fino_app/models/finance_record.dart';

part 'debts_model.g.dart';

/// Un deuda registrado por el usuario.
class Debt extends FinanceRecord {
  Debt({
    required super.name,
    required super.amount,
    super.date,
    super.category,
    super.note,
  });
}
