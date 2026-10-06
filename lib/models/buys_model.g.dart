// Adaptador de Hive escrito a mano; la lógica está en FinanceRecordAdapter.

part of 'buys_model.dart';

class BuyAdapter extends FinanceRecordAdapter<Buy> {
  BuyAdapter() : super(2, Buy.new);
}
