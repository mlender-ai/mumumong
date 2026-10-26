// Simulator UI verification, not a real microphone/recognition accuracy test.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';

class UnavailableSpeech implements SpeechInput {
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
    'native microphone is visible; unsupported speech preserves editable draft without animation',
    (tester) async {
      final repo = MemoryRepository();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              speechInputProvider.overrideWithValue(UnavailableSpeech()),
            ],
            child: MaterialApp(
              theme: mumumongTheme(),
              home: const CaptureFlow(dreamNumber: 1, sceneNumber: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.mic_none), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('녹음 시작'));
        await tester.pumpAndSettle();
        expect(find.textContaining('이 기기에서 음성 인식을 사용할 수 없어요'), findsOneWidget);
        expect(find.byType(ThinkingOrb), findsNothing);
        expect(find.byType(BeamFrame), findsNothing);
        await tester.enterText(find.byType(TextField), '가상 꿈: 종이별이 창가에서 노래했다.');
        await tester.pump(const Duration(milliseconds: 600));
        expect((await repo.loadDraft())!.rawText, '가상 꿈: 종이별이 창가에서 노래했다.');
        expect(find.text('꿈 저장하기').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        repo.dispose();
      }
    },
  );
}
