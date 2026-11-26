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

    final mode = await showDialog<_ImportMode>(
      context: context,
      builder: (context) => _ConfirmImportDialog(
        backup: backup,
        currentCount: sources.recordCount,
      ),
    );
    switch (mode) {
      case null:
        return;
      case _ImportMode.replace:
        await sources.restore(backup);
        _show(messenger, 'Se importaron ${_records(backup.recordCount)}');
      case _ImportMode.merge:
        final result = await sources.merge(backup);
        _show(messenger, _mergeMessage(result));
    }
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

String _mergeMessage(MergeResult result) {
  final MergeResult(:added, :skipped, :categoriesAdded) = result;
  if (added == 0 && categoriesAdded == 0) {
    return 'Todo el respaldo ya estaba en la app';
  }
  return [
        'Se agregaron ${_records(added)}',
        if (categoriesAdded > 0)
          categoriesAdded == 1 ? '1 categoría' : '$categoriesAdded categorías',
      ].join(' y ') +
      switch (skipped) {
        0 => '',
        1 => '; 1 ya existía',
        _ => '; $skipped ya existían',
      };
}

String _records(int count) => count == 1 ? '1 registro' : '$count registros';

enum _ImportMode { merge, replace }

class _ConfirmImportDialog extends StatelessWidget {
  const _ConfirmImportDialog({
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
    final hasData = currentCount > 0;
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
          if (hasData) ...[
            'Combinar agrega lo que no tengas todavía y conserva tus '
                '${_records(currentCount)} actuales.',
            'Reemplazar borra tus datos actuales y deja solo los del '
                'respaldo.',
          ],
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (hasData)
          TextButton(
            onPressed: () => Navigator.pop(context, _ImportMode.replace),
            child: const Text('Reemplazar'),
          ),
        FilledButton(
          // Sin datos actuales ambos modos dan lo mismo; combinar es el
          // más seguro.
          onPressed: () => Navigator.pop(context, _ImportMode.merge),
          child: Text(hasData ? 'Combinar' : 'Importar'),
        ),
      ],
    );
  }
}
