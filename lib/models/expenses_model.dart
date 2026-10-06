import 'package:hive/hive.dart';

part 'expenses_model.g.dart';

@HiveType(typeId: 0)
class Expense {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime? date;

  Expense({required this.name, required this.amount, this.date});
}
