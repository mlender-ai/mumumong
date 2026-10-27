// V2 PREVIEW. Everything below runs on the device only:
//  - data: MemoryRepository with fictional seed dreams (or empty)
//  - AI: MockEngineClient with a fixed fictional scene, chosen outcome
//  - consent: a local preview policy that is never submitted
//  - voice: a scripted fictional voice, or the device recognizer
//  - preferences, app lock and database: in-memory
// No account, server, production AI or user data is used.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../data/engine/mock_engine_client.dart';
import '../../data/memory/memory_repository.dart';
import '../../data/privacy/app_lock.dart';
import '../../di/providers.dart';
import '../../ui/auth/ai_consent.dart';
import '../../ui/settings/record_actions.dart';
import '../app.dart';
import '../components/brand.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../design/atmosphere.dart';
import '../design/dot_matrix.dart';
import '../design/press.dart';
import '../design/surface.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../screens/format.dart';
import '../screens/onboarding.dart';
import '../screens/v2_providers.dart';
import '../screens/volume_setup.dart';
import 'design_lab.dart';
import 'preview_consent.dart';
import 'preview_database.dart';
import 'preview_speech.dart';
import 'preview_stores.dart';

enum PreviewStart { fresh, continued }

enum PreviewVoice { scripted, device }

@immutable
class PreviewConfig {
  const PreviewConfig({
    required this.start,
    this.engine = MockEngineCase.success,
    this.voice = PreviewVoice.scripted,
    this.stageDelay = const Duration(seconds: 2),
  });

  final PreviewStart start;
  final MockEngineCase engine;
  final PreviewVoice voice;
  final Duration stageDelay;
}

/// Overrides that isolate a preview session. Also used by tests.
List<Override> previewOverrides(
  PreviewConfig config,
  MemoryRepository repository,
) => [
  v2PreviewProvider.overrideWithValue(true),
  repositoryProvider.overrideWithValue(repository),
  engineClientProvider.overrideWith((ref) {
    final client = MockEngineClient(
      store: repository,
      scenario: config.engine,
      stageDelay: config.stageDelay,
    );
    ref.onDispose(client.dispose);
    return client;
  }),
  outboxWorkerProvider.overrideWithValue(null),
  networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
  uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
  appLockProvider.overrideWith(
    (ref) => AppLockController(
      MemorySecureValueStore(),
      const PreviewAuthenticator(),
    ),
  ),
  recordActionsProvider.overrideWithValue(const PreviewRecordActions()),
  aiConsentRepositoryProvider.overrideWithValue(
    const PreviewAiConsentRepository(),
  ),
  databaseProvider.overrideWith((ref) {
    final database = previewDatabase();
    ref.onDispose(database.close);
    return database;
  }),
  v2CreateVolumeProvider.overrideWithValue(repository.createPreviewVolume),
  if (config.voice == PreviewVoice.scripted) ...[
    speechInputProvider.overrideWithValue(PreviewSpeechInput()),
    v2VoiceNoteProvider.overrideWithValue('미리보기 음성 · 마이크 없이 가상 꿈을 입력해요'),
  ],
];

class V2PreviewRoot extends StatefulWidget {
  const V2PreviewRoot({super.key});

  @override
  State<V2PreviewRoot> createState() => _V2PreviewRootState();
}

class _V2PreviewRootState extends State<V2PreviewRoot> {
  PreviewConfig? _config;
  int _session = 0;

  void _start(PreviewConfig config) => setState(() {
    _config = config;
    _session++;
  });

  void _exit() => setState(() => _config = null);

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) {
      return MumumongV2App(
        overlay: const _PreviewMarker(),
        home: _Launcher(onStart: _start),
      );
    }
    return V2PreviewSession(
      key: ValueKey(_session),
      config: config,
      onExit: _exit,
    );
  }
}

class V2PreviewSession extends StatefulWidget {
  const V2PreviewSession({
    super.key,
    required this.config,
    required this.onExit,
  });

