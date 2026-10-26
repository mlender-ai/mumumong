import 'package:mumumong/core/design/ui_preferences.dart';

class MemoryUiStore implements UiPreferenceStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('test_storage_failure');
    this.value = value;
  }
}
