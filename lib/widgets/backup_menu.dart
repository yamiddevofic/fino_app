import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:fino_app/models/buys_model.dart';
import 'package:fino_app/models/debts_model.dart';
import 'package:fino_app/models/expenses_model.dart';
import 'package:fino_app/models/incomes_model.dart';
import 'package:fino_app/provider/backup.dart';
import 'package:fino_app/provider/category_provider.dart';
import 'package:fino_app/provider/record_provider.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Acceso a los archivos del dispositivo. Las pruebas lo sustituyen para no
/// abrir los diálogos del sistema.
class BackupFiles {
  const BackupFiles();

  /// Guarda [bytes] donde elija el usuario. Devuelve `false` si canceló.
  Future<bool> save(String fileName, Uint8List bytes) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Guardar respaldo',
      fileName: fileName,
      bytes: bytes,
    );
    // En la web el navegador descarga el archivo y no hay ruta.
    return path != null || kIsWeb;
  }

  /// Contenido del archivo que elija el usuario, o `null` si canceló.
  Future<Uint8List?> pick() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Elegir respaldo',
      withData: true,
    );
    return result?.files.single.bytes;
  }
}

/// Menú de la barra superior para exportar e importar todos los datos.
class BackupMenuButton extends StatelessWidget {
  const BackupMenuButton({super.key, this.files = const BackupFiles()});

  final BackupFiles files;

  BackupSources _sources(BuildContext context) => BackupSources(
    incomes: context.read<RecordProvider<Income>>(),
    expenses: context.read<RecordProvider<Expense>>(),
    debts: context.read<RecordProvider<Debt>>(),
    buys: context.read<RecordProvider<Buy>>(),
    categories: context.read<CategoryProvider>(),
  );

  Future<void> _export(BuildContext context) async {
    final sources = _sources(context);
    final messenger = ScaffoldMessenger.of(context);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String message;
    try {
      final saved = await files.save(
        'fino-respaldo-$date.json',
        utf8.encode(sources.export()),
      );
      if (!saved) return;
      message = 'Respaldo guardado con ${_records(sources.recordCount)}';
    } on Exception {
      _show(messenger, 'No se pudo guardar el respaldo');
      return;
    }
    _show(messenger, message);
  }

  Future<void> _import(BuildContext context) async {
    final sources = _sources(context);
    final messenger = ScaffoldMessenger.of(context);

    final Backup backup;
    try {
      final bytes = await files.pick();
      if (bytes == null) return;
      backup = parseBackup(utf8.decode(bytes));
    } on BackupException catch (e) {
      _show(messenger, e.message);
      return;
    } on Exception {
      _show(messenger, 'No se pudo leer el archivo');
      return;
    }
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmRestoreDialog(
        backup: backup,
        currentCount: sources.recordCount,
      ),
    );
    if (confirmed != true) return;

    await sources.restore(backup);
    _show(messenger, 'Se importaron ${_records(backup.recordCount)}');
  }

  void _show(ScaffoldMessengerState messenger, String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Respaldo de datos',
      icon: Icon(Icons.more_vert_rounded, color: tokens.textMuted),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: () => _export(context),
          child: const ListTile(
            leading: Icon(Icons.upload_file_rounded),
            title: Text('Exportar datos'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: () => _import(context),
          child: const ListTile(
            leading: Icon(Icons.download_rounded),
            title: Text('Importar datos'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

String _records(int count) => count == 1 ? '1 registro' : '$count registros';

class _ConfirmRestoreDialog extends StatelessWidget {
  const _ConfirmRestoreDialog({
    required this.backup,
    required this.currentCount,
  });

  final Backup backup;
  final int currentCount;

  @override
  Widget build(BuildContext context) {
    final exportedAt = backup.exportedAt;
    final when = exportedAt == null
        ? ''
        : ' (${DateFormat.yMMMd('es').add_Hm().format(exportedAt)})';
    final categories = backup.categoryCount;
    final contents = [
      _records(backup.recordCount),
      if (categories > 0)
        categories == 1
            ? '1 categoría propia'
            : '$categories categorías propias',
    ].join(' y ');
    return AlertDialog(
      title: const Text('Importar respaldo'),
      content: Text(
        [
          'El respaldo$when tiene $contents.',
          if (currentCount > 0)
            'Reemplazará tus ${_records(currentCount)} actuales y tus '
                'categorías propias. Si quieres conservarlos, exporta antes '
                'un respaldo.',
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
