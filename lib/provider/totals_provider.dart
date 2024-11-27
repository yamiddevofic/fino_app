// provider para el manejo de los totales de expenses, incomes y buysº

import 'package:flutter/material.dart';

class TotalsProvider with ChangeNotifier {
  final List<double> _totals = [];

  List<double> get totals => _totals;

  void addTotal(double total) {
    _totals.add(total);
    notifyListeners();
  }
}