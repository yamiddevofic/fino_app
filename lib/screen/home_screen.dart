import 'package:fino_app/app_colors.dart';
import 'package:fino_app/provider/debts_provider.dart';
import 'package:fino_app/provider/expenses_provider.dart';
import 'package:fino_app/provider/incomes_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final incomes = context
        .watch<IncomeProvider>()
        .incomes
        .fold<double>(0, (total, item) => total + item.amount);
    final expenses = context
        .watch<ExpenseProvider>()
        .expenses
        .fold<double>(0, (total, item) => total + item.amount);
    final debtProvider = context.watch<DebtProvider>();
    final debtsTotal = debtProvider.totalDebts;
    final debtsPending = debtProvider.pendingTotal;
    final hasPendingDebts = debtProvider.pendingCount > 0;
    final balance = incomes - expenses - debtsTotal;
    final theme = Theme.of(context);
    final colors = AppColors.accents(theme.brightness);
    final color = colors[AppSection.overview.index];
    final muted = theme.colorScheme.onSurfaceVariant;
    final foreground = AppColors.onAccent(color);
    final numberFormat = NumberFormat('#,##0.00', 'es_CO');
    final message = _financialMessage(balance, hasPendingDebts);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TU DINERO, EN ORDEN',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: muted,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Resumen financiero',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BalanceCard(
                    color: color,
                    foreground: foreground,
                    balance: balance,
                    formattedBalance: numberFormat.format(balance),
                    message: message,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Resumen por categoría',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _MetricCard(
                    category: 'Ingresos',
                    amount: incomes,
                    color: colors[1],
                    icon: Icons.south_west_rounded,
                  ),
                  _MetricCard(
                    category: 'Gastos',
                    amount: expenses,
                    color: colors[2],
                    icon: Icons.north_east_rounded,
                  ),
                  _MetricCard(
                    category: 'Deudas',
                    amount: debtsTotal,
                    color: colors[3],
                    icon: Icons.account_balance_outlined,
                    subtitle: debtsPending > 0
                        ? 'Pendientes: ${numberFormat.format(debtsPending)}'
                        : 'Todas al día',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Totales acumulados de tus registros',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _financialMessage(double balance, bool hasPendingDebts) {
    if (hasPendingDebts) return 'Tienes deudas pendientes';
    if (balance > 0) return 'Buen momento, estás en positivo';
    if (balance < 0) return 'Revisa tus gastos, estás en negativo';
    return 'Estás en equilibrio, mantén el control';
  }
}

class _BalanceCard extends StatelessWidget {
  final Color color;
  final Color foreground;
  final double balance;
  final String formattedBalance;
  final String message;

  const _BalanceCard({
    required this.color,
    required this.foreground,
    required this.balance,
    required this.formattedBalance,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Balance disponible',
                  style: TextStyle(
                    color: foreground.withValues(alpha: .85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined,
                  color: foreground, size: 24),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'COP $formattedBalance',
                style: TextStyle(
                  color: foreground,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: TextStyle(
              color: foreground.withValues(alpha: .9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                positive ? Icons.trending_up_rounded : Icons.info_outline,
                color: foreground.withValues(alpha: .85),
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                positive ? 'Balance positivo' : 'Balance por revisar',
                style: TextStyle(
                  color: foreground.withValues(alpha: .85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String category;
  final double amount;
  final Color color;
  final IconData icon;
  final String? subtitle;

  const _MetricCard({
    required this.category,
    required this.amount,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountText = NumberFormat('#,##0.00', 'es_CO').format(amount);
    final foreground = AppColors.onAccent(color);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, color: foreground, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foreground.withValues(alpha: .8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                'COP $amountText',
                textAlign: TextAlign.right,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
