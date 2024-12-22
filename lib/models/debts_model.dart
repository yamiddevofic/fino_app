import 'package:hive/hive.dart';

part 'debts_model.g.dart';

@HiveType(typeId: 3)
class Debt {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  Debt({required this.name, required this.amount});
}