import 'package:hive/hive.dart';


@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  Expense({required this.name, required this.amount});
}
