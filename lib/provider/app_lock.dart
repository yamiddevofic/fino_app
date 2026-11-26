import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

const securityBoxName = 'securityBox';
const pinLength = 4;

/// Tiempo en segundo plano tras el cual la app pide otra vez el PIN. Evita
/// pedirlo al volver de un diálogo del sistema, como elegir un archivo.
const lockAfter = Duration(minutes: 1);

/// PIN que protege la app en este dispositivo.
///
/// Es un candado local: la sesión de Supabase se inicia una vez con correo
/// y contraseña, y el PIN solo evita que otra persona abra la app en el
/// celular o el navegador. Se guarda como hash con sal.
class AppLock with ChangeNotifier {
  AppLock() : _box = Hive.box<String>(securityBoxName);

  final Box<String> _box;

  bool _unlocked = false;
  DateTime? _backgroundSince;

  bool get hasPin => _box.containsKey('pinHash');

  bool get isLocked => hasPin && !_unlocked;

  /// Si el usuario eligió usar la app sin cuenta en este dispositivo.
  bool get offlineMode => _box.get('offlineMode') == 'true';

  Future<void> setOfflineMode(bool value) async {
    await _box.put('offlineMode', '$value');
    notifyListeners();
  }

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    assert(isValidPin(pin));
    final random = Random.secure();
    final salt = base64Url.encode([
      for (var i = 0; i < 16; i++) random.nextInt(256),
    ]);
    await _box.putAll({'pinSalt': salt, 'pinHash': _hash(salt, pin)});
    _unlocked = true;
    notifyListeners();
  }

  /// Desbloquea la app si [pin] es correcto.
  bool unlock(String pin) {
    final salt = _box.get('pinSalt');
    if (salt == null || _hash(salt, pin) != _box.get('pinHash')) return false;
    _unlocked = true;
    notifyListeners();
    return true;
  }

  /// Si el usuario olvidó el PIN y debe iniciar sesión para cambiarlo.
  bool get resettingPin => _box.get('resettingPin') == 'true';

  /// Pide iniciar sesión otra vez; al hacerlo se borra el PIN.
  Future<void> requestPinReset() async {
    await _box.put('resettingPin', 'true');
    notifyListeners();
  }

  /// Se llama al iniciar sesión: completa un cambio de PIN pendiente.
  Future<void> signedIn() async {
    await _box.put('offlineMode', 'false');
    if (resettingPin) {
      await _box.deleteAll(['pinSalt', 'pinHash', 'resettingPin']);
      _unlocked = false;
    }
    notifyListeners();
  }

  void lock() {
    _unlocked = false;
    notifyListeners();
  }

  void wentToBackground() => _backgroundSince = DateTime.now();

  /// Al volver a primer plano bloquea si pasó más de [lockAfter].
  void cameToForeground() {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (since != null && DateTime.now().difference(since) > lockAfter) lock();
  }
}
