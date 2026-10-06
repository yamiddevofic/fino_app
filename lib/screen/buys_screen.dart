import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/screen/records_screen.dart';
import 'package:flutter/material.dart';

class BuysScreen extends StatelessWidget {
  const BuysScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const RecordsScreen<Buy>(kind: RecordKind.buy);
}
