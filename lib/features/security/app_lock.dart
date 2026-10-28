import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

const _kHash = 'pin_hash';
const _kSalt = 'pin_salt';
const _kBiometric = 'pin_biometric';

/// Hash del PIN: SHA-256 iterado con sal aleatoria. El PIN nunca se guarda.
@visibleForTesting
String hashPin(String pin, String salt, {int rounds = 10000}) {
  var bytes = utf8.encode('$salt:$pin');
  for (var i = 0; i < rounds; i++) {
    bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
  }
  return base64Encode(bytes);
}

class LockSettings {
  const LockSettings({required this.hasPin, required this.biometric});

  final bool hasPin;
  final bool biometric;
}

/// Configuración del bloqueo (PIN + huella opcional).
class LockSettingsNotifier extends Notifier<LockSettings> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  LockSettings build() => LockSettings(
    hasPin: _prefs.getString(_kHash) != null,
    biometric: _prefs.getBool(_kBiometric) ?? false,
  );

  Future<void> setPin(String pin) async {
    final rng = Random.secure();
    final salt = base64Encode(List.generate(16, (_) => rng.nextInt(256)));
    await _prefs.setString(_kSalt, salt);
    await _prefs.setString(_kHash, await compute(_hashArgs, (pin, salt)));
    state = build();
  }

  Future<bool> verify(String pin) async {
    final salt = _prefs.getString(_kSalt);
    final hash = _prefs.getString(_kHash);
    if (salt == null || hash == null) return true;
    return await compute(_hashArgs, (pin, salt)) == hash;
  }

  Future<void> removePin() async {
    await _prefs.remove(_kHash);
    await _prefs.remove(_kSalt);
    await _prefs.remove(_kBiometric);
    state = build();
  }

  Future<void> setBiometric(bool on) async {
    await _prefs.setBool(_kBiometric, on);
    state = build();
  }
}

String _hashArgs((String, String) a) => hashPin(a.$1, a.$2);

final lockSettingsProvider =
    NotifierProvider<LockSettingsNotifier, LockSettings>(
      LockSettingsNotifier.new,
    );

/// Si la app está bloqueada ahora mismo.
class LockedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(lockSettingsProvider).hasPin;

  void lock() {
    if (ref.read(lockSettingsProvider).hasPin) state = true;
  }

  void unlock() => state = false;
}

final lockedProvider = NotifierProvider<LockedNotifier, bool>(
  LockedNotifier.new,
);

/// Huella / rostro del sistema. Devuelve false si no hay o falla.
class Biometrics {
  final _auth = LocalAuthentication();

  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Desbloquea PlataPets',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((ref) => Biometrics());
