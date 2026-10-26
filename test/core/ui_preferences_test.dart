import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mumumong/core/design/ui_preferences.dart';
import '../support/ui_preference_store.dart';

void main() {
  test(
    'appearance round trip survives a fresh controller and device store',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = UiPreferences(DeviceUiPreferenceStore());
      await first.ready;
      expect(
        await first.save(theme: ThemeMode.dark, scale: 1.4, origins: true),
        isTrue,
      );
      first.dispose();
      final next = UiPreferences(DeviceUiPreferenceStore());
      await next.ready;
      expect(next.themeMode, ThemeMode.dark);
      expect(next.readerScale, 1.4);
      expect(next.showOrigins, isTrue);
      next.dispose();
    },
  );
  test('failed setting save preserves the previous appearance', () async {
    final store = MemoryUiStore();
    final preferences = UiPreferences(store);
    await preferences.ready;
    await preferences.save(theme: ThemeMode.dark);
    store.fail = true;
    expect(await preferences.save(theme: ThemeMode.light, scale: 1.4), isFalse);
    expect(preferences.themeMode, ThemeMode.dark);
    expect(preferences.readerScale, 1);
    expect(preferences.saving, isFalse);
    preferences.dispose();
  });
  test('malformed settings fail safe and a valid save recovers', () async {
    final store = MemoryUiStore()..value = '{broken';
    final preferences = UiPreferences(store);
    await preferences.ready;
    expect(preferences.loadFailed, isTrue);
    expect(preferences.themeMode, ThemeMode.light);
    expect(await preferences.save(scale: 50), isTrue);
    expect(preferences.readerScale, 1.5);
    expect(preferences.loadFailed, isFalse);
    preferences.dispose();
  });
}
