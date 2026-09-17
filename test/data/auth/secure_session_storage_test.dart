import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/auth/secure_session_storage.dart';

void main() {
  test('세션은 전용 Keychain 키로 저장·조회·삭제한다', () async {
    final store = _MemorySecureValueStore();
    final storage = SecureSessionStorage(store: store);

    await storage.initialize();
    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession('session-json');
    expect(store.lastKey, SecureSessionStorage.sessionKey);
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), 'session-json');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });
}

class _MemorySecureValueStore implements SecureValueStore {
  final Map<String, String> _values = {};
  String? lastKey;

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    lastKey = key;
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    lastKey = key;
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    lastKey = key;
    _values[key] = value;
  }
}
