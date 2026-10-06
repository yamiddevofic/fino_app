import 'package:fino_app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryEntry {
  final String title;
  final double amount;
  final DateTime? date;
  final int index;
  final bool? isCompleted;
  final bool isPricePending;
  final String completedLabel;
  final String pendingLabel;

  const HistoryEntry({
    required this.title,
    required this.amount,
    required this.date,
    required this.index,
    this.isCompleted = false,
    this.isPricePending = false,
    this.completedLabel = 'Hecha',
    this.pendingLabel = 'Pendiente',
  });
}

class HistoryList extends StatelessWidget {
  final List<HistoryEntry> entries;
  final Color accentColor;
  final String emptyMessage;
  final String deleteTitle;
  final String deleteMessage;
  final String deletedMessage;
  final ValueChanged<int> onDelete;
  final ValueChanged<int>? onToggleCompleted;
  final void Function(int index, double amount)? onUpdatePrice;

  const HistoryList({
    super.key,
    required this.entries,
    required this.accentColor,
    required this.emptyMessage,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deletedMessage,
    required this.onDelete,
    this.onToggleCompleted,
    this.onUpdatePrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final cardBackground = theme.cardColor;
    final dividerColor = theme.colorScheme.outline.withValues(alpha: .2);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                emptyMessage,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tus registros aparecerán aquí.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final noDate = DateTime(1);
    final grouped = <DateTime, List<HistoryEntry>>{};
    for (final entry in entries) {
      final date = entry.date;
      final day =
          date == null ? noDate : DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final dateFormat = DateFormat("EEEE d 'de' MMMM", 'es_CO');
    final amountFormat = NumberFormat('#,##0.00', 'es_CO');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          itemCount: days.length,
          itemBuilder: (context, dayIndex) {
            final day = days[dayIndex];
            final dayEntries = grouped[day]!
              ..sort((a, b) => (b.date ?? noDate).compareTo(a.date ?? noDate));
            final dateLabel = day == noDate
                ? 'Sin fecha registrada'
                : _capitalize(dateFormat.format(day));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xs,
                      AppSpacing.sm, AppSpacing.xs, AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: mutedColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ...dayEntries.map((entry) {
                  final done = entry.isCompleted == true;
                  final canToggle = onToggleCompleted != null;
                  final time = entry.date == null
                      ? ''
                      : DateFormat('HH:mm').format(entry.date!);

                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    elevation: isDark ? 0 : 2,
                    shadowColor: Colors.black.withValues(alpha: .1),
                    clipBehavior: Clip.antiAlias,
                    color: done
                        ? accentColor.withValues(alpha: .08)
                        : cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(
                        color: accentColor.withValues(alpha: done ? .3 : .12),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: canToggle
                          ? () => onToggleCompleted!(entry.index)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (canToggle)
                                  _CompletionToggle(
                                    done: done,
                                    accentColor: accentColor,
                                    completedLabel: entry.completedLabel,
                                    pendingLabel: entry.pendingLabel,
                                    onChanged: () =>
                                        onToggleCompleted!(entry.index),
                                  )
                                else
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.control),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: accentColor,
                                      size: 20,
                                    ),
                                  ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          decoration: done
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: done ? mutedColor : textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (entry.isPricePending) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              time,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                color: mutedColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            _PendingPriceRow(
                                              onEdit: () => _showPriceInput(
                                                  context, entry.index),
                                            ),
                                          ],
                                        ),
                                      ] else if (time.isNotEmpty ||
                                          canToggle) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (time.isNotEmpty)
                                              Text(
                                                time,
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  color: mutedColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (canToggle)
                                              _StatusPill(
                                                done: done,
                                                accentColor: accentColor,
                                                completedLabel:
                                                    entry.completedLabel,
                                                pendingLabel:
                                                    entry.pendingLabel,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: dividerColor,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      entry.isPricePending
                                          ? 'Precio indefinido'
                                          : 'COP ${amountFormat.format(entry.amount)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: entry.isPricePending
                                            ? theme.colorScheme.onSurfaceVariant
                                            : accentColor,
                                        fontSize:
                                            entry.isPricePending ? 14 : 16,
                                        fontWeight: entry.isPricePending
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Semantics(
                                  button: true,
                                  label: 'Eliminar registro',
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      tooltip: 'Eliminar del historial',
                                      icon: const Icon(
                                          Icons.delete_outline_rounded),
                                      iconSize: 20,
                                      onPressed: () =>
                                          _confirmDelete(context, entry.index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPriceInput(BuildContext context, int index) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ingresar precio'),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Precio',
            hintText: '0,00',
            prefixText: 'COP  ',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final amount = _parseAmount(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(dialogContext);
                onUpdatePrice?.call(index, amount);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  double? _parseAmount(String value) {
    var normalized = value.trim().replaceAll(' ', '');
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      if (lastComma > lastDot) {
        normalized = normalized.replaceAll('.', '').replaceFirst(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (lastComma >= 0) {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized);
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  void _confirmDelete(BuildContext context, int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(deletedMessage)),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _PendingPriceRow extends StatelessWidget {
  final VoidCallback onEdit;

  const _PendingPriceRow({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('Ingresar precio'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}

class _CompletionToggle extends StatelessWidget {
  final bool done;
  final Color accentColor;
  final String completedLabel;
  final String pendingLabel;
  final VoidCallback onChanged;

  const _CompletionToggle({
    required this.done,
    required this.accentColor,
    required this.completedLabel,
    required this.pendingLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: done
          ? 'Marcar como $pendingLabel'
          : 'Marcar como ${completedLabel.toLowerCase()}',
      child: SizedBox(
        width: 44,
        height: 44,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onChanged,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? accentColor : Colors.transparent,
                border: Border.all(
                  color: accentColor.withValues(alpha: done ? 1 : .6),
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.onAccent(accentColor),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool done;
  final Color accentColor;
  final String completedLabel;
  final String pendingLabel;

  const _StatusPill({
    required this.done,
    required this.accentColor,
    required this.completedLabel,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = done ? accentColor : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_rounded : Icons.schedule_rounded,
            size: 13,
            color: statusColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            done ? completedLabel : pendingLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
