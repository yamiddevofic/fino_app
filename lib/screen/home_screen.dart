import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:fino_app/widgets/charts.dart';
import 'package:fino_app/widgets/common.dart';
import 'package:fino_app/widgets/record_tile.dart';
import 'package:fino_app/widgets/wave_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenSection});

  /// Abre la pestaña de una sección al tocar su fila en el desglose.
  final ValueChanged<RecordKind>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final incomes = context.watch<RecordProvider<Income>>();
    final expenses = context.watch<RecordProvider<Expense>>();
    final debts = context.watch<RecordProvider<Debt>>();
    final buys = context.watch<RecordProvider<Buy>>();
    final tokens = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    // El balance solo cuenta dinero que ya se movió. Las deudas y compras
    // pendientes se restan aparte, en el balance proyectado; al marcarlas
    // como listas se registran como gastos.
    final balance = incomes.total - expenses.total;
    final pendingTotal = debts.pendingTotal + buys.pendingTotal;
    final projected = balance - pendingTotal;
    final committed = incomes.total > 0
        ? expenses.total / incomes.total
        : (expenses.total > 0 ? 1.0 : 0.0);

    final recent =
        <(RecordKind, FinanceRecord)>[
          for (final r in incomes.records) (RecordKind.income, r),
          for (final r in expenses.records) (RecordKind.expense, r),
        ]..sort((a, b) {
          final da = a.$2.date, db = b.$2.date;
          if (da == null) return db == null ? 0 : 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

    final breakdown = [
      (RecordKind.income, incomes.total, null),
      (RecordKind.expense, expenses.total, null),
      (RecordKind.debt, debts.pendingTotal, _debtNote(debts)),
      (RecordKind.buy, buys.pendingTotal, _buyNote(buys)),
    ];
    final maxBreakdown = breakdown.fold<double>(
      0,
      (m, e) => e.$2 > m ? e.$2 : m,
    );

    var section = 0;
    Widget block(Widget child) => FadeSlideIn(index: section++, child: child);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              block(
                WaveCard(
                  accent: tokens.brand,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance general',
                              style: textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AnimatedAmount(
                                value: balance,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: balance < 0
                                      ? tokens.negative
                                      : tokens.text,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingresos − gastos',
                              style: textTheme.bodySmall?.copyWith(
                                color: tokens.textMuted,
                              ),
                            ),
                            if (pendingTotal > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Proyectado: ${formatCop(projected)}',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: tabularFigures,
                                  color: projected < 0
                                      ? tokens.negative
                                      : tokens.text,
                                ),
                              ),
                              Text(
                                'Tras pagar lo pendiente',
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ProgressRing(
                        value: committed,
                        color: committed >= 1 ? tokens.negative : tokens.brand,
                        trackColor: tokens.surfaceMuted,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(committed * 100).clamp(0, 999).round()}%',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                            Text(
                              'usado',
                              style: textTheme.labelSmall?.copyWith(
                                color: tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              block(const SectionLabel('Desglose')),
              block(
                SectionCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final (kind, total, note) in breakdown)
                        _BreakdownRow(
                          kind: kind,
                          total: total,
                          share: maxBreakdown > 0 ? total / maxBreakdown : 0,
                          note: note,
                          onTap: onOpenSection == null
                              ? null
                              : () => onOpenSection!(kind),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              block(
                SectionLabel(
                  'Últimos 6 meses',
                  trailing: _Legend(
                    incomeColor: RecordKind.income.accent(context),
                    expenseColor: RecordKind.expense.accent(context),
                  ),
                ),
              ),
              block(
                SectionCard(
                  child: MonthlyBars(
                    months: _lastMonths(incomes.records, expenses.records),
                    incomeColor: RecordKind.income.accent(context),
                    expenseColor: RecordKind.expense.accent(context),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              block(const SectionLabel('Movimientos recientes')),
              block(
                recent.isEmpty
                    ? SectionCard(
                        child: EmptyState(
                          color: tokens.brand,
                          title: 'Sin movimientos todavía',
                          message:
                              'Registra tus ingresos y gastos desde las pestañas de abajo.',
                        ),
                      )
                    : SectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, (kind, record))
                                in recent.take(5).indexed) ...[
                              if (i > 0) const Divider(indent: 70, height: 1),
                              RecordTile(record: record, kind: kind),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// En deudas y compras el desglose muestra lo pendiente; lo ya pagado
  /// está en los gastos.
  static String? _debtNote(RecordProvider<Debt> debts) {
    if (debts.records.isEmpty) return null;
    final pending = debts.pending.length;
    if (pending == 0) return 'Todas pagadas';
    return pending == 1 ? '1 por pagar' : '$pending por pagar';
  }

  static String? _buyNote(RecordProvider<Buy> buys) {
    if (buys.records.isEmpty) return null;
    final pending = buys.pending.length;
    if (pending == 0) return 'Todas compradas';
    final noPrice = buys.pending.where((b) => b.pricePending).length;
    return [
      '$pending por comprar',
      if (noPrice > 0) '$noPrice sin precio',
    ].join(' · ');
  }

  static List<MonthTotals> _lastMonths(
    List<FinanceRecord> incomes,
    List<FinanceRecord> expenses,
  ) {
    final now = DateTime.now();
    double sum(List<FinanceRecord> records, DateTime month) => records
        .where(
          (r) =>
              r.date != null &&
              r.date!.year == month.year &&
              r.date!.month == month.month,
        )
        .fold(0.0, (s, r) => s + r.amount);

    return [
      for (var i = 5; i >= 0; i--)
        () {
          final month = DateTime(now.year, now.month - i);
          return MonthTotals(month, sum(incomes, month), sum(expenses, month));
        }(),
    ];
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.kind,
    required this.total,
    required this.share,
    this.note,
    this.onTap,
  });

  final RecordKind kind;
  final double total;
  final double share;
  final String? note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = kind.accent(context);
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AccentIcon(icon: kind.icon, color: accent, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          kind.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        formatCop(total),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: share),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        color: accent,
                        backgroundColor: tokens.surfaceMuted,
                      ),
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      note!,
                      style: textTheme.labelSmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.incomeColor, required this.expenseColor});

  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppTokens.of(context).textMuted);
    Widget dot(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(incomeColor),
        const SizedBox(width: 4),
        Text('Ingresos', style: style),
        const SizedBox(width: 10),
        dot(expenseColor),
        const SizedBox(width: 4),
        Text('Gastos', style: style),
      ],
    );
  }
}
