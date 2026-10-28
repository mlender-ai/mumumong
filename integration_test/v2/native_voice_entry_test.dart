// Migrated from integration_test/native_voice_entry_test.dart (V1). Simulator
// UI verification, not a real microphone or recognition accuracy test: the
// native V2 capture shows the record button, and when on-device speech is
// unavailable it says so, settles without motion and keeps the draft
// editable and saved.
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/settings.dart';

import 'harness.dart';

class _UnavailableSpeech implements SpeechInput {
  @override
  Stream<SpeechUpdate> get updates => const Stream.empty();
  @override
  Future<void> start() async =>
      throw PlatformException(code: 'on_device_unavailable');
  @override
  Future<void> stop() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 native record button; unsupported speech keeps an editable draft without motion',
    (tester) async {
      final repo = MemoryRepository();
      try {
        await mountV2Native(
          tester,
          const V2CaptureFlow(dreamNumber: 1, sceneNumber: 1),
          speech: false,
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            speechInputProvider.overrideWithValue(_UnavailableSpeech()),
          ],
        );
        await waitFor(tester, find.bySemanticsLabel('말로 기록하기'));
        await tapNative(tester, find.bySemanticsLabel('말로 기록하기'));
        // Native starts recognition in place; only the web opens the guide.
        expect(find.byType(V2VoicePage), findsNothing);
        expect(v2TextContaining('이 기기에서 음성 인식을 사용할 수 없어요'), findsOneWidget);
        expect(find.bySemanticsLabel('말로 기록하기'), findsOneWidget);
        expect(tester.binding.hasScheduledFrame, isFalse);

        await tester.enterText(find.byType(TextField), '가상 꿈: 종이별이 창가에서 노래했다.');
        await tester.pump(const Duration(milliseconds: 600));
        expect((await repo.loadDraft())!.rawText, '가상 꿈: 종이별이 창가에서 노래했다.');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(v2Text('꿈 저장하기').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await unmount(tester);
        repo.dispose();
      }
    },
  );
}
