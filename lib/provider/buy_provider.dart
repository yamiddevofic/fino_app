import 'package:fino_app/models/buys_model.dart';
import 'package:flutter/material.dart';

class BuyProvider with ChangeNotifier {
  final List<Buy> _buys = [];

  List<Buy> get buys => _buys;

  void addBuy(Buy buy) {
    _buys.add(buy);
    notifyListeners();
  }
}