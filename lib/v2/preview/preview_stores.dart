import 'dart:ui' show Rect;

import '../../core/design/ui_preferences.dart';
import '../../data/auth/secure_session_storage.dart';
import '../../data/privacy/app_lock.dart';
import '../../ui/settings/record_actions.dart';

/// Preview-only stores: nothing is written to the device.
class MemoryUiPreferenceStore implements UiPreferenceStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async => value = next;
}

class MemorySecureValueStore implements SecureValueStore {
  final _values = <String, String>{};
  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class PreviewAuthenticator implements DeviceAuthenticator {
  const PreviewAuthenticator();
  @override
  Future<bool> authenticate() async => true;
}

/// The preview never exports or deletes anything: there is no real record
/// and no account. The settings page also disables both rows.
class PreviewRecordActions implements RecordActions {
  const PreviewRecordActions();

  @override
  Future<void> shareExport({Rect? origin}) =>
      Future.error(UnsupportedError('preview_has_no_records'));

  @override
  Future<void> deleteEverything() =>
      Future.error(UnsupportedError('preview_has_no_account'));
}
