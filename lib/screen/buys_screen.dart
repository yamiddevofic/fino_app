import 'package:fino_app/app_colors.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/provider/buy_provider.dart';
import 'package:fino_app/widgets/finance_entry_page.dart';
import 'package:fino_app/widgets/history_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BuysScreen extends StatelessWidget {
  const BuysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forSection(
      AppSection.purchase,
      Theme.of(context).brightness,
    );

    return FinanceEntryPage(
      title: 'Nueva compra',
      description: 'Anota lo que planeas comprar y su valor.',
      entryType: 'la compra',
      successMessage: 'Compra agregada exitosamente',
      accentColor: accent,
      icon: Icons.shopping_bag_outlined,
      allowPendingPrice: true,
      onSave: (name, amount, {bool isPricePending = false}) =>
          context.read<BuyProvider>().addBuy(
                Buy(
                  name: name,
                  amount: amount,
                  date: DateTime.now(),
                  isPricePending: isPricePending,
                ),
              ),
      onShowHistory: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BuysListScreen(),
        ),
      ),
    );
  }
}

class BuysListScreen extends StatelessWidget {
  const BuysListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buys = context.watch<BuyProvider>().buys;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de compras')),
      body: HistoryList(
        entries: [
          for (var index = 0; index < buys.length; index++)
            HistoryEntry(
              title: buys[index].name,
              amount: buys[index].amount,
              date: buys[index].date,
              index: index,
              isCompleted: buys[index].isCompleted,
              isPricePending: buys[index].isPricePendingValue,
            ),
        ],
        accentColor: AppColors.forSection(
          AppSection.purchase,
          Theme.of(context).brightness,
        ),
        emptyMessage: 'Aún no tienes compras registradas.',
        deleteTitle: 'Eliminar compra',
        deleteMessage: '¿Quieres eliminar esta compra del historial?',
        deletedMessage: 'Compra eliminada',
        onDelete: (index) => context.read<BuyProvider>().deleteBuy(index),
        onToggleCompleted: (index) =>
            context.read<BuyProvider>().toggleBuyCompleted(index),
        onUpdatePrice: (index, amount) =>
            context.read<BuyProvider>().updateBuyPrice(index, amount),
      ),
    );
  }
}
