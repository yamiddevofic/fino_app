import 'package:fino_app/app_colors.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/widgets/finance_entry_page.dart';
import 'package:fino_app/widgets/history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forSection(
      AppSection.expense,
      Theme.of(context).brightness,
    );

    return FinanceEntryPage(
      title: 'Nuevo gasto',
      description: 'Lleva un registro claro de tus salidas.',
      entryType: 'el gasto',
      successMessage: 'Gasto agregado exitosamente',
      accentColor: accent,
      icon: Icons.north_east_rounded,
      onSave: (name, amount, {bool isPricePending = false}) =>
          context.read<ExpenseProvider>().addExpense(
                Expense(name: name, amount: amount, date: DateTime.now()),
              ),
      onShowHistory: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ExpensesListScreen(),
        ),
      ),
    );
  }
}

class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de gastos')),
      body: HistoryList(
        entries: [
          for (var index = 0; index < expenses.length; index++)
            HistoryEntry(
              title: expenses[index].name,
              amount: expenses[index].amount,
              date: expenses[index].date,
              index: index,
            ),
        ],
        accentColor: AppColors.forSection(
          AppSection.expense,
          Theme.of(context).brightness,
        ),
        emptyMessage: 'Aún no tienes gastos registrados.',
        deleteTitle: 'Eliminar gasto',
        deleteMessage: '¿Quieres eliminar este gasto del historial?',
        deletedMessage: 'Gasto eliminado',
        onDelete: (index) =>
            context.read<ExpenseProvider>().deleteExpense(index),
      ),
    );
  }
}
