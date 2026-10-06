import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';

class BuyProvider extends RecordProvider<Buy> {
  BuyProvider() : super(RecordKind.buy.boxName, Buy.new);
}
