import 'package:hive/hive.dart';

part 'buys_model.g.dart';

@HiveType(typeId: 2)
class Buy {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime? date;

  @HiveField(3)
  final bool? isCompleted;

  @HiveField(4)
  final bool? isPricePending;

  Buy({
    required this.name,
    required this.amount,
    this.date,
    this.isCompleted = false,
    this.isPricePending = false,
  });

  bool get isPricePendingValue => isPricePending ?? false;

  Buy copyWith({
    String? name,
    double? amount,
    DateTime? date,
    bool? isCompleted,
    bool? isPricePending,
  }) {
    return Buy(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isPricePending: isPricePending ?? this.isPricePending,
    );
  }
}
