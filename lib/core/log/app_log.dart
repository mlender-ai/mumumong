import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

const _allowedKeys = {
  'dream_id',
  'volume_id',
  'scene_id',
  'passage_id',
  'job_id',
  'user_id',
  'stage',
  'status',
  'code',
  'ms',
  'count',
  'attempt',
  'origin',
  'mode',
  'env',
};

typedef AppLogSink = void Function(String name, Map<String, Object?> fields);

abstract final class AppLog {
  static AppLogSink _sink = _developerSink;

  static void event(String name, [Map<String, Object?> fields = const {}]) {
    final safe = <String, Object?>{};
    fields.forEach((key, value) {
      if (!_allowedKeys.contains(key)) return;
      if (value is String && value.length > 64) return;
      safe[key] = value;
    });
    _sink(name, Map.unmodifiable(safe));
  }

  @visibleForTesting
  static void setSinkForTesting(AppLogSink sink) {
    _sink = sink;
  }

  @visibleForTesting
  static void resetSinkForTesting() {
    _sink = _developerSink;
  }

  static void _developerSink(String name, Map<String, Object?> fields) {
    developer.log(jsonEncode(fields), name: name);
  }
}
