import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/buys_model.dart';

class BuyProvider with ChangeNotifier {
  final _buyBox = Hive.box<Buy>('buysBox');

  List<Buy> _buys = [];

  List<Buy> get buys => _buys;

  BuyProvider() {
    _loadBuys();
  }

  void _loadBuys() {
    _buys = _buyBox.values.toList();
    notifyListeners();
  }

  Future<void> addBuy(Buy buy) async {
    await _buyBox.add(buy);
    _buys = _buyBox.values.toList();
    notifyListeners();
  }

  Future<void> deleteBuy(int index) async {
    await _buyBox.deleteAt(index);
    _buys = _buyBox.values.toList();
    notifyListeners();
  }

  Future<void> updateBuy(int index, Buy updatedBuy) async {
    await _buyBox.putAt(index, updatedBuy);
    _buys = _buyBox.values.toList();
    notifyListeners();
  }
}
