import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';

void main() {
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

  testWidgets('entry and consent retain the mobile glass composition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final policy = AiConsentPolicy(
      version: 1,
      message: '꿈 내용은 원고 생성을 위해 AI 제공사로 전송됩니다.',
      providers: [
        AiProviderDisclosure(id: 'groq', name: 'Groq', termsUrl: _groqTerms),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: mumumongTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const Key('visual-capture'),
            child: OnboardingScreen(policy: policy, onApplePressed: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('visual-capture')),
      matchesGoldenFile(
        '../../docs/ux-review/2026-10-26-visual-recovery/goldens/entry.png',
      ),
    );

    await tester.tap(find.text('Apple로 시작하기'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('visual-capture')),
      matchesGoldenFile(
        '../../docs/ux-review/2026-10-26-visual-recovery/goldens/consent.png',
      ),
    );
  });
}

final _groqTerms = Uri.parse(
  'https://console.groq.com/docs/legal/services-agreement',
);
