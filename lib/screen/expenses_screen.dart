import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/screen/records_screen.dart';
import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const RecordsScreen<Expense>(kind: RecordKind.expense);
}
