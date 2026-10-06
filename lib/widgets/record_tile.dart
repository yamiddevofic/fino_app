import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:fino_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Fila de un registro: icono, descripción, categoría y fecha, y monto.
///
/// En las secciones que lo admiten, el icono funciona como casilla para
/// marcar el registro como hecho (deuda cancelada, compra realizada).
class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
    required this.kind,
    this.onTap,
    this.onToggleDone,
  });

  final FinanceRecord record;
  final RecordKind kind;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = kind.accent(context);
    final textTheme = Theme.of(context).textTheme;
    final date = record.date;
    final done = kind.canMarkDone && record.done;
    final details = [
      if (done) kind.doneLabel!,
      ?record.category,
      date == null ? 'Sin fecha' : DateFormat.MMMd('es').format(date),
    ].join(' · ');
    final sign = switch (kind) {
      RecordKind.income => '+',
      RecordKind.expense => '−',
      // Deudas y compras no son movimientos hasta que se pagan.
      RecordKind.debt || RecordKind.buy => '',
    };

    final icon = AccentIcon(icon: kind.iconFor(record.category), color: accent);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (kind.canMarkDone)
              _DoneToggle(
                done: done,
                color: accent,
                label: done
                    ? 'Marcar como ${kind.pendingLabel!.toLowerCase()}'
                    : 'Marcar como ${kind.doneLabel!.toLowerCase()}',
                onPressed: onToggleDone,
                child: icon,
              )
            else
              icon,
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
                      color: done ? tokens.textMuted : tokens.text,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: tokens.textMuted,
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
            if (record.pricePending)
              Text(
                'Precio por definir',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                '$sign${formatCop(record.amount)}',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done
                      ? tokens.textMuted
                      : kind == RecordKind.income
                      ? accent
                      : tokens.text,
                  fontFeatures: tabularFigures,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Icono de la categoría que, al tocarlo, alterna el estado "hecho". Cuando
/// está hecho muestra una marca de verificación con el color de acento.
class _DoneToggle extends StatelessWidget {
  const _DoneToggle({
    required this.done,
    required this.color,
    required this.label,
    required this.onPressed,
    required this.child,
  });

  final bool done;
  final Color color;
  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onPressed,
          radius: 26,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: done
                ? Container(
                    key: const ValueKey(true),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(40 * 0.32),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: onColor(color),
                      size: 22,
                    ),
                  )
                : KeyedSubtree(key: const ValueKey(false), child: child),
          ),
        ),
      ),
    );
  }
}
