import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:fino_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fila de un registro: icono, descripción, categoría y fecha, y monto.
class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
    required this.kind,
    this.onTap,
  });

  final FinanceRecord record;
  final RecordKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = kind.accent(context);
    final textTheme = Theme.of(context).textTheme;
    final date = record.date;
    final details = [
      ?record.category,
      date == null ? 'Sin fecha' : DateFormat.MMMd('es').format(date),
    ].join(' · ');
    final sign = switch (kind) {
      RecordKind.income => '+',
      RecordKind.expense || RecordKind.debt => '−',
      RecordKind.buy => '',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AccentIcon(icon: kind.iconFor(record.category), color: accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$sign${formatCop(record.amount)}',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: kind == RecordKind.income ? accent : tokens.text,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
