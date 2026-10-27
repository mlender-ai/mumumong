import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';
import 'ai_consent.dart';
import 'auth_gate.dart' show VolumeSetupScreen;
import 'auth_loading_screen.dart';
import 'onboarding_screen.dart';

/// Why a gate stays closed until the user retries.
enum AuthBlockReason {
  /// Sign-in, session or account bootstrap failed.
  account,

  /// The AI processing notice or the consent record could not be read.
  aiNotice,
}

/// Draws the authentication, consent and first-volume gates.
///
/// The gates own every rule: which phase shows what, when a consent record
/// counts, when a bootstrap retries. A presentation only draws, so the V1 and
/// V2 interfaces share one gate and cannot drift apart on access decisions.
abstract class AuthPresentation {
  const AuthPresentation();

  /// A real network wait, never a simulated step or progress percentage.
  Widget loading(String title);

  /// Signed out: the introduction and the checks that come before sign-in.
  Widget onboarding({
    ValueChanged<int>? onApplePressed,
    ValueChanged<int>? onTrialPressed,
  });

  /// Signed in without a consent record for the current [policy].
  /// [failed] is true when the last acceptance was not recorded.
  Widget consent({
    required AiConsentPolicy policy,
    required bool busy,
    required bool failed,
    required ValueChanged<int> onConsentPressed,
  });

  /// Access stays closed until [onRetry] succeeds.
  Widget blocked({
    required AuthBlockReason reason,
    required String title,
    String? body,
    required VoidCallback onRetry,
  });

  /// A signed-in account that has no volume yet.
  Widget volumeSetup({required VoidCallback onComplete});
}

/// The current shipped interface.
class V1AuthPresentation extends AuthPresentation {
  const V1AuthPresentation();

  @override
  Widget loading(String title) => AuthLoadingScreen(title: title);

  @override
  Widget onboarding({
    ValueChanged<int>? onApplePressed,
    ValueChanged<int>? onTrialPressed,
  }) => OnboardingScreen(
    onApplePressed: onApplePressed,
    onTrialPressed: onTrialPressed,
  );

  @override
  Widget consent({
    required AiConsentPolicy policy,
    required bool busy,
    required bool failed,
    required ValueChanged<int> onConsentPressed,
  }) => Stack(
    children: [
      OnboardingScreen(
        key: ValueKey(policy.version),
        policy: policy,
        initialPage: 1,
        busy: busy,
        onConsentPressed: onConsentPressed,
      ),
      if (failed)
        Positioned(
          left: 20,
          right: 20,
          bottom: 4,
          child: Builder(
            builder: (context) => Material(
              color: context.canvas,
              child: const Text(
                '확인 내용을 저장하지 못했어요. 다시 시도해 주세요.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
    ],
  );

  @override
  Widget blocked({
    required AuthBlockReason reason,
    required String title,
    String? body,
    required VoidCallback onRetry,
  }) {
    final retry = EditorialButton(label: '다시 시도', onPressed: onRetry);
    return switch (reason) {
      AuthBlockReason.account => _AccountPage(
        meta: 'ACCOUNT',
        title: title,
        body: body,
        footer: retry,
      ),
      AuthBlockReason.aiNotice => _GateMessage(
        title: title,
        detail: body,
        action: retry,
      ),
    };
  }

  @override
  Widget volumeSetup({required VoidCallback onComplete}) =>
      VolumeSetupScreen(onComplete: onComplete);
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.meta,
    required this.title,
    this.body,
    this.footer,
  });

  final String meta;
  final String title;
  final String? body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetaText(meta),
              const Spacer(flex: 4),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              if (body != null) ...[
                const SizedBox(height: 20),
                Text(
                  body!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
                ),
              ],
              const Spacer(flex: 3),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({required this.title, this.detail, this.action});

  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MetaText('AI NOTICE'),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              if (detail != null) ...[
                const SizedBox(height: 16),
                Text(detail!),
              ],
              const Spacer(),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
