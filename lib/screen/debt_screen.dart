import 'package:fino_app/app_colors.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/widgets/finance_entry_page.dart';
import 'package:fino_app/widgets/history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forSection(
      AppSection.debt,
      Theme.of(context).brightness,
    );

    return FinanceEntryPage(
      title: 'Nueva deuda',
      description: 'Organiza tus compromisos pendientes.',
      entryType: 'la deuda',
      successMessage: 'Deuda agregada exitosamente',
      accentColor: accent,
      icon: Icons.account_balance_outlined,
      onSave: (name, amount, {bool isPricePending = false}) async {
        await context.read<DebtProvider>().addDebt(
              Debt(name: name, amount: amount, date: DateTime.now()),
            );
      },
      onShowHistory: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DebtsListScreen(),
        ),
      ),
    );
  }
}

class DebtsListScreen extends StatelessWidget {
  const DebtsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final debts = context.watch<DebtProvider>().debts;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de deudas')),
      body: HistoryList(
        entries: [
          for (var index = 0; index < debts.length; index++)
            HistoryEntry(
              title: debts[index].name,
              amount: debts[index].amount,
              date: debts[index].date,
              index: index,
              isCompleted: debts[index].isCancelled,
              completedLabel: 'Cancelada',
              pendingLabel: 'Pendiente',
            ),
        ],
        accentColor: AppColors.forSection(
          AppSection.debt,
          Theme.of(context).brightness,
        ),
        emptyMessage: 'Aún no tienes deudas registradas.',
        deleteTitle: 'Eliminar deuda',
        deleteMessage: '¿Quieres eliminar esta deuda del historial?',
        deletedMessage: 'Deuda eliminada',
        onDelete: (index) => context.read<DebtProvider>().deleteDebt(index),
        onToggleCompleted: (index) =>
            context.read<DebtProvider>().toggleDebtCancelled(index),
      ),
    );
  }
}
