// Local design walkthrough. No authentication, cloud calls, or real consent.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/settings/settings_components.dart';
import 'package:mumumong/ui/settings/appearance_screen.dart';
import 'package:mumumong/ui/settings/generation_settings_screen.dart';
import 'package:mumumong/ui/auth/onboarding_screen.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'orb_motion_review.dart';

void main() => runApp(const VisualPreviewApp());

class VisualPreviewApp extends StatefulWidget {
  const VisualPreviewApp({
    super.key,
    this.stageDelay = const Duration(seconds: 4),
  });
  final Duration stageDelay;

  @override
  State<VisualPreviewApp> createState() => _VisualPreviewAppState();
}

class _VisualPreviewAppState extends State<VisualPreviewApp> {
  late MemoryRepository _repository = MemoryRepository(seedPrototype: false);
  late MockEngineClient _engine = MockEngineClient(
    store: _repository,
    stageDelay: widget.stageDelay,
  );
  final _speech = _PreviewSpeechInput();
  int _step = 0;
  Key _session = UniqueKey();

  void _restart() {
    final oldEngine = _engine;
    final oldRepository = _repository;
    setState(() {
      _step = 0;
      _repository = MemoryRepository(seedPrototype: false);
      _engine = MockEngineClient(
        store: _repository,
        stageDelay: widget.stageDelay,
      );
      _session = UniqueKey();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldEngine.dispose();
      oldRepository.dispose();
    });
  }

  void _motion(BuildContext context) =>
      Navigator.of(context).push(quietPageRoute(const OrbMotionReview()));

