import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../auth/secure_session_storage.dart';

abstract interface class DeviceAuthenticator {
  Future<bool> authenticate();
}

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  LocalDeviceAuthenticator({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();
  final LocalAuthentication _authentication;

  @override
  Future<bool> authenticate() async {
    if (!await _authentication.isDeviceSupported()) return false;
    return _authentication.authenticate(
      localizedReason: '무무몽의 꿈과 원고를 열어보려면 인증해 주세요.',
      persistAcrossBackgrounding: true,
    );
  }
}

class AppLockController extends ChangeNotifier {
  AppLockController(this._store, this._authenticator);
  static const storageKey = 'mumumong.app_lock.enabled';
  final SecureValueStore _store;
  final DeviceAuthenticator _authenticator;
  bool _loaded = false;
  bool _enabled = false;
  bool _unlocked = true;
  bool _authenticating = false;

  bool get loaded => _loaded;
  bool get enabled => _enabled;
  bool get unlocked => !_enabled || _unlocked;
  bool get authenticating => _authenticating;

  Future<void> load() async {
    if (_loaded) return;
    try {
      _enabled = await _store.read(storageKey) == 'true';
    } on Object {
      _enabled = false;
    }
    _loaded = true;
    _unlocked = !_enabled;
    notifyListeners();
    if (_enabled) await unlock();
  }

  void lock() {
    if (!_enabled || !_unlocked) return;
    _unlocked = false;
    notifyListeners();
  }

  Future<bool> unlock() async => _verify(() => _unlocked = true);

  Future<bool> setEnabled(bool value) async {
    if (!_loaded) await load();
    if (value == _enabled) return true;
    return _verify(() async {
      if (value) {
        await _store.write(storageKey, 'true');
      } else {
        await _store.delete(storageKey);
      }
      _enabled = value;
      _unlocked = true;
    });
  }

  Future<bool> _verify(FutureOr<void> Function() onSuccess) async {
    if (_authenticating) return false;
    _authenticating = true;
    notifyListeners();
    var success = false;
    try {
      success = await _authenticator.authenticate();
      if (success) await onSuccess();
    } on Object {
      success = false;
    } finally {
      _authenticating = false;
      notifyListeners();
    }
    return success;
  }
}
