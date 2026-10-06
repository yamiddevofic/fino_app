import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/widgets/charts.dart';
import 'package:fino_app/widgets/common.dart';
import 'package:fino_app/widgets/record_form_sheet.dart';
import 'package:fino_app/widgets/record_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Pantalla de una sección (ingresos, gastos, deudas o compras): total,
/// filtro por mes y lista de registros.
class RecordsScreen<T extends FinanceRecord> extends StatefulWidget {
  const RecordsScreen({super.key, required this.kind});

  final RecordKind kind;

  @override
  State<RecordsScreen<T>> createState() => _RecordsScreenState<T>();
}

/// Filtro activo: `null` es "Todo", [_noDate] son los registros sin fecha y
/// cualquier otra fecha es el primer día de un mes.
final _noDate = DateTime(0);

class _RecordsScreenState<T extends FinanceRecord>
    extends State<RecordsScreen<T>> {
  DateTime? _month;

  RecordKind get kind => widget.kind;

  bool _matches(FinanceRecord r) {
    final month = _month;
    if (month == null) return true;
    final date = r.date;
    if (month == _noDate) return date == null;
    return date != null && date.year == month.year && date.month == month.month;
  }

  Future<void> _add() async {
    final provider = context.read<RecordProvider<T>>();
    final record = await showRecordForm<T>(
      context,
      kind: kind,
      builder: provider.builder,
    );
    if (record != null) await provider.add(record);
  }

  Future<void> _edit(T original) async {
    final provider = context.read<RecordProvider<T>>();
    final updated = await showRecordForm<T>(
      context,
      kind: kind,
      builder: provider.builder,
      initial: original,
    );
    if (updated != null) await provider.update(original, updated);
  }

  Future<void> _delete(T record) async {
    final provider = context.read<RecordProvider<T>>();
    final messenger = ScaffoldMessenger.of(context);
    final copy = await provider.delete(record);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Se eliminó "${copy.name}"'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => provider.add(copy),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = kind.accent(context);
    final textTheme = Theme.of(context).textTheme;
    final all = context.watch<RecordProvider<T>>().records;

    final months = <DateTime>{
      for (final r in all)
        if (r.date != null) DateTime(r.date!.year, r.date!.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final hasUndated = all.any((r) => r.date == null);
    if (_month != null &&
        !months.contains(_month) &&
        !(_month == _noDate && hasUndated)) {
      _month = null;
    }

    final visible = all.where(_matches).toList();
    final total = visible.fold<double>(0, (s, r) => s + r.amount);
    final monthLabel = DateFormat.yMMMM('es');

    // La barra de navegación se dibuja encima del contenido (extendBody),
    // así que su alto llega aquí como relleno inferior.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: FadeSlideIn(
                    child: SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _month == null
                                      ? 'Total de ${kind.title.toLowerCase()}'
                                      : _month == _noDate
                                      ? 'Sin fecha'
                                      : _capitalize(monthLabel.format(_month!)),
                                  style: textTheme.labelMedium,
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedAmount(
                                    value: total,
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _countLabel(visible),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: tokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AccentIcon(icon: kind.icon, color: accent, size: 52),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (months.isNotEmpty || hasUndated)
              SliverToBoxAdapter(
                child: ContentWidth(
                  child: SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      children: [
                        _filterChip('Todo', null, accent),
                        for (final m in months)
                          _filterChip(
                            _capitalize(
                              DateFormat(
                                m.year == DateTime.now().year
                                    ? 'MMMM'
                                    : 'MMM y',
                                'es',
                              ).format(m),
                            ),
                            m,
                            accent,
                          ),
                        if (hasUndated)
                          _filterChip('Sin fecha', _noDate, accent),
                      ],
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 96),
                  child: visible.isEmpty
                      ? EmptyState(
                          color: accent,
                          title: 'Aún no hay ${kind.title.toLowerCase()}',
                          message:
                              'Toca "Agregar ${kind.singular}" para registrar el primero.',
                        )
                      : SectionCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < visible.length; i++) ...[
                                if (i > 0) const Divider(indent: 70, height: 1),
                                FadeSlideIn(
                                  key: ObjectKey(visible[i]),
                                  index: i,
                                  child: _dismissible(visible[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: bottomInset + 16,
          child: FloatingActionButton.extended(
            heroTag: kind.name,
            backgroundColor: accent,
            foregroundColor: kind.onAccent(context),
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Agregar ${kind.singular}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dismissible(T record) {
    final tokens = AppTokens.of(context);
    return Dismissible(
      key: ObjectKey(record),
      direction: DismissDirection.endToStart,
      background: Container(
        color: tokens.negative,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(record),
      child: RecordTile(
        record: record,
        kind: kind,
        onTap: () => _edit(record),
        onToggleDone: kind.canMarkDone
            ? () => context.read<RecordProvider<T>>().toggleDone(record)
            : null,
      ),
    );
  }

  /// "5 registros"; en deudas y compras añade cuántas faltan:
  /// "5 registros · 2 pendientes" o "5 registros · todas canceladas".
  String _countLabel(List<T> records) {
    final count = records.length == 1
        ? '1 registro'
        : '${records.length} registros';
    if (!kind.canMarkDone || records.isEmpty) return count;
    final pending = records.where((r) => !r.done).length;
    if (pending == 0) return '$count · todas ${kind.doneLabel!.toLowerCase()}s';
    final label = kind.pendingLabel!.toLowerCase();
    // "pendiente" lleva plural; "por comprar" no cambia.
    final plural = pending == 1 || label.contains(' ') ? label : '${label}s';
    return '$count · $pending $plural';
  }

  Widget _filterChip(String label, DateTime? value, Color accent) {
    final selected = _month == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: accent.withValues(alpha: 0.16),
        labelStyle: TextStyle(
          color: selected ? accent : AppTokens.of(context).text,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        onSelected: (_) => setState(() => _month = value),
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
