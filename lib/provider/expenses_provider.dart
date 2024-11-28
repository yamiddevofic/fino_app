import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expenses_model.dart';

class ExpenseProvider with ChangeNotifier {
  final _expenseBox = Hive.box<Expense>('expensesBox');

  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  ExpenseProvider() {
    _loadExpenses();
  }

  void _loadExpenses() {
    _expenses = _expenseBox.values.toList();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.add(expense);
    _expenses = _expenseBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteExpense(int index) async {
    await _expenseBox.deleteAt(index);
    _expenses = _expenseBox.values.toList();
    notifyListeners();
  }

  Future<void> updateExpense(int index, Expense updatedExpense) async {
    await _expenseBox.putAt(index, updatedExpense);
    _expenses = _expenseBox.values.toList();
    notifyListeners();
  }
}
