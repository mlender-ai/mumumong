// Phase visual evidence only. Memory fixtures; no auth, network, or hosted data.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';

void main() {
  const captureDirectory = String.fromEnvironment(
    'UX_CAPTURE_DIR',
    defaultValue: '../docs/ux-review/2026-10-23-mobile-native',
  );
  setUpAll(() async {
    await (FontLoader('Pretendard')
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Regular.otf'))
          ..addFont(rootBundle.load('assets/fonts/Pretendard-Medium.otf')))
        .load();
    await (FontLoader('MaruBuri')
          ..addFont(rootBundle.load('assets/fonts/MaruBuri-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/MaruBuri-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('phase captures current screens using isolated synthetic data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryRepository();
    final engine = MockEngineClient(
      store: repository,
      stageDelay: const Duration(seconds: 1),
    );

    Future<void> mount(Widget screen, {bool offline = false}) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            engineClientProvider.overrideWithValue(engine),
            if (offline)
              networkConnectedProvider.overrideWith(
                (ref) => Stream.value(false),
              ),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: RepaintBoundary(
                key: const Key('p0-capture'),
                child: child,
              ),
            ),
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('p0-capture')),
        matchesGoldenFile('$captureDirectory/$name.png'),
      );
    }

    try {
      await mount(
        OnboardingScreen(
          policy: AiConsentPolicy(
            version: 1,
            message: '가상 테스트용 고지입니다. 실제 동의는 기록하지 않습니다.',
            providers: [
              AiProviderDisclosure(
                id: 'fixture',
                name: '가상 테스트 제공사',
                termsUrl: Uri.parse('https://example.test/terms'),
                dataUrl: Uri.parse('https://example.test/data'),
              ),
            ],
          ),
          onApplePressed: (_) {},
        ),
      );
      await capture('01-entry');
      await tester.tap(find.text('Apple로 시작하기'));
      await tester.pumpAndSettle();
      await capture('02-consent');
      await mount(VolumeSetupScreen(onComplete: () {}));
      await capture('03-volume-setup');
      await mount(const MumumongShell());
      await capture('04-home');
      await tester.tap(find.text('보관함'));
      await tester.pumpAndSettle();
      await capture('05-archive');
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await capture('06-settings');
      await mount(const ReaderScreen());
      await capture('07-reader');
      await mount(const CaptureFlow(dreamNumber: 8, sceneNumber: 3));
      await capture('08-capture');
      await tester.enterText(
        find.byType(TextField).first,
        '나는 물이 찬 긴 복도에 서 있었다. 붉은 문 앞의 여자가 우산을 쥐고 문을 두드렸다. 문틈에서 물소리가 들렸다.',
      );
      await tester.tap(find.text('꿈 저장하기'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await capture('09-saved');
      await tester.ensureVisible(find.text('장면 만들기'));
      await tester.tap(find.text('장면 만들기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await capture('10-processing');
      for (var i = 0; i < 20; i++) {
        if (find.text('새 장면 읽기').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('새 장면 읽기'), findsOneWidget);
      await tester.pumpAndSettle();
      await capture('11-reveal');
      await tester.ensureVisible(find.text('새 장면 읽기'));
      await tester.tap(find.text('새 장면 읽기'));
      await tester.pumpAndSettle();
      await capture('12-direct-reader');
      await mount(const ReaderScreen(initialSceneId: 'missing'));
      await capture('13-unavailable-reader');
      await mount(const ReaderScreen(), offline: true);
      await capture('14-offline-reader');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      engine.dispose();
      repository.dispose();
    }
  });
}
