import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/incomes_model.dart';

class IncomeProvider with ChangeNotifier {
  final _incomeBox = Hive.box<Income>('incomesBox');

  List<Income> _incomes = [];

  List<Income> get incomes => _incomes;

  IncomeProvider() {
    _loadIncomes();
  }

  void _loadIncomes() {
    _incomes = _incomeBox.values.toList();
    notifyListeners();
  }

  Future<void> addIncome(Income income) async {
    await _incomeBox.add(income);
    _incomes = _incomeBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteIncome(int index) async {
    await _incomeBox.deleteAt(index);
    _incomes = _incomeBox.values.toList();
    notifyListeners();
  }

  Future<void> updateIncome(int index, Income updatedIncome) async {
    await _incomeBox.putAt(index, updatedIncome);
    _incomes = _incomeBox.values.toList();
    notifyListeners();
  }
}