  final PreviewConfig config;
  final VoidCallback onExit;

  @override
  State<V2PreviewSession> createState() => _V2PreviewSessionState();
}

class _V2PreviewSessionState extends State<V2PreviewSession> {
  late final MemoryRepository _repository = MemoryRepository(
    seedPrototype: widget.config.start == PreviewStart.continued,
  );

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restart = _RestartRow(onExit: widget.onExit);
    return ProviderScope(
      overrides: previewOverrides(widget.config, _repository),
      child: MumumongV2App(
        overlay: const _PreviewMarker(),
        home: widget.config.start == PreviewStart.fresh
            ? _FreshFlow(extraSettings: restart)
            : V2Shell(extraSettings: restart),
      ),
    );
  }
}

class _FreshFlow extends StatefulWidget {
  const _FreshFlow({required this.extraSettings});

  final Widget extraSettings;

  @override
  State<_FreshFlow> createState() => _FreshFlowState();
}

class _FreshFlowState extends State<_FreshFlow> {
  int _stage = 0;

  @override
  Widget build(BuildContext context) {
    final child = switch (_stage) {
      0 => V2OnboardingScreen(
        key: const ValueKey('onboarding'),
        entryActionLabel: '시작하기',
        entryCaption: '미리보기 · 계정 없이 이 기기 안에서만 동작해요',
        consentActionLabel: '동의하고 계속',
        consentNote: '미리보기는 동의를 저장하거나 어디에도 보내지 않아요.',
        onConsentPressed: (_) => setState(() => _stage = 1),
      ),
      1 => V2VolumeSetupScreen(
        key: const ValueKey('setup'),
        onComplete: () => setState(() => _stage = 2),
      ),
      _ => V2Shell(
        key: const ValueKey('shell'),
        extraSettings: widget.extraSettings,
      ),
    };
    return AnimatedSwitcher(
      duration: V2Motion.of(context, V2Motion.page),
      switchInCurve: V2Motion.settle,
      child: child,
    );
  }
}

