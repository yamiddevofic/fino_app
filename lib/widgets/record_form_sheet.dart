import 'package:fino_app/models/finance_record.dart';
import 'package:fino_app/models/record_kind.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Abre el formulario para crear un registro, o para editar [initial].
/// Devuelve el registro nuevo, o `null` si el usuario cancela.
Future<T?> showRecordForm<T extends FinanceRecord>(
  BuildContext context, {
  required RecordKind kind,
  required RecordBuilder<T> builder,
  T? initial,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _RecordForm<T>(kind: kind, builder: builder, initial: initial),
  );
}

class _RecordForm<T extends FinanceRecord> extends StatefulWidget {
  const _RecordForm({required this.kind, required this.builder, this.initial});

  final RecordKind kind;
  final RecordBuilder<T> builder;
  final T? initial;

  @override
  State<_RecordForm<T>> createState() => _RecordFormState<T>();
}

class _RecordFormState<T extends FinanceRecord> extends State<_RecordForm<T>> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : formatCop(widget.initial!.amount).replaceAll(r'$', '').trim(),
  );
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _note = TextEditingController(text: widget.initial?.note);
  late String? _category = widget.initial?.category;
  late DateTime _date =
      widget.initial?.date ?? DateUtils.dateOnly(DateTime.now());

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    Navigator.pop(
      context,
      widget.builder(
        name: _name.text.trim(),
        amount: parseAmount(_amount.text)!,
        date: _date,
        category: _category,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final accent = widget.kind.accent(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_editing ? 'Editar' : 'Nuevo'} ${widget.kind.singular}',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amount,
                autofocus: !_editing,
                cursorColor: accent,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                style: textTheme.headlineMedium?.copyWith(
                  color: accent,
                  fontFeatures: tabularFigures,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: r'$ ',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  prefixStyle: textTheme.headlineMedium?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
                validator: (value) {
                  final amount = parseAmount(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto mayor que cero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa una descripción'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('Categoría', style: textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in widget.kind.categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      showCheckmark: false,
                      selectedColor: accent.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        color: _category == c ? accent : tokens.text,
                        fontWeight: _category == c
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      onSelected: (selected) =>
                          setState(() => _category = selected ? c : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(Icons.event_outlined, color: tokens.textMuted),
                  title: Text(DateFormat.yMMMMd('es').format(_date)),
                  trailing: Icon(Icons.chevron_right, color: tokens.textMuted),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: widget.kind.onAccent(context),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _submit,
                child: Text(_editing ? 'Guardar cambios' : 'Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
