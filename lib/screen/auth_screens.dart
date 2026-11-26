import 'dart:async';

import 'package:fino_app/provider/app_lock.dart';
import 'package:fino_app/provider/sync_service.dart';
import 'package:fino_app/theme/app_theme.dart';
import 'package:fino_app/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Decide qué mostrar al abrir la app: iniciar sesión, crear el PIN,
/// pedirlo o el contenido.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = context.read<AppLock>();
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        lock.wentToBackground();
      case AppLifecycleState.resumed:
        lock.cameToForeground();
        unawaited(context.read<SyncService?>()?.sync());
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLock>();
    final sync = context.watch<SyncService?>();
    final signedIn = sync?.user != null;

    if (!signedIn && (lock.resettingPin || !lock.offlineMode)) {
      return LoginScreen(allowOffline: !lock.resettingPin);
    }
    if (!lock.hasPin) return const PinScreen.create();
    if (lock.isLocked) return const PinScreen.unlock();
    return widget.child;
  }
}

/// Inicio de sesión con correo y contraseña. Se hace una vez por
/// dispositivo; después basta con el PIN.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSignedIn, this.allowOffline = true});

  /// Se llama tras iniciar sesión. Si es `null` la pantalla no se cierra
  /// sola, porque la muestra [AuthGate].
  final Future<void> Function()? onSignedIn;

  /// Muestra la opción de usar la app sin cuenta.
  final bool allowOffline;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool create}) async {
    if (!_formKey.currentState!.validate()) return;
    final sync = context.read<SyncService?>();
    final lock = context.read<AppLock>();
    if (sync == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final auth = sync.client.auth;
    try {
      final email = _email.text.trim();
      final password = _password.text;
      final response = create
          ? await auth.signUp(email: email, password: password)
          : await auth.signInWithPassword(email: email, password: password);
      if (response.session == null) {
        setState(() {
          _message =
              'Te enviamos un correo para confirmar la cuenta. '
              'Ábrelo y luego vuelve aquí para entrar.';
          _messageIsError = false;
        });
        return;
      }
      await lock.signedIn();
      await widget.onSignedIn?.call();
    } on AuthException catch (e) {
      setState(() {
        _message = _authMessage(e);
        _messageIsError = true;
      });
    } on Exception {
      setState(() {
        _message = 'No hay conexión. Inténtalo de nuevo.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: widget.onSignedIn == null ? null : AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ContentWidth(
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SvgPicture.asset(
                        'assets/svg/logo.svg',
                        width: 56,
                        height: 56,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tu cuenta de Fino',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guarda tus registros en la nube y úsalos en el '
                        'celular y en el navegador. Después solo te '
                        'pediremos tu PIN.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Correo'),
                        validator: (v) => (v ?? '').contains('@')
                            ? null
                            : 'Escribe tu correo',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        validator: (v) =>
                            (v ?? '').length < 8 ? 'Mínimo 8 caracteres' : null,
                        onFieldSubmitted: (_) => _submit(create: false),
                      ),
                      if (_message case final message?) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: _messageIsError
                                ? tokens.negative
                                : tokens.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : () => _submit(create: false),
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : () => _submit(create: true),
                        child: const Text('Crear cuenta'),
                      ),
                      if (widget.allowOffline) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => context.read<AppLock>().setOfflineMode(
                                  true,
                                ),
                          child: const Text('Usar sin cuenta por ahora'),
                        ),
                      ],
                    ],
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

String _authMessage(AuthException e) => switch (e.code) {
  'invalid_credentials' => 'Correo o contraseña incorrectos.',
  'email_not_confirmed' => 'Confirma tu correo antes de entrar.',
  'user_already_exists' => 'Ya existe una cuenta con ese correo. Entra.',
  'weak_password' => 'La contraseña es muy débil.',
  'over_email_send_rate_limit' =>
    'Se enviaron demasiados correos. Espera unos minutos.',
  _ => e.message,
};

/// Crea el PIN o lo pide para abrir la app.
class PinScreen extends StatefulWidget {
  const PinScreen.create({super.key}) : creating = true;
  const PinScreen.unlock({super.key}) : creating = false;

  final bool creating;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

const _maxAttempts = 5;

class _PinScreenState extends State<PinScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _first;
  String? _error;
  int _failures = 0;
  DateTime? _blockedUntil;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    if (value.length < pinLength) return;
    final lock = context.read<AppLock>();
    _controller.clear();

    if (widget.creating) {
      final first = _first;
      if (first == null) {
        setState(() {
          _first = value;
          _error = null;
        });
      } else if (first == value) {
        await lock.setPin(value);
      } else {
        setState(() {
          _first = null;
          _error = 'Los PIN no coinciden. Empieza de nuevo.';
        });
      }
      return;
    }

    final blockedUntil = _blockedUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return;
    if (lock.unlock(value)) return;
    _failures++;
    setState(() {
      if (_failures >= _maxAttempts) {
        _failures = 0;
        _blockedUntil = DateTime.now().add(const Duration(seconds: 30));
        _error = 'Demasiados intentos. Espera 30 segundos.';
      } else {
        _error = 'PIN incorrecto';
      }
    });
  }

  Future<void> _forgot() async {
    final lock = context.read<AppLock>();
    final sync = context.read<SyncService?>();
    if (sync == null || sync.user == null) {
      setState(
        () => _error =
            'Sin cuenta no se puede recuperar el PIN. Para empezar de '
            'nuevo, borra los datos de la app o reinstálala.',
      );
      return;
    }
    // Para cambiar el PIN hay que demostrar que se es el dueño de la cuenta.
    await lock.requestPinReset();
    await sync.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = widget.creating
        ? (_first == null ? 'Crea tu PIN' : 'Repite tu PIN')
        : 'Ingresa tu PIN';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: tokens.brand,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                  if (widget.creating) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lo pediremos cada vez que abras Fino en este '
                      'dispositivo.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 180,
                      child: TextField(
                        key: const ValueKey('pin'),
                        controller: _controller,
                        focusNode: _focus,
                        autofocus: true,
                        obscureText: true,
                        obscuringCharacter: '●',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: pinLength,
                        style: textTheme.headlineMedium?.copyWith(
                          letterSpacing: 16,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(counterText: ''),
                        onChanged: _onChanged,
                      ),
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.negative,
                      ),
                    ),
                  ],
                  if (!widget.creating) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _forgot,
                      child: const Text('¿Olvidaste tu PIN?'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
