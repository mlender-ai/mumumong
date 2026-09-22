import 'package:flutter/services.dart';

class SpeechUpdate {
  const SpeechUpdate({
    this.text,
    this.rms = 0,
    this.stopped = false,
    this.code,
  });
  final String? text;
  final double rms;
  final bool stopped;
  final String? code;
}

abstract interface class SpeechInput {
  Stream<SpeechUpdate> get updates;
  Future<void> start();
  Future<void> stop();
}

class OnDeviceSpeechInput implements SpeechInput {
  static const _methods = MethodChannel('mumumong/speech');
  static const _events = EventChannel('mumumong/speech/events');

  @override
  Stream<SpeechUpdate> get updates =>
      _events.receiveBroadcastStream().map((data) {
        final map = data as Map;
        return SpeechUpdate(
          text: map['text'] as String?,
          rms: (map['rms'] as num?)?.toDouble() ?? 0,
          stopped: map['stopped'] == true,
          code: map['code'] as String?,
        );
      });

  @override
  Future<void> start() => _methods.invokeMethod<void>('start');
  @override
  Future<void> stop() async {
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      /* Unsupported platform has no microphone. */
    } on PlatformException {
      /* An interrupted audio session must not prevent saving the draft. */
    }
  }
}
