import 'package:fino_app/app_colors.dart';
import 'package:flutter/material.dart';

class FinanceEntryPage extends StatefulWidget {
  const FinanceEntryPage({
    super.key,
    required this.title,
    required this.description,
    required this.entryType,
    required this.successMessage,
    required this.accentColor,
    required this.icon,
    required this.onSave,
    required this.onShowHistory,
    this.allowPendingPrice = false,
  });

  final String title;
  final String description;
  final String entryType;
  final String successMessage;
  final Color accentColor;
  final IconData icon;
  final Future<void> Function(String name, double amount, {bool isPricePending})
      onSave;
  final VoidCallback onShowHistory;
  final bool allowPendingPrice;

  @override
  State<FinanceEntryPage> createState() => _FinanceEntryPageState();
}

class _FinanceEntryPageState extends State<FinanceEntryPage>
    with AutomaticKeepAliveClientMixin<FinanceEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _saving = false;
  bool _isPricePending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameController.text.trim();
    final isPending = _isPricePending && widget.allowPendingPrice;
    final amount = isPending ? 0.0 : _parseAmount(_amountController.text)!;
    setState(() => _saving = true);

    try {
      await widget.onSave(name, amount, isPricePending: isPending);
      if (!mounted) return;
      _formKey.currentState?.reset();
      _nameController.clear();
      _amountController.clear();
      const feedbackColor = AppColors.success;
      final feedbackForeground = AppColors.onAccent(feedbackColor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: feedbackColor,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: feedbackForeground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.successMessage,
                  style: TextStyle(color: feedbackForeground),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final feedbackColor = Theme.of(context).colorScheme.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: feedbackColor,
          content: Text(
            'No se pudo guardar ${widget.entryType}. Inténtalo de nuevo.',
            style: TextStyle(color: AppColors.onAccent(feedbackColor)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final foreground = AppColors.onAccent(widget.accentColor);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xl,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    side: BorderSide(
                      color: widget.accentColor.withValues(alpha: .2),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 360
                          ? AppSpacing.lg
                          : AppSpacing.xl,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      widget.accentColor.withValues(alpha: .12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.control),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.title,
                                        style: textTheme.titleLarge),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      widget.description,
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).nextFocus(),
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ej. Arriendo, mercado...',
                              prefixIcon: Icon(Icons.label_outline_rounded),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Escribe un nombre para el registro'
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _save(),
                            enabled: !_isPricePending,
                            decoration: InputDecoration(
                              labelText: 'Monto',
                              hintText: '0,00',
                              prefixText: 'COP  ',
                              prefixIcon: Icon(Icons.payments_outlined),
                              disabledBorder: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isPricePending && widget.allowPendingPrice) {
                                return null;
                              }
                              final amount = _parseAmount(value ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Ingresa un monto mayor que cero';
                              }
                              return null;
                            },
                          ),
                          if (widget.allowPendingPrice) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isPricePending,
                                  onChanged: (value) => setState(
                                      () => _isPricePending = value ?? false),
                                  activeColor: widget.accentColor,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() =>
                                        _isPricePending = !_isPricePending),
                                    child: Text(
                                      'Precio indefinido (lo ingresaré después)',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final saveButton = FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: widget.accentColor,
                                  foregroundColor: foreground,
                                ),
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              foreground),
                                        ),
                                      )
                                    : const Icon(Icons.add_rounded),
                                label: Text(_saving ? 'Guardando' : 'Agregar'),
                              );
                              final historyButton = OutlinedButton.icon(
                                onPressed:
                                    _saving ? null : widget.onShowHistory,
                                icon: const Icon(Icons.history_rounded),
                                label: const Text('Historial'),
                              );

                              if (constraints.maxWidth < 400) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    saveButton,
                                    const SizedBox(height: AppSpacing.sm),
                                    historyButton,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: saveButton),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: historyButton),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
