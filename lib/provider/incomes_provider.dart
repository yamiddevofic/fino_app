import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';

class IncomeProvider extends RecordProvider<Income> {
  IncomeProvider() : super(RecordKind.income.boxName, Income.new);
}
