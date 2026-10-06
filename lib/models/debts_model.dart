import 'package:hive/hive.dart';

part 'debts_model.g.dart';

@HiveType(typeId: 3)
class Debt {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime? date;

  @HiveField(3)
  final bool? isCancelled;

  Debt({
    required this.name,
    required this.amount,
    this.date,
    this.isCancelled = false,
  });
}
