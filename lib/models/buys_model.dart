import 'package:hive/hive.dart';

part 'buys_model.g.dart';


@HiveType(typeId: 2)
class Buy {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  Buy({required this.name, required this.amount});
}
