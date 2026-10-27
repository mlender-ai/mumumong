// DESIGN LAB (preview only). Every control here is a real V2 component; the
// states are driven by buttons instead of the engine so each interaction
// can be inspected on its own. Nothing here touches data.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/privacy/app_lock.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../components/progress.dart';
import '../design/atmosphere.dart';
import '../design/dot_matrix.dart';
import '../design/halftone.dart';
import '../design/memory_swarm.dart';
import '../design/surface.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../screens/gates.dart';
import 'preview_stores.dart';

class V2DesignLab extends StatefulWidget {
  const V2DesignLab({super.key});

  @override
  State<V2DesignLab> createState() => _V2DesignLabState();
}

class _V2DesignLabState extends State<V2DesignLab>
    with TickerProviderStateMixin {
  V2Mood _mood = V2Mood.home;
  bool _disabled = false;
  bool _loading = false;
  bool _recording = false;
  int _presses = 0;
  final _level = ValueNotifier<double>(0);
  Timer? _levelTimer;

  // Halftone
  V2Motif _motif = V2Motif.door;
  double _progress = .42;
  double? _growFrom;
  int _growthKey = 0;

  // Swarm
  late final MemorySwarm _swarm = MemorySwarm(vsync: this);
  int _swarmStep = 0;
  int _chars = 0;
  late final TextEditingController _field = TextEditingController()
    ..addListener(() {
      if (_field.text.length != _chars && _swarmStep == 0) {
        setState(() => _chars = _field.text.length);
      }
    });
  final _focus = FocusNode();

  static const _steps = ['입력', '저장', '읽기', '연결', '쓰기', '확인', '공개'];

  @override
  void dispose() {
    _levelTimer?.cancel();
    _level.dispose();
    _swarm.dispose();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() => _recording = !_recording);
    _levelTimer?.cancel();
    if (_recording) {
      var tick = 0;
      // DESIGN MOCK: a synthetic voice level for the ring.
      _levelTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        tick++;
        _level.value = tick % 6 == 0
            ? .1
            : (.45 + .4 * math.sin(tick * 1.7).abs());
      });
    } else {
      _level.value = 0;
    }
  }

  void _grow(double amount) {
    setState(() {
      _growFrom = _progress;
      _progress = (_progress + amount).clamp(0.0, 1.0);
      _growthKey++;
    });
  }

  void _formSwarm(Size size) {
    final center = Offset(size.width / 2, size.height * .45);
    final rect = Rect.fromLTWH(
      28,
      size.height * .18,
      size.width - 56,
      size.height * .64,
    );
    final formation = switch (_swarmStep) {
      0 => SwarmFormation.field(
        count: MemorySwarm.dotsForText(_chars),
        center: center,
      ),
      1 => SwarmFormation.fragment(center: center),
      2 => SwarmFormation.clusters(center: center),
      3 => SwarmFormation.linked(center: center),
      4 => SwarmFormation.rows(rect: rect, lineHeight: 26, titleGap: 46),
      5 => SwarmFormation.page(rect: rect, lineHeight: 26, titleGap: 46),
      _ => SwarmFormation.dissolve(rect: rect, lineHeight: 26, titleGap: 46),
    };
    _swarm.form(
      formation,
      duration: _swarmStep == 6 ? V2Motion.reveal : V2Motion.stage,
      stagger: _swarmStep == 6 ? .7 : .35,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Color.paper,
      body: V2Atmosphere(
        mood: _mood,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              V2ContextHeader(
                leading: V2IconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: '돌아가기',
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('디자인 랩', style: V2Type.headline),
                    V2Meta('DESIGN MOCK · 데이터와 연결되지 않은 시연'),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    V2Space.gutter,
                    V2Space.sm,
                    V2Space.gutter,
                    96,
                  ),
                  children: [
                    _section(
                      '01',
                      '버튼 · 하나의 물리',
                      '누르면 표면이 가라앉고 빛이 내려가요. 놓으면 살짝 튀어 올라 돌아와요. 모든 버튼이 같은 스프링과 햅틱을 써요.',
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        V2Button(
                          label: '꿈 저장하기',
                          loading: _loading,
                          loadingLabel: '저장하는 중',
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2Button.secondary(
                          label: '이어 읽기',
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2Button.glass(
                          label: '기억 보강하기',
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2Button.floating(
                          label: '꿈 기록',
                          icon: Icons.edit_outlined,
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2IconButton(
                          icon: Icons.close_rounded,
                          semanticLabel: '글라스 아이콘',
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2IconButton(
                          icon: Icons.tune_rounded,
                          semanticLabel: '잉크 아이콘',
                          variant: V2IconButtonVariant.ink,
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                        V2RecordButton(
                          recording: _recording,
                          level: _level,
                          onPressed: _disabled ? null : _toggleRecording,
                        ),
                        V2TextAction(
                          label: '나중에 만들기',
                          onPressed: _disabled
                              ? null
                              : () => setState(() => _presses++),
                        ),
                      ],
                    ),
                    const SizedBox(height: V2Space.md),
                    Row(
                      children: [
                        V2ChoiceChip(
                          label: '비활성',
                          selected: _disabled,
                          onSelected: () =>
                              setState(() => _disabled = !_disabled),
                        ),
                        const SizedBox(width: 8),
                        V2ChoiceChip(
                          label: '로딩',
                          selected: _loading,
                          onSelected: () =>
                              setState(() => _loading = !_loading),
                        ),
                        const Spacer(),
                        const V2Meta('누른 횟수 '),
                        V2DotMatrix(
                          '$_presses',
                          pitch: 2.4,
                          color: V2Color.sky600,
                        ),
                      ],
                    ),
                    _section(
                      '02',
                      '표면',
                      '같은 빛과 테두리를 쓰는 다섯 재질. 유리는 뒤의 하늘을 흐리게 비춰요.',
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(V2Radius.card),
                      child: SizedBox(
                        height: 200,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              V2Atmosphere.skyAsset,
                              fit: BoxFit.cover,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  for (final (kind, label) in const [
                                    (V2SurfaceKind.paper, '종이'),
                                    (V2SurfaceKind.atmospheric, '대기'),
                                    (V2SurfaceKind.frosted, '서리\n유리'),
                                    (V2SurfaceKind.elevated, '띄운\n유리'),
                                    (V2SurfaceKind.floating, '플로팅'),
                                  ]) ...[
                                    Expanded(
                                      child: V2Surface(
                                        kind: kind,
                                        radius: 20,
                                        chroma: kind == V2SurfaceKind.frosted
                                            ? .5
                                            : 0,
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: Text(
                                            label,
                                            textAlign: TextAlign.center,
                                            style: V2Type.meta.copyWith(
                                              color: V2Color.ink,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (kind != V2SurfaceKind.floating)
                                      const SizedBox(width: 6),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _section(
                      '03',
                      '입력에 반응하는 도트',
                      '적은 만큼 도트가 생기고, 녹음하면 목소리에 맞춰 퍼져요. 단계를 눌러 기록→저장→처리→공개를 하나씩 보세요.',
                    ),
                    SizedBox(
                      height: 300,
                      child: V2Surface(
                        kind: V2SurfaceKind.frosted,
                        radius: V2Radius.card,
                        padding: EdgeInsets.zero,
                        blur: 0,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.biggest;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _formSwarm(size);
                            });
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: MemorySwarmView(swarm: _swarm),
                                ),
                                Positioned(
                                  left: 16,
                                  top: 14,
                                  child: V2Meta(
                                    '${_swarmStep + 1} / 7  ·  ${_steps[_swarmStep]}',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: V2Space.sm),
                    SizedBox(
                      height: 96,
                      child: V2CaptureField(
                        controller: _field,
                        focusNode: _focus,
                        hint: '여기에 적으면 위의 도트가 늘어나요',
                        energy: math.min(1, _chars / 280),
                        recording: _recording,
                      ),
                    ),
                    const SizedBox(height: V2Space.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        V2Button.secondary(
                          label: '+40자',
                          size: V2ButtonSize.compact,
                          onPressed: () => setState(() {
                            _swarmStep = 0;
                            _chars = math.min(_chars + 40, 300);
                          }),
                        ),
                        V2Button.secondary(
                          label: '목소리',
                          size: V2ButtonSize.compact,
                          onPressed: () {
                            setState(() => _swarmStep = 0);
                            _swarm.setLevel(.9);
                            Future<void>.delayed(
                              const Duration(milliseconds: 320),
                              () {
                                if (mounted) _swarm.setLevel(0);
                              },
                            );
                          },
                        ),
                        V2Button(
                          label: _swarmStep < 6
                              ? '다음 단계 · ${_steps[(_swarmStep + 1) % 7]}'
                              : '처음으로',
                          size: V2ButtonSize.compact,
                          onPressed: () => setState(() {
                            if (_chars == 0) _chars = 160;
                            _swarmStep = (_swarmStep + 1) % 7;
                          }),
                        ),
                      ],
                    ),
                    _section(
                      '04',
                      '원고의 형상',
                      '원고는 꿈의 사물을 도트로 인쇄한 이미지예요. 재료가 쌓일수록 도트가 채워지고 또렷해지지만, 끝까지 완전히 선명해지지는 않아요. 손가락으로 만져 보세요.',
                    ),
                    V2Segmented<V2Motif>(
                      segments: const [
                        (V2Motif.door, '문'),
                        (V2Motif.window, '창'),
                        (V2Motif.stairs, '계단'),
                        (V2Motif.umbrella, '우산'),
                        (V2Motif.horizon, '바다'),
                      ],
                      value: _motif,
                      onChanged: (value) => setState(() {
                        _motif = value;
                        _growFrom = null;
                      }),
                    ),
                    const SizedBox(height: V2Space.md),
                    V2Surface(
                      kind: V2SurfaceKind.paper,
                      radius: V2Radius.hero,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          V2Manuscript(
                            motif: _motif,
                            seed: 7,
                            progress: _progress,
                            growFrom: _growFrom,
                            growthKey: _growFrom == null ? null : _growthKey,
                            interactive: true,
                          ),
                          const SizedBox(height: V2Space.md),
                          Row(
                            children: [
                              V2Meta(
                                '선명도 ${(halftoneClarity(_progress) * 100).round()}%  ·  최대 ${(V2Dot.maxClarity * 100).round()}%',
                              ),
                              const Spacer(),
                              V2DotMatrix(
                                '${(_progress * 100).round()}%',
                                pitch: 3.6,
                                color: V2Color.inkDot,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: V2Space.sm),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: V2Color.sky600,
                        inactiveTrackColor: V2Color.ink.withValues(alpha: .1),
                        thumbColor: V2Color.ink,
                        overlayColor: V2Color.sky300.withValues(alpha: .3),
                      ),
                      child: Slider(
                        value: _progress,
                        label: '진척',
                        onChanged: (value) => setState(() {
                          _progress = value;
                          _growFrom = null;
                        }),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        V2Button(
                          label: '꿈 하나 더하기 +6%',
                          size: V2ButtonSize.compact,
                          onPressed: _progress >= 1 ? null : () => _grow(.06),
                        ),
                        V2Button.glass(
                          label: '완성 보기',
                          size: V2ButtonSize.compact,
                          onPressed: () => _grow(1 - _progress),
                        ),
                      ],
                    ),
                    const SizedBox(height: V2Space.lg),
                    V2CompletionReveal(motif: _motif, seed: 11),
                    _section(
                      '05',
                      '진행과 숫자',
                      '채운 도트는 쓰인 재료, 하늘색은 방금 더해진 것, 빈 고리는 아직 비어 있는 자리예요.',
                    ),
                    V2DotProgress(value: _progress, recent: .06),
                    const SizedBox(height: V2Space.md),
                    const V2StepProgress(steps: 4, current: 2.55),
                    const SizedBox(height: V2Space.md),
                    const Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        V2DotMatrix('10.27', pitch: 3, color: V2Color.ink),
                        V2DotMatrix('DREAM 012', pitch: 2, color: V2Color.ink2),
                        V2DotMatrix('+4%', pitch: 3, color: V2Color.sky600),
                        V2StatusPill(
                          title: '원고가 자랐어요',
                          detail: '+4%  ·  새 장면  ·  보강 2',
                        ),
                      ],
                    ),
                    _section(
                      '06',
                      '대기',
                      '화면마다 같은 하늘이 상태에 맞게 빛의 위치만 옮겨요. 상태가 바뀔 때만 움직여요.',
                    ),
                    V2Segmented<V2Mood>(
                      segments: const [
                        (V2Mood.intro, '소개'),
                        (V2Mood.home, '원고'),
                        (V2Mood.capture, '기록'),
                        (V2Mood.processing, '처리'),
                        (V2Mood.reveal, '공개'),
                      ],
                      value: _mood,
                      onChanged: (value) => setState(() => _mood = value),
                    ),
                    _section(
                      '07',
                      '계정과 잠금',
                      '실제 앱의 로그인·동의·잠금 관문이 V2로 그리는 화면이에요. 규칙은 V1과 같은 관문 코드가 정해요.',
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        for (final (label, page) in [
                          ('대기', const V2WaitPage(title: '원고를 여는 중')),
                          (
                            '차단',
                            V2GatePage(
                              meta: 'ACCOUNT',
                              title: '원고를 불러오지 못했어요.',
                              body: '연결을 확인한 뒤 다시 시도해 주세요.',
                              action: V2Button(
                                label: '다시 시도',
                                expand: true,
                                onPressed: () {},
                              ),
                            ),
                          ),
                          (
                            '잠금',
                            V2LockedPage(
                              lock: AppLockController(
                                MemorySecureValueStore(),
                                const PreviewAuthenticator(),
                              ),
                            ),
                          ),
                        ])
                          V2Button.secondary(
                            label: label,
                            size: V2ButtonSize.compact,
                            onPressed: () => Navigator.of(
                              context,
                            ).push(v2Route(_LabFrame(child: page))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String index, String title, String body) => Padding(
    padding: const EdgeInsets.only(top: V2Space.xxl, bottom: V2Space.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        V2DotMatrix(index, pitch: 2.6, color: V2Color.sky600),
        const SizedBox(height: V2Space.xs),
        Semantics(header: true, child: Text(title, style: V2Type.title)),
        const SizedBox(height: V2Space.xxs),
        Text(body, style: V2Type.bodySmall),
      ],
    ),
  );
}

/// A full page shown from the lab, with a close control on top.
class _LabFrame extends StatelessWidget {
  const _LabFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned(
        right: V2Space.sm,
        bottom: MediaQuery.paddingOf(context).bottom + V2Space.xxl + 80,
        child: V2IconButton(
          icon: Icons.close_rounded,
          semanticLabel: '랩으로 돌아가기',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}
