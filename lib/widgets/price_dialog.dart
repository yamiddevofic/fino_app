import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/utils/amount.dart';
import 'package:flutter/material.dart';

/// Pide el precio de una compra que se registró sin él. Devuelve `null` si
/// el usuario cancela.
Future<double?> showPriceDialog(
  BuildContext context, {
  required String itemName,
  required Color accent,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _PriceDialog(itemName: itemName, accent: accent),
  );
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.itemName, required this.accent});

  final String itemName;
  final Color accent;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, parseAmount(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('¿Cuánto costó ${widget.itemName}?'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          cursorColor: widget.accent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: textTheme.titleLarge?.copyWith(fontFeatures: tabularFigures),
          decoration: const InputDecoration(hintText: '0', prefixText: r'$ '),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final amount = parseAmount(value ?? '');
            return amount == null || amount <= 0
                ? 'Ingresa un monto mayor que cero'
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.accent,
            foregroundColor: onColor(widget.accent),
          ),
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
