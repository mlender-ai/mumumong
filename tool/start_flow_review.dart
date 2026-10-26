// Local presentation QA only. Never deployed by deploy_live_trial.sh.
// No account, consent submission, storage, audio or AI requests.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/thinking_orb.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/auth/auth_loading_screen.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';

void main() {
  final query = Uri.base.queryParameters;
  runApp(
    ProviderScope(
      child: MaterialApp(
        title: '무무몽 · 로컬 화면 검토',
        debugShowCheckedModeBanner: false,
        theme: query['night'] == 'true' ? dreamNightTheme() : mumumongTheme(),
        home: switch (query['screen']) {
          'setup' => VolumeSetupScreen(
            onComplete: () {},
            createVolume:
                ({
                  required adaptation,
                  required style,
                  required narrativeVoice,
                }) async {},
          ),
          'loading' => const _WaitReview(),
          _ => OnboardingScreen(
            initialPage: query['screen'] == 'consent' ? 1 : 0,
            policy: AiConsentPolicy(
              version: 1,
              message:
                  '로컬 QA용 안내입니다. 실제 동의나 계정은 만들지 않아요. 실제 앱의 전체 AI 처리 고지는 서버 정책에서 불러옵니다.',
              providers: [
                AiProviderDisclosure(
                  id: 'groq',
                  name: 'Groq',
                  termsUrl: Uri.parse(
                    'https://console.groq.com/docs/legal/services-agreement',
                  ),
                  dataUrl: Uri.parse('https://console.groq.com/docs/your-data'),
                ),
              ],
            ),
            onTrialPressed: (_) {},
          ),
        },
      ),
    ),
  );
}

class _WaitReview extends StatefulWidget {
  const _WaitReview();
  @override
  State<_WaitReview> createState() => _WaitReviewState();
}

class _WaitReviewState extends State<_WaitReview> {
  int _phase = 0;
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) =>
          setState(() => _phase = (_phase + 1) % DreamOrbState.values.length),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthLoadingScreen(
    title: '시작할 준비를 하고 있어요',
    orbState: DreamOrbState.values[_phase],
  );
}
