import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/design/design_system.dart';
import '../../data/auth/auth_controller.dart';
import '../../di/providers.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.manuscript});

  final Widget manuscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;

    return switch (state.phase) {
      AuthenticationPhase.restoring => const _QuietStatusScreen(
        meta: 'ACCOUNT',
        title: '원고를 여는 중',
      ),
      AuthenticationPhase.signedOut => _SignInScreen(
        onPressed: controller.signInWithApple,
      ),
      AuthenticationPhase.signingIn => const _SignInScreen(isBusy: true),
      AuthenticationPhase.failure => _AuthenticationFailureScreen(
        failure: state.failure ?? AuthenticationFailure.unknown,
        onRetry: controller.retry,
      ),
      AuthenticationPhase.signedIn =>
        state.destination == AuthenticationDestination.manuscript
            ? manuscript
            : const VolumeSetupBoundary(),
    };
  }
}

class _SignInScreen extends StatelessWidget {
  const _SignInScreen({this.isBusy = false, this.onPressed});

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _AccountPage(
      meta: 'MUMUMONG',
      title: '꿈을 쓰면,\n원고가 자랍니다.',
      body: '나의 꿈을 기록하고\n하나의 소설로 이어가세요.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SignInWithAppleButton(
            text: isBusy ? 'Apple ID 확인 중' : 'Apple로 계속하기',
            height: 52,
            borderRadius: BorderRadius.zero,
            onPressed: isBusy ? null : onPressed,
          ),
          const SizedBox(height: 14),
          const MetaText('이름과 이메일은 저장하지 않습니다.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AuthenticationFailureScreen extends StatelessWidget {
  const _AuthenticationFailureScreen({
    required this.failure,
    required this.onRetry,
  });

  final AuthenticationFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = switch (failure) {
      AuthenticationFailure.network => (
        title: '연결을 확인해 주세요.',
        body: '네트워크가 돌아오면 다시 시도할 수 있어요.',
      ),
      AuthenticationFailure.expiredSession => (
        title: '세션이 만료되었습니다.',
        body: '원고를 다시 열려면 Apple로 로그인해 주세요.',
      ),
      AuthenticationFailure.unavailable => (
        title: 'Apple 로그인을 사용할 수 없어요.',
        body: '기기의 Apple ID 설정을 확인해 주세요.',
      ),
      AuthenticationFailure.invalidCredential => (
        title: 'Apple ID를 확인하지 못했어요.',
        body: '잠시 후 다시 시도해 주세요.',
      ),
      AuthenticationFailure.unknown => (
        title: '원고를 열지 못했어요.',
        body: '잠시 후 다시 시도해 주세요.',
      ),
    };

    return _AccountPage(
      meta: 'ACCOUNT',
      title: copy.title,
      body: copy.body,
      footer: EditorialButton(label: '다시 시도', onPressed: onRetry),
    );
  }
}

class VolumeSetupBoundary extends StatelessWidget {
  const VolumeSetupBoundary({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccountPage(
      meta: 'VOL. 01',
      title: '첫 원고를\n준비할게요.',
      body: '다음 단계에서 원고의 분량과\n꿈을 이어갈 방식을 정합니다.',
      footer: MetaText('VOLUME SETUP · S02', textAlign: TextAlign.center),
    );
  }
}

class _QuietStatusScreen extends StatelessWidget {
  const _QuietStatusScreen({required this.meta, required this.title});

  final String meta;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _AccountPage(meta: meta, title: title);
  }
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
                  ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
                ),
              ],
              const Spacer(flex: 5),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}
