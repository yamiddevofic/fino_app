import 'package:fino_app/provider/sync_service.dart';
import 'package:fino_app/screen/auth_screens.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Estado de la sincronización en la barra superior. Al tocarlo abre la
/// cuenta, o el inicio de sesión si se usa la app sin cuenta.
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService?>();
    if (sync == null) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);

    final (icon, tooltip, color) = switch (sync) {
      SyncService(user: null) => (
        Icons.cloud_off_outlined,
        'Conectar con tu cuenta',
        tokens.textMuted,
      ),
      SyncService(status: SyncStatus.syncing) => (
        Icons.cloud_sync_outlined,
        'Sincronizando…',
        tokens.brand,
      ),
      SyncService(status: SyncStatus.error) => (
        Icons.sync_problem_outlined,
        'Error al sincronizar',
        tokens.negative,
      ),
      SyncService(status: SyncStatus.offline) => (
        Icons.cloud_queue_outlined,
        'Sin conexión: los cambios se subirán después',
        tokens.textMuted,
      ),
      _ => (Icons.cloud_done_outlined, 'Sincronizado', tokens.textMuted),
    };

    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: () => sync.user == null
          ? Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => LoginScreen(
                  allowOffline: false,
                  onSignedIn: () async => Navigator.of(context).pop(),
                ),
              ),
            )
          : showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: sync,
                child: const _AccountSheet(),
              ),
            ),
    );
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final tokens = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final last = sync.lastSync;
    final pending = sync.pendingCount;

    final status = switch (sync.status) {
      SyncStatus.syncing => 'Sincronizando…',
      SyncStatus.error => 'Error: ${sync.error ?? 'desconocido'}',
      SyncStatus.offline => 'Sin conexión',
      _ when last == null => 'Aún no se ha sincronizado',
      _ => 'Sincronizado ${DateFormat.MMMd('es').add_Hm().format(last)}',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tu cuenta', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              sync.user?.email ?? '',
              style: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 16),
            Text(status, style: textTheme.bodyMedium),
            if (pending > 0)
              Text(
                pending == 1
                    ? '1 cambio pendiente de subir'
                    : '$pending cambios pendientes de subir',
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: sync.status == SyncStatus.syncing ? null : sync.sync,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Sincronizar ahora'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await sync.signOut();
                navigator.pop();
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
