import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SecureValueStore {
  Future<String?> read(String key);
  Future<bool> containsKey(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class KeychainValueStore implements SecureValueStore {
  KeychainValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<bool> containsKey(String key) {
    return _storage.containsKey(key: key, iOptions: _iosOptions);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key, iOptions: _iosOptions);
  }

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key, iOptions: _iosOptions);
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value, iOptions: _iosOptions);
  }
}

class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({SecureValueStore? store})
    : _store = store ?? KeychainValueStore();

  static const sessionKey = 'mumumong.supabase.session';

  final SecureValueStore _store;

  @override
  Future<String?> accessToken() => _store.read(sessionKey);

  @override
  Future<bool> hasAccessToken() => _store.containsKey(sessionKey);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> persistSession(String persistSessionString) {
    return _store.write(sessionKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() => _store.delete(sessionKey);
}
