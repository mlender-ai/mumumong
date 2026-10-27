import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../core/design/thinking_orb.dart';
import '../../core/design/dream_atmosphere.dart';
import '../../data/auth/auth_controller.dart';
import '../../core/env/env.dart';
import '../../domain/model/enums.dart';
import '../../di/providers.dart';
import 'auth_presentation.dart';
import 'authenticated_consent_gate.dart';
import 'auth_loading_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({
    super.key,
    required this.manuscript,
    this.presentation = const V1AuthPresentation(),
  });

  final Widget manuscript;

  /// Draws each gate state. The rules below stay the same for every
  /// presentation.
  final AuthPresentation presentation;

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
    final presentation = widget.presentation;

    return switch (state.phase) {
      AuthenticationPhase.restoring => presentation.loading('원고를 여는 중'),
      AuthenticationPhase.signedOut => presentation.onboarding(
        onApplePressed: kIsWeb ? null : _signInWithApple,
        onTrialPressed: AppEnv.environment != AppEnvironment.prod
            ? _signInAnonymously
            : null,
      ),
      AuthenticationPhase.signingIn => presentation.loading('계정을 확인하는 중'),
      AuthenticationPhase.failure => _failure(
        presentation,
        state.failure ?? AuthenticationFailure.unknown,
        controller.retry,
      ),
      AuthenticationPhase.signedIn => AuthenticatedConsentGate(
        presentation: presentation,
        pendingOnboardingVersion: _pendingOnboardingVersion,
        child: state.destination == AuthenticationDestination.manuscript
            ? AppEnv.engine == EngineMode.remote
                  ? _CloudBootstrapGate(
                      presentation: presentation,
                      child: widget.manuscript,
                    )
                  : widget.manuscript
            : presentation.volumeSetup(
                onComplete: controller.completeVolumeSetup,
              ),
      ),
    };
  }
}

Widget _failure(
  AuthPresentation presentation,
  AuthenticationFailure failure,
  VoidCallback onRetry,
) {
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
  return presentation.blocked(
    reason: AuthBlockReason.account,
    title: copy.title,
    body: copy.body,
    onRetry: onRetry,
  );
}

class VolumeSetupScreen extends ConsumerStatefulWidget {
  const VolumeSetupScreen({
    super.key,
    required this.onComplete,
    this.createVolume,
  });

  final VoidCallback onComplete;

  /// Optional local walkthrough/test adapter. AuthGate leaves this null and
  /// always uses the existing authenticated CloudSyncService.
  final Future<void> Function({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    required NarrativeVoice narrativeVoice,
  })?
  createVolume;

  @override
  ConsumerState<VolumeSetupScreen> createState() => _VolumeSetupScreenState();
}

class _VolumeSetupScreenState extends ConsumerState<VolumeSetupScreen> {
  AdaptationLevel _adaptation = AdaptationLevel.balanced;
  WritingStyle _style = WritingStyle.plain;
  NarrativeVoice _narrativeVoice = NarrativeVoice.firstPersonPast;
  bool _saving = false;
  bool _failed = false;
  bool _details = false;

  Future<void> _start() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final create =
          widget.createVolume ??
          ref.read(cloudSyncServiceProvider).createVolume;
      await create(
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
    if (_saving) {
      return const AuthLoadingScreen(
        title: '첫 원고를 준비하는 중',
        orbState: DreamOrbState.composing,
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: DreamAtmosphere(
              animate: false,
              night: context.isNight,
              strength: .25,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MongFlowPage(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '첫 이야기를\n시작해 볼까요?',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '기억나는 장면 하나면 충분해요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.secondaryInk,
                        ),
                      ),
                      if (_details) ...[
                        const SizedBox(height: 24),
                        _choiceSection('꿈과 이야기의 거리', [
                          ChoiceChipEditorial(
                            label: '꿈에 충실하게',
                            selected: _adaptation == AdaptationLevel.faithful,
                            onTap: () => setState(
                              () => _adaptation = AdaptationLevel.faithful,
                            ),
                          ),
                          ChoiceChipEditorial(
                            label: '균형 있게',
                            selected: _adaptation == AdaptationLevel.balanced,
                            onTap: () => setState(
                              () => _adaptation = AdaptationLevel.balanced,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 28),
                        _choiceSection('문장의 느낌', [
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
                        ]),
                        const SizedBox(height: 28),
                        _choiceSection('이야기의 시점', [
                          ChoiceChipEditorial(
                            label: '나의 시점',
                            selected:
                                _narrativeVoice ==
                                NarrativeVoice.firstPersonPast,
                            onTap: () => setState(
                              () => _narrativeVoice =
                                  NarrativeVoice.firstPersonPast,
                            ),
                          ),
                          ChoiceChipEditorial(
                            label: '소설 속 인물 시점',
                            selected:
                                _narrativeVoice ==
                                NarrativeVoice.thirdPersonPast,
                            onTap: () => setState(
                              () => _narrativeVoice =
                                  NarrativeVoice.thirdPersonPast,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                  actions: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_failed) ...[
                        Text(
                          '원고를 만들지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      MongActionGroup(
                        primary: GlassActionButton(
                          label: '시작하기',
                          onPressed: _start,
                        ),
                        secondary: [
                          MongButton.ghost(
                            label: _details ? '이야기 설정 접기' : '이야기 설정',
                            onPressed: () =>
                                setState(() => _details = !_details),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceSection(String title, List<Widget> choices) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: choices),
    ],
  );
}

class _CloudBootstrapGate extends ConsumerStatefulWidget {
  const _CloudBootstrapGate({required this.presentation, required this.child});

  final AuthPresentation presentation;
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
          return widget.presentation.loading('원고를 불러오는 중');
        }
        if (snapshot.hasError || snapshot.data != true) {
          return widget.presentation.blocked(
            reason: AuthBlockReason.account,
            title: '원고를 불러오지 못했어요.',
            body: '연결을 확인한 뒤 다시 시도해 주세요.',
            onRetry: _retry,
          );
        }
        return widget.child;
      },
    );
  }
}
