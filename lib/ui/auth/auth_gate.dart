import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../data/auth/auth_controller.dart';
import '../../core/env/env.dart';
import '../../domain/model/enums.dart';
import '../../di/providers.dart';
import 'authenticated_consent_gate.dart';
import 'onboarding_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.manuscript});

  final Widget manuscript;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  int? _pendingOnboardingVersion;

  void _signInWithApple(int version) {
    _pendingOnboardingVersion = version;
    ref.read(authControllerProvider).signInWithApple();
  }

  void _signInAnonymously(int version) {
    _pendingOnboardingVersion = version;
    ref.read(authControllerProvider).signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;

    return switch (state.phase) {
      AuthenticationPhase.restoring => const _QuietStatusScreen(
        meta: 'ACCOUNT',
        title: '원고를 여는 중',
      ),
      AuthenticationPhase.signedOut => OnboardingScreen(
        onApplePressed: _signInWithApple,
        onTrialPressed: AppEnv.environment == AppEnvironment.dev
            ? _signInAnonymously
            : null,
      ),
      AuthenticationPhase.signingIn => const _QuietStatusScreen(
        meta: 'ACCOUNT',
        title: '계정을 확인하는 중',
      ),
      AuthenticationPhase.failure => _AuthenticationFailureScreen(
        failure: state.failure ?? AuthenticationFailure.unknown,
        onRetry: controller.retry,
      ),
      AuthenticationPhase.signedIn => AuthenticatedConsentGate(
        pendingOnboardingVersion: _pendingOnboardingVersion,
        child: state.destination == AuthenticationDestination.manuscript
            ? AppEnv.engine == EngineMode.remote
                  ? _CloudBootstrapGate(child: widget.manuscript)
                  : widget.manuscript
            : VolumeSetupScreen(onComplete: controller.completeVolumeSetup),
      ),
    };
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

class VolumeSetupScreen extends ConsumerStatefulWidget {
  const VolumeSetupScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<VolumeSetupScreen> createState() => _VolumeSetupScreenState();
}

class _VolumeSetupScreenState extends ConsumerState<VolumeSetupScreen> {
  AdaptationLevel _adaptation = AdaptationLevel.balanced;
  WritingStyle _style = WritingStyle.plain;
  NarrativeVoice _narrativeVoice = NarrativeVoice.firstPersonPast;
  bool _saving = false;
  bool _failed = false;

  Future<void> _start() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(cloudSyncServiceProvider)
          .createVolume(
            adaptation: _adaptation,
            style: _style,
            narrativeVoice: _narrativeVoice,
          );
      if (mounted) widget.onComplete();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountPage(
      meta: 'VOL. 01 · SHORT',
      title: '첫 원고의\n결을 정합니다.',
      body: '기본값 그대로 바로 시작할 수 있어요.\n설정은 이후 생성분부터 바꿀 수 있습니다.',
      middle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MetaText('ADAPTATION'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChipEditorial(
                label: '꿈에 충실하게',
                selected: _adaptation == AdaptationLevel.faithful,
                onTap: () =>
                    setState(() => _adaptation = AdaptationLevel.faithful),
              ),
              ChoiceChipEditorial(
                label: '균형 있게',
                selected: _adaptation == AdaptationLevel.balanced,
                onTap: () =>
                    setState(() => _adaptation = AdaptationLevel.balanced),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const MetaText('WRITING STYLE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const [
                (WritingStyle.plain, '담백하게'),
                (WritingStyle.lyrical, '서정적으로'),
                (WritingStyle.cinematic, '영화적으로'),
              ])
                ChoiceChipEditorial(
                  label: option.$2,
                  selected: _style == option.$1,
                  onTap: () => setState(() => _style = option.$1),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const MetaText('POINT OF VIEW'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChipEditorial(
                label: '나의 시점',
                selected: _narrativeVoice == NarrativeVoice.firstPersonPast,
                onTap: () => setState(
                  () => _narrativeVoice = NarrativeVoice.firstPersonPast,
                ),
              ),
              ChoiceChipEditorial(
                label: '소설 속 인물 시점',
                selected: _narrativeVoice == NarrativeVoice.thirdPersonPast,
                onTap: () => setState(
                  () => _narrativeVoice = NarrativeVoice.thirdPersonPast,
                ),
              ),
            ],
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed) ...[
            const SizedBox(height: 10),
            const Text(
              '원고를 만들지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          EditorialButton(
            label: _saving ? '원고를 여는 중' : '이 설정으로 시작',
            onPressed: _saving ? null : _start,
          ),
        ],
      ),
    );
  }
}

class _CloudBootstrapGate extends ConsumerStatefulWidget {
  const _CloudBootstrapGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_CloudBootstrapGate> createState() =>
      _CloudBootstrapGateState();
}

class _CloudBootstrapGateState extends ConsumerState<_CloudBootstrapGate> {
  late Future<bool> _loading;

  @override
  void initState() {
    super.initState();
    _loading = ref.read(cloudSyncServiceProvider).bootstrapCurrentAccount();
  }

  void _retry() {
    setState(() {
      _loading = ref.read(cloudSyncServiceProvider).bootstrapCurrentAccount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _QuietStatusScreen(
            meta: 'ACCOUNT',
            title: '원고를 동기화하는 중',
          );
        }
        if (snapshot.hasError || snapshot.data != true) {
          return _AccountPage(
            meta: 'ACCOUNT',
            title: '원고를 불러오지 못했어요.',
            body: '연결을 확인한 뒤 다시 시도해 주세요.',
            footer: EditorialButton(label: '다시 시도', onPressed: _retry),
          );
        }
        return widget.child;
      },
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
    this.middle,
    this.footer,
  });

  final String meta;
  final String title;
  final String? body;
  final Widget? middle;
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
              if (middle != null) ...[const SizedBox(height: 34), middle!],
              const Spacer(flex: 3),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}
