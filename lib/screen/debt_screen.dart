import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/screen/records_screen.dart';
import 'package:flutter/material.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const RecordsScreen<Debt>(kind: RecordKind.debt);
}
