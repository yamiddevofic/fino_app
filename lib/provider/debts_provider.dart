import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/debts_model.dart';

class DebtProvider with ChangeNotifier {
  final _debtBox = Hive.box<Debt>('debtBox');

  List<Debt> _debts = [];

  List<Debt> get debts => _debts;

  // Total de TODAS las deudas (canceladas + pendientes) para el balance
  double get totalDebts =>
      _debts.fold<double>(0, (total, debt) => total + debt.amount);

  // Solo deudas pendientes (para mostrar mensaje)
  double get pendingTotal => _debts
      .where((debt) => debt.isCancelled != true)
      .fold<double>(0, (total, debt) => total + debt.amount);

  // Cantidad de deudas pendientes
  int get pendingCount =>
      _debts.where((debt) => debt.isCancelled != true).length;

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

  Future<void> toggleDebtCancelled(int index) async {
    final debt = _debts[index];
    await updateDebt(
      index,
      Debt(
        name: debt.name,
        amount: debt.amount,
        date: debt.date,
        isCancelled: !(debt.isCancelled ?? false),
      ),
    );
  }
}
