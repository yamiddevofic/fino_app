import 'package:fino_app/app_colors.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:fino_app/widgets/finance_entry_page.dart';
import 'package:fino_app/widgets/history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class IncomesScreen extends StatelessWidget {
  const IncomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forSection(
      AppSection.income,
      Theme.of(context).brightness,
    );

    return FinanceEntryPage(
      title: 'Nuevo ingreso',
      description: 'Registra el dinero que recibes.',
      entryType: 'el ingreso',
      successMessage: 'Ingreso agregado exitosamente',
      accentColor: accent,
      icon: Icons.south_west_rounded,
      onSave: (name, amount, {bool isPricePending = false}) =>
          context.read<IncomeProvider>().addIncome(
                Income(name: name, amount: amount, date: DateTime.now()),
              ),
      onShowHistory: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const IncomesListScreen(),
        ),
      ),
    );
  }
}

class IncomesListScreen extends StatelessWidget {
  const IncomesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incomes = context.watch<IncomeProvider>().incomes;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de ingresos')),
      body: HistoryList(
        entries: [
          for (var index = 0; index < incomes.length; index++)
            HistoryEntry(
              title: incomes[index].name,
              amount: incomes[index].amount,
              date: incomes[index].date,
              index: index,
            ),
        ],
        accentColor: AppColors.forSection(
          AppSection.income,
          Theme.of(context).brightness,
        ),
        emptyMessage: 'Aún no tienes ingresos registrados.',
        deleteTitle: 'Eliminar ingreso',
        deleteMessage: '¿Quieres eliminar este ingreso del historial?',
        deletedMessage: 'Ingreso eliminado',
        onDelete: (index) => context.read<IncomeProvider>().deleteIncome(index),
      ),
    );
  }
}