class _RestartRow extends StatelessWidget {
  const _RestartRow({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => V2Button.glass(
    label: '미리보기 처음으로',
    icon: Icons.restart_alt_rounded,
    expand: true,
    onPressed: () {
      Navigator.of(context).popUntil((route) => route.isFirst);
      onExit();
    },
  );
}

/// A small, always-visible marker so every capture says it is a preview.
class _PreviewMarker extends StatelessWidget {
  const _PreviewMarker();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          bottom: bottom > 20 ? bottom - 22 : 4,
        ),
        child: Semantics(
          label: '미리보기, 가짜 데이터',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: V2Color.sky500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              V2DotMatrix(
                'PREVIEW',
                pitch: 1.15,
                color: V2Color.ink3.withValues(alpha: .8),
                semanticsLabel: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Launcher extends StatefulWidget {
  const _Launcher({required this.onStart});

  final ValueChanged<PreviewConfig> onStart;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  MockEngineCase _engine = MockEngineCase.success;
  PreviewVoice _voice = PreviewVoice.scripted;

  PreviewConfig _config(PreviewStart start) =>
      PreviewConfig(start: start, engine: _engine, voice: _voice);

  @override
  Widget build(BuildContext context) {
    return V2Page(
      mood: V2Mood.intro,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                V2Space.gutter,
                V2Space.md,
                V2Space.gutter,
                V2Space.xl,
              ),
              children: [
                Row(
                  children: [
                    const V2Wordmark(animate: true),
                    const Spacer(),
                    V2DotMatrix(
                      'V2',
                      pitch: 2.4,
                      color: V2Color.ink2,
                      semanticsLabel: '버전 2',
                    ),
                  ],
                ),
                const SizedBox(height: V2Space.xxl),
                Semantics(
                  header: true,
                  child: const Text(
                    '새 무무몽을\n직접 눌러 보세요',
                    style: V2Type.displayXL,
                  ),
                ),
                const SizedBox(height: V2Space.sm),
                Text(
                  v2KeepAll(
                    '이 미리보기는 기기 안에서만 동작해요. 가상의 꿈과 가짜 AI 엔진을 쓰고, 계정·서버·실제 AI를 쓰지 않아요.',
                  ),
                  style: V2Type.body,
                ),
                const SizedBox(height: V2Space.xl),
                _Entry(
                  title: '처음 시작하기',
                  body: '브랜드 소개 → 동의 → 첫 원고 → 첫 꿈 기록',
                  index: '01',
                  onTap: () => widget.onStart(_config(PreviewStart.fresh)),
                ),
                const SizedBox(height: V2Space.sm),
                _Entry(
                  title: '이어 쓰기',
                  body: '가상 원고 42% · 장면 11개에서 꿈을 더해 성장 보기',
                  index: '02',
                  onTap: () => widget.onStart(_config(PreviewStart.continued)),
                ),
                const SizedBox(height: V2Space.sm),
                _Entry(
                  title: '디자인 랩',
                  body: '버튼·글라스·도트·모션을 하나씩 만져 보기',
                  index: '03',
                  onTap: () =>
                      Navigator.of(context).push(v2Route(const V2DesignLab())),
                ),
                const SizedBox(height: V2Space.xl),
                const V2Meta('가짜 AI 엔진의 결과'),
                const SizedBox(height: V2Space.xs),
                V2Segmented<MockEngineCase>(
                  segments: const [
                    (MockEngineCase.success, '성공'),
                    (MockEngineCase.retry, '재시도'),
                    (MockEngineCase.fallback, '대체'),
                    (MockEngineCase.fail, '실패'),
                  ],
                  value: _engine,
                  onChanged: (value) => setState(() => _engine = value),
                ),
                const SizedBox(height: V2Space.md),
                const V2Meta('음성 입력'),
                const SizedBox(height: V2Space.xs),
                V2Segmented<PreviewVoice>(
                  segments: const [
                    (PreviewVoice.scripted, '미리보기 음성'),
                    (PreviewVoice.device, '기기 음성 인식'),
                  ],
                  value: _voice,
                  onChanged: (value) => setState(() => _voice = value),
                ),
                const SizedBox(height: V2Space.xs),
                const V2Meta('미리보기 음성은 마이크를 쓰지 않고, 새로 지은 가상 꿈을 말하듯 입력해요.'),
                const SizedBox(height: V2Space.xl),
                const V2Notice(
                  icon: Icons.science_outlined,
                  message:
                      '실제 연결: 저장소·Provider·기록 흐름·생성 상태·공개 영수증·리더 위치·문장 수정은 실제 앱 코드 그대로예요.\n'
                      '가짜: 데이터(메모리 저장소), AI 엔진(고정 장면), 동의(제출 없음), 미리보기 음성.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    required this.body,
    required this.index,
    required this.onTap,
  });

  final String title;
  final String body;
  final String index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => V2Pressable(
    onPressed: onTap,
    haptic: V2Haptic.light,
    semanticLabel: '$title. $body',
    builder: (context, state) => Transform.scale(
      scale: V2Motion.reduced(context) ? 1 : 1 - .015 * state.depth,
      child: V2Surface(
        kind: V2SurfaceKind.elevated,
        radius: V2Radius.card,
        chroma: .3 + state.hover * .2,
        sink: state.sink,
        hover: state.hover,
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        child: Row(
          children: [
            V2DotMatrix(index, pitch: 3, color: V2Color.sky600),
            const SizedBox(width: V2Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: V2Type.title.copyWith(fontSize: 21)),
                  const SizedBox(height: 2),
                  Text(v2KeepAll(body), style: V2Type.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: V2Color.ink2,
            ),
          ],
        ),
      ),
    ),
  );
}
