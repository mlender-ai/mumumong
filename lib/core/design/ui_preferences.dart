import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class UiPreferenceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceUiPreferenceStore implements UiPreferenceStore {
  DeviceUiPreferenceStore({this.storageKey = key});
  static const key = 'mumumong.ui.v1';
  final String storageKey;
  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(storageKey);
  @override
  Future<void> write(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      storageKey,
      value,
    )) {
      throw StateError('ui_preferences_not_saved');
    }
  }
}

/// Device-only appearance metadata. Never stores dreams, prose or credentials.
class UiPreferences extends ChangeNotifier {
  UiPreferences(this.store) {
    ready = _load();
  }
  final UiPreferenceStore store;
  late final Future<void> ready;
  ThemeMode themeMode = ThemeMode.light;
  double readerScale = 1;
  bool showOrigins = false;
  bool saving = false;
  bool loadFailed = false;
  bool _disposed = false;

  Future<void> _load() async {
    try {
      final raw = await store.read();
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        themeMode =
            ThemeMode.values
                .where((v) => v.name == json['theme'])
                .firstOrNull ??
            ThemeMode.light;
        final scale = json['reader_scale'];
        if (scale is num && scale.isFinite) {
          readerScale = scale.toDouble().clamp(.85, 1.5);
        }
        showOrigins = json['show_origins'] == true;
      }
    } on Object {
      loadFailed = true;
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> save({ThemeMode? theme, double? scale, bool? origins}) async {
    await ready;
    if (saving || _disposed) return false;
    final nextTheme = theme ?? themeMode;
    final nextScale = (scale ?? readerScale).clamp(.85, 1.5).toDouble();
    final nextOrigins = origins ?? showOrigins;
    saving = true;
    notifyListeners();
    try {
      await store.write(
        jsonEncode({
          'theme': nextTheme.name,
          'reader_scale': nextScale,
          'show_origins': nextOrigins,
        }),
      );
      if (_disposed) return false;
      themeMode = nextTheme;
      readerScale = nextScale;
      showOrigins = nextOrigins;
      loadFailed = false;
      return true;
    } on Object {
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