  @override
  void dispose() {
    _engine.dispose();
    _speech.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _session,
      overrides: [
        repositoryProvider.overrideWithValue(_repository),
        engineClientProvider.overrideWithValue(_engine),
        speechInputProvider.overrideWithValue(_speech),
        outboxWorkerProvider.overrideWithValue(null),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          title: '무무몽 · 인터랙션 미리보기',
          debugShowCheckedModeBanner: false,
          theme: mumumongTheme(),
          darkTheme: dreamNightTheme(),
          themeMode: ref.watch(uiPreferencesProvider).themeMode,
          home: Builder(
            builder: (context) => switch (_step) {
              0 => OnboardingScreen(
                policy: const AiConsentPolicy(
                  version: 1,
                  message:
                      '디자인 검토용 가상 동의입니다. 실제 계정·AI 요청·서버 동의 기록은 만들지 않아요. 입력과 결과는 메모리에만 있고 새로고침하면 초기화돼요. 결과 본문은 입력과 무관한 고정 예시입니다.',
                  providers: [],
                ),
                entryActionLabel: '시작하기',
                consentActionLabel: '확인하고 계속',
                entryCaption: '디자인 검토 · 실제 로그인이나 AI 호출은 없어요',
                onMotionPreview: () => _motion(context),
                onConsentPressed: (_) => setState(() => _step = 1),
                headerAction: IconButton(
                  tooltip: '온보딩 처음부터 보기',
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  onPressed: _restart,
                ),
              ),
              1 => VolumeSetupScreen(
                createVolume: _repository.createPreviewVolume,
                onComplete: () => setState(() => _step = 2),
              ),
              _ => MumumongShell(
                settingsPage: _PreviewSettings(
                  onRestart: _restart,
                  onMotion: () => _motion(context),
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewSpeechInput implements SpeechInput {
  final _updates = StreamController<SpeechUpdate>.broadcast();

  @override
  Stream<SpeechUpdate> get updates => _updates.stream;

  @override
  Future<void> start() async {
    _updates.add(
      const SpeechUpdate(
        text: '꿈속에서 푸른 문을 열었어요. 문 너머에는 작은 정원이 있었어요.',
        rms: .55,
      ),
    );
  }

  @override
  Future<void> stop() async => _updates.add(const SpeechUpdate(stopped: true));

  void dispose() => _updates.close();
}

class _PreviewSettings extends StatefulWidget {
  const _PreviewSettings({required this.onRestart, required this.onMotion});
  final VoidCallback onRestart;
  final VoidCallback onMotion;

  @override
  State<_PreviewSettings> createState() => _PreviewSettingsState();
}

class _PreviewSettingsState extends State<_PreviewSettings> {
  bool _lock = false;
  SettingsDestination? _destination;

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    if (destination == null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.onRestart,
                  child: const Text('온보딩 다시 보기'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onMotion,
                  child: const Text('Orb 모션 보기'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SettingsOverview(
              onOpen: (value) {
                if (value == SettingsDestination.appearance ||
                    value == SettingsDestination.generation) {
                  Navigator.of(context).push(
                    quietPageRoute(
                      value == SettingsDestination.generation
                          ? const GenerationSettingsScreen()
                          : const AppearanceScreen(),
                    ),
                  );
                } else {
                  setState(() => _destination = value);
                }
              },
            ),
          ),
        ],
      );
    }
    final child = switch (destination) {
      SettingsDestination.appearance => const SizedBox.shrink(),
      SettingsDestination.generation => const SizedBox.shrink(),
      SettingsDestination.library => const Center(
        child: Text('완성본과 PDF는 실제 저장소를 사용하는 앱에서 확인해 주세요. 이 미리보기는 고정 예시예요.'),
      ),
      SettingsDestination.data => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          const _PreviewInfo(
            title: '기록은 내 것이에요',
            body: '꿈 · 원고 · 출처 · 작성 중인 초안을 관리할 수 있어요.',
          ),
          const SizedBox(height: 20),
          SettingsNavigationRow(
            title: '내 기록 내보내기',
            subtitle: '파일을 저장하거나 다른 앱으로 공유',
            onTap: () => _notice('목업에서는 파일을 내보내지 않아요.'),
          ),
          SettingsNavigationRow(
            title: '모든 기록 삭제',
            subtitle: '미리보기에서는 실제로 삭제되지 않아요',
            destructive: true,
            onTap: () => _notice('목업 데이터는 새로고침하면 초기화됩니다.'),
          ),
        ],
      ),
      SettingsDestination.security => ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          _PreviewInfo(
            title: _lock ? '잠금이 켜져 있어요' : '잠금이 꺼져 있어요',
            body: 'Face ID 또는 기기 암호로 앱을 열어요. 이 전환은 디자인 미리보기 전용입니다.',
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            title: const Text('앱 잠금 사용'),
            subtitle: const Text('미리보기 전용 전환'),
            value: _lock,
            onChanged: (value) => setState(() => _lock = value),
          ),
        ],
      ),
      SettingsDestination.aiProcessing => ListView(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          _PreviewInfo(
            title: 'AI 처리 고지',
            body:
                '실제 AI 호출이나 동의 기록 없이 화면 흐름만 체험합니다. 공급사와 전송 내용은 앱에서 확인할 수 있어요.',
          ),
        ],
      ),
      SettingsDestination.voiceInput => ListView(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 32),
        children: [
          _PreviewInfo(
            title: '음성은 기기 안에서만',
            body:
                '목업 음성 입력은 예시 문장을 넣으며 마이크를 사용하지 않아요. 실제 음성 기능은 기기 지원 범위에서 동작해요.',
          ),
        ],
      ),
    };
    final title = switch (destination) {
      SettingsDestination.appearance => '화면과 읽기',
      SettingsDestination.generation => '이후 장면 설정',
      SettingsDestination.library => '내가 완성한 책',
      SettingsDestination.data => '기록 관리',
      SettingsDestination.security => '앱 잠금',
      SettingsDestination.aiProcessing => 'AI 처리 고지',
      SettingsDestination.voiceInput => '음성 기록',
    };
    return SettingsDetailFrame(
      title: title,
      description: '디자인 검토용 목업 · 실제 계정이나 저장 데이터는 바뀌지 않아요.',
      onBack: () => setState(() => _destination = null),
      child: child,
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  const _PreviewInfo({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.subtle,
      borderRadius: BorderRadius.circular(MongRadius.field),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
