import 'package:fino_app/models/incomes_model.dart';
import 'package:flutter/foundation.dart';

class IncomeProvider with ChangeNotifier {
  final List<Income> _incomes = [];

  List<Income> get incomes => _incomes;

  void addIncome(Income income) {
    _incomes.add(income);
    notifyListeners();
  }
}
