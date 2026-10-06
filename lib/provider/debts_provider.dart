import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';

class DebtProvider extends RecordProvider<Debt> {
  DebtProvider() : super(RecordKind.debt.boxName, Debt.new);
}
