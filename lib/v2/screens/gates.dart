// V2 drawing of the shared authentication, consent, bootstrap and app-lock
// gates. Every access rule stays in lib/ui/auth and lib/ui/settings; this
// file only decides how each state looks.
import 'package:flutter/material.dart';

import '../../data/privacy/app_lock.dart';
import '../../ui/auth/ai_consent.dart';
import '../../ui/auth/auth_presentation.dart';
import '../components/brand.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/orb.dart';
import '../design/atmosphere.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'onboarding.dart';
import 'volume_setup.dart';

class V2AuthPresentation extends AuthPresentation {
  const V2AuthPresentation();

  @override
  Widget loading(String title) => V2WaitPage(title: title);

  @override
  Widget onboarding({
    ValueChanged<int>? onApplePressed,
    ValueChanged<int>? onTrialPressed,
  }) => V2OnboardingScreen(
    onApplePressed: onApplePressed,
    onTrialPressed: onTrialPressed,
  );

  @override
  Widget consent({
    required AiConsentPolicy policy,
    required bool busy,
    required bool failed,
    required ValueChanged<int> onConsentPressed,
  }) => V2OnboardingScreen(
    key: ValueKey(policy.version),
    policy: policy,
    initialPage: 1,
    busy: busy,
    onConsentPressed: onConsentPressed,
    consentError: failed ? '확인 내용을 저장하지 못했어요. 다시 시도해 주세요.' : null,
  );

  @override
  Widget blocked({
    required AuthBlockReason reason,
    required String title,
    String? body,
    required VoidCallback onRetry,
  }) => V2GatePage(
    meta: switch (reason) {
      AuthBlockReason.account => 'ACCOUNT',
      AuthBlockReason.aiNotice => 'AI NOTICE',
    },
    title: title,
    body: body,
    action: V2Button(label: '다시 시도', expand: true, onPressed: onRetry),
  );

  @override
  Widget volumeSetup({required VoidCallback onComplete}) =>
      V2VolumeSetupScreen(onComplete: onComplete);
}

/// A real network wait: the wordmark, what is happening, three still dots.
/// No percentage and no looping loader, because nothing is being measured.
class V2WaitPage extends StatelessWidget {
  const V2WaitPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => V2Page(
    mood: V2Mood.home,
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(V2Space.gutter),
          child: Semantics(
            liveRegion: true,
            label: title,
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const V2Wordmark(size: 22),
                const SizedBox(height: V2Space.xl),
                // V1's Thinking Orb while the app opens or checks access.
                const V2ThinkingOrb(),
                const SizedBox(height: V2Space.lg),
                Text(
                  v2KeepAll(title),
                  textAlign: TextAlign.center,
                  style: V2Type.title,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A closed gate: what happened, why access stays closed, one way forward.
class V2GatePage extends StatelessWidget {
  const V2GatePage({
    super.key,
    required this.meta,
    required this.title,
    required this.action,
    this.body,
  });

  final String meta;
  final String title;
  final String? body;
  final Widget action;

  @override
  Widget build(BuildContext context) => V2Page(
    mood: V2Mood.home,
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                V2Space.gutter,
                V2Space.sm,
                V2Space.gutter,
                V2Space.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - V2Space.sm - V2Space.lg)
                      .clamp(0, double.infinity),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const V2Wordmark(),
                          const Spacer(),
                          // ink2: the label sits on the brightest sky.
                          V2Meta(meta, color: V2Color.ink2),
                        ],
                      ),
                      const Spacer(flex: 4),
                      Semantics(
                        liveRegion: true,
                        header: true,
                        child: Text(v2KeepAll(title), style: V2Type.display),
                      ),
                      if (body case final text?) ...[
                        const SizedBox(height: V2Space.md),
                        Text(
                          v2KeepAll(text),
                          style: V2Type.body.copyWith(color: V2Color.ink2),
                        ),
                      ],
                      const Spacer(flex: 3),
                      const SizedBox(height: V2Space.lg),
                      action,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The app-lock screen. Unlocking is the device's own authentication.
class V2LockedPage extends StatelessWidget {
  const V2LockedPage({super.key, required this.lock});

  final AppLockController lock;

  @override
  Widget build(BuildContext context) => V2GatePage(
    meta: 'LOCKED',
    title: '꿈과 원고가 잠겨 있어요.',
    body: 'Face ID 또는 기기 암호로 열 수 있어요.',
    action: V2Button(
      label: '잠금 해제',
      icon: Icons.lock_open_rounded,
      expand: true,
      loading: lock.authenticating,
      loadingLabel: '확인 중',
      onPressed: lock.authenticating ? null : () => lock.unlock(),
    ),
  );
}
