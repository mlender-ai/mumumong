import 'dart:async';
import 'dart:math' as math;

import '../../data/speech/speech_input.dart';

/// DESIGN MOCK: a scripted voice for the preview. It emits a newly written,
/// fictional dream with a synthetic level so the recording interaction can
/// be seen on a simulator. It never touches the microphone.
class PreviewSpeechInput implements SpeechInput {
  PreviewSpeechInput({this.script = previewVoiceScript});

  static const previewVoiceScript =
      '낡은 엘리베이터가 바다 쪽으로 열렸다. 문이 열릴 때마다 젖은 모래 냄새가 났고, '
      '버튼에는 숫자 대신 계절이 적혀 있었다. 나는 겨울을 눌렀다.';

  final String script;
  final _controller = StreamController<SpeechUpdate>.broadcast();
  Timer? _timer;

  @override
  Stream<SpeechUpdate> get updates => _controller.stream;

  @override
  Future<void> start() async {
    _timer?.cancel();
    final words = script.split(' ');
    var index = 0;
    var tick = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      tick++;
      // Speech-like level: syllable pulses with short pauses between words.
      final pause = tick % 6 == 0;
      final level = pause
          ? .08
          : (.45 + .4 * math.sin(tick * 1.7).abs()).clamp(0.0, 1.0);
      String? text;
      if (tick % 4 == 0 && index < words.length) {
        index++;
        text = words.take(index).join(' ');
      }
      if (index >= words.length && tick % 4 == 2) {
        _controller.add(const SpeechUpdate(stopped: true));
        timer.cancel();
        return;
      }
      _controller.add(SpeechUpdate(text: text, rms: level));
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }
}
