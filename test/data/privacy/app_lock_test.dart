import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/auth/secure_session_storage.dart';
import 'package:mumumong/data/privacy/app_lock.dart';

class MemoryStore implements SecureValueStore {
  final values = <String, String>{};
  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class FakeAuth implements DeviceAuthenticator {
  FakeAuth(this.results);
  final List<bool> results;
  int calls = 0;
  @override
  Future<bool> authenticate() async => results[calls++];
}

void main() {
  test('lock defaults off and enabling requires authentication', () async {
    final store = MemoryStore();
    final auth = FakeAuth([false, true]);
    final controller = AppLockController(store, auth);
    await controller.load();
    expect(controller.enabled, false);
    expect(await controller.setEnabled(true), false);
    expect(controller.enabled, false);
    expect(await controller.setEnabled(true), true);
    expect(controller.enabled, true);
    expect(store.values[AppLockController.storageKey], 'true');
  });

  test(
    'background lock and disabling both require successful device auth',
    () async {
      final store = MemoryStore()
        ..values[AppLockController.storageKey] = 'true';
      final auth = FakeAuth([true, false, true]);
      final controller = AppLockController(store, auth);
      await controller.load();
      expect(controller.unlocked, true);
      controller.lock();
      expect(controller.unlocked, false);
      expect(await controller.setEnabled(false), false);
      expect(controller.enabled, true);
      expect(await controller.setEnabled(false), true);
      expect(controller.enabled, false);
      expect(store.values, isEmpty);
    },
  );
}
