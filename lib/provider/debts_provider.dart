import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/debts_model.dart';

class DebtProvider with ChangeNotifier {
  final _debtBox = Hive.box<Debt>('debtBox');

  List<Debt> _debts = [];

  List<Debt> get debts => _debts;

  DebtProvider() {
    _loadDebts();
  }

  void _loadDebts() {
    _debts = _debtBox.values.toList();
    notifyListeners();
  }

  Future addDebt(Debt debt) async {
    await _debtBox.add(debt);
    _debts = _debtBox.values.toList();
    notifyListeners();
  }

  Future deleteDebt(int index) async {
    await _debtBox.deleteAt(index);
    _debts = _debtBox.values.toList();
    notifyListeners();
  }

  Future updateDebt(int index, Debt updatedDebt) async {
    await _debtBox.putAt(index, updatedDebt);
    _debts = _debtBox.values.toList();
    notifyListeners();
  }
}
