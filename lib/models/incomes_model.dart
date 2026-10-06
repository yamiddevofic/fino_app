import 'package:hive/hive.dart';

part 'incomes_model.g.dart';

@HiveType(typeId: 1)
class Income {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime? date;

  Income({required this.name, required this.amount, this.date});
}
