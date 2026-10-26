// Development-only UI catalog (DESIGN.md §14-1). Never deployed by
// deploy_live_trial.sh. No account, storage, audio or AI requests.
//
//   flutter run -t tool/ui_catalog.dart
//   flutter build web --release --target tool/ui_catalog.dart --output build/ui-catalog
//   open http://127.0.0.1:4228/?night=true&reduce=true
import 'package:flutter/material.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dot_cover.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/core/design/thinking_orb.dart';

void main() {
  final query = Uri.base.queryParameters;
  runApp(
    UiCatalogApp(
      night: query['night'] == 'true',
      reduceMotion: query['reduce'] == 'true',
    ),
  );
}

class UiCatalogApp extends StatefulWidget {
  const UiCatalogApp({
    super.key,
    this.night = false,
    this.reduceMotion = false,
  });
  final bool night;
  final bool reduceMotion;

  @override
  State<UiCatalogApp> createState() => _UiCatalogAppState();
}

class _UiCatalogAppState extends State<UiCatalogApp> {
  late bool _night = widget.night;
  late bool _reduce = widget.reduceMotion;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '무무몽 · UI Catalog',
    debugShowCheckedModeBanner: false,
    theme: _night ? dreamNightTheme() : mumumongTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: _reduce),
      child: child!,
    ),
    home: UiCatalogPage(
      night: _night,
      reduceMotion: _reduce,
      onNight: (v) => setState(() => _night = v),
      onReduce: (v) => setState(() => _reduce = v),
    ),
  );
}

class UiCatalogPage extends StatefulWidget {
  const UiCatalogPage({
    super.key,
    required this.night,
    required this.reduceMotion,
    required this.onNight,
    required this.onReduce,
  });
  final bool night;
  final bool reduceMotion;
  final ValueChanged<bool> onNight;
  final ValueChanged<bool> onReduce;

  @override
  State<UiCatalogPage> createState() => _UiCatalogPageState();
}

class _UiCatalogPageState extends State<UiCatalogPage>
    with SingleTickerProviderStateMixin {
  late final _growth = AnimationController(
    vsync: this,
    duration: MongMotion.growth,
  );
  var _coverSpec = const DotCoverSpec(seed: 7, density: .3, clarity: .45);
  DotCoverSpec? _previousSpec;
  bool _chipSelected = true;
  bool _recording = false;
  bool _switchOn = true;
  int _stampKey = 0;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _growth.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _grow() {
    setState(() {
      _previousSpec = _coverSpec;
      _coverSpec = _coverSpec.copyWith(
        density: (_coverSpec.density + .18).clamp(0.0, 1.0),
        clarity: (_coverSpec.clarity + .12).clamp(0.0, DotCoverSpec.maxClarity),
      );
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _growth.value = 1;
    } else {
      _growth.forward(from: 0);
    }
  }

  void _resetCover() {
    setState(() {
      _previousSpec = null;
      _coverSpec = const DotCoverSpec(seed: 7, density: .3, clarity: .45);
      _growth.value = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: MongSize.readingMaxWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                MongSpace.screen,
                MongSpace.lg,
                MongSpace.screen,
                MongSpace.xxl,
              ),
              children: [
                Wrap(
                  spacing: MongSpace.xs,
                  runSpacing: MongSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const MongWordmark(animate: true),
                    MongChip(
                      label: widget.night ? '어둡게' : '밝게',
                      selected: widget.night,
                      onTap: () => widget.onNight(!widget.night),
                    ),
                    const SizedBox(width: MongSpace.xs),
                    MongChip(
                      label: '동작 줄이기',
                      selected: widget.reduceMotion,
                      onTap: () => widget.onReduce(!widget.reduceMotion),
                    ),
                  ],
                ),
                const SizedBox(height: MongSpace.md),
                Text('UI Catalog', style: text.displayMedium),
                const SizedBox(height: MongSpace.xs),
                Text(
                  'DESIGN.md의 모든 토큰·컴포넌트·상태를 한 화면에서 검수한다. 개발 전용.',
                  style: text.bodySmall,
                ),

                _section(context, '1. 색 토큰'),
                Wrap(
                  spacing: MongSpace.xs,
                  runSpacing: MongSpace.xs,
                  children: [
                    for (final (name, color) in const [
                      ('paper', MongColor.paper),
                      ('paperPure', MongColor.paperPure),
                      ('paperShade', MongColor.paperShade),
                      ('line', MongColor.line),
                      ('ink', MongColor.ink),
                      ('ink2', MongColor.ink2),
                      ('ink3', MongColor.ink3),
                      ('alert', MongColor.alert),
                      ('sky50', MongColor.sky50),
                      ('sky100', MongColor.sky100),
                      ('sky200', MongColor.sky200),
                      ('sky300', MongColor.sky300),
                      ('sky400', MongColor.sky400),
                      ('sky500', MongColor.sky500),
                      ('sky600', MongColor.sky600),
                      ('sky700', MongColor.sky700),
                      ('sky800', MongColor.sky800),
                      ('orbInk', MongColor.orbInk),
                      ('lightSky', MongColor.lightSky),
                      ('lightDeep', MongColor.lightDeep),
                      ('lightSoft', MongColor.lightSoft),
                      ('lightHaze', MongColor.lightHaze),
                      ('nightCanvas', MongColor.nightCanvas),
                      ('nightRaised', MongColor.nightRaised),
                      ('nightSky', MongColor.nightSky),
                      ('readerNightPaper', MongColor.readerNightPaper),
                    ])
                      _Swatch(name: name, color: color),
                  ],
                ),

                _section(context, '2. 타이포그래피'),
                Text('꿈이 자라, 이야기가 되는 곳.', style: text.displayLarge),
                const SizedBox(height: MongSpace.xs),
                Text('첫 이야기를 시작해 볼까요?', style: text.displayMedium),
                const SizedBox(height: MongSpace.xs),
                Text('장면을 조정하기', style: text.headlineSmall),
                const SizedBox(height: MongSpace.xs),
                Text('소설을 만들고 있어요', style: text.titleMedium),
                const SizedBox(height: MongSpace.xs),
                Text(
                  '복도 바닥에 물이 차 있었다. 걸음을 옮길 때마다 얇은 파문이 벽까지 밀려갔다.',
                  style: manuscriptStyle(context),
                ),
                const SizedBox(height: MongSpace.xs),
                Text('기억나는 장면 하나면 충분해요.', style: text.bodyMedium),
                const SizedBox(height: MongSpace.xs),
                Text('이 기기에 저장돼요. 원고의 내용은 바뀌지 않아요.', style: text.bodySmall),
                const SizedBox(height: MongSpace.xs),
                Text('장면 만들기', style: text.labelLarge),
                const SizedBox(height: MongSpace.xs),
                Text('선명한 기억', style: text.labelMedium),
                const SizedBox(height: MongSpace.xs),
                const MetaText('DREAM 008  →  SCENE 12'),

                _section(context, '3. Surface Levels'),
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MongRadius.panel),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DreamAtmosphere(
                            night: widget.night,
                            memoryObject: true,
                          ),
                        ),
                        Positioned(
                          left: MongSpace.md,
                          top: MongSpace.md,
                          child: MetaText(
                            'Level 1 · Atmospheric',
                            color: context.secondaryInk,
                          ),
                        ),
                        Positioned(
                          left: MongSpace.md,
                          right: MongSpace.md,
                          bottom: MongSpace.md,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: MongSurface(
                                  padding: const EdgeInsets.all(MongSpace.md),
                                  child: Text(
                                    'Level 2 · Frosted',
                                    style: text.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: MongSpace.xs),
                              Expanded(
                                child: MongSurface(
                                  level: MongSurfaceLevel.elevated,
                                  padding: const EdgeInsets.all(MongSpace.md),
                                  child: Text(
                                    'Level 3 · Elevated',
                                    style: text.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: MongSpace.xs),
                              Expanded(
                                child: MongSurface(
                                  level: MongSurfaceLevel.paper,
                                  padding: const EdgeInsets.all(MongSpace.md),
                                  child: Text(
                                    'Level 0 · Paper',
                                    style: text.labelLarge,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _section(context, '4. MongButton — variants × states'),
                for (final variant in MongButtonVariant.values) ...[
                  MetaText(variant.name),
                  const SizedBox(height: MongSpace.xs),
                  Wrap(
                    spacing: MongSpace.xs,
                    runSpacing: MongSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MongButton(
                        label: 'Default',
                        variant: variant,
                        expanded: false,
                        onPressed: () {},
                      ),
                      MongButton(
                        label: 'Icon',
                        variant: variant,
                        expanded: false,
                        icon: Icons.arrow_upward_rounded,
                        onPressed: () {},
                      ),
                      MongButton(
                        label: 'Disabled',
                        variant: variant,
                        expanded: false,
                        onPressed: null,
                      ),
                      MongButton(
                        label: 'Loading',
                        variant: variant,
                        expanded: false,
                        loadingLabel: '저장하는 중',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: MongSpace.md),
                ],
                MetaText('over atmosphere · lightContent'),
                const SizedBox(height: MongSpace.xs),
                SizedBox(
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MongRadius.panel),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: DreamAtmosphere(night: true, animate: false),
                        ),
                        Center(
                          child: Wrap(
                            spacing: MongSpace.xs,
                            children: [
                              MongButton(
                                label: '체험 계정으로 시작',
                                expanded: false,
                                lightContent: true,
                                onPressed: () {},
                              ),
                              MongButton(
                                label: '가상 꿈 미리 보기',
                                variant: MongButtonVariant.secondary,
                                expanded: false,
                                lightContent: true,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MongSpace.md),
                MetaText('MongActionGroup · 280px primary + ghost secondary'),
                const SizedBox(height: MongSpace.xs),
                MongActionGroup(
                  primary: MongButton(label: '장면 만들기', onPressed: () {}),
                  secondary: [
                    MongButton.ghost(label: '기억 더 보강하기', onPressed: () {}),
                    MongButton.ghost(label: '나중에 만들기', onPressed: () {}),
                  ],
                ),

                _section(context, '5. MongIconButton'),
                Wrap(
                  spacing: MongSpace.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MongIconButton(
                      icon: Icons.close_rounded,
                      semanticLabel: '닫기',
                      onPressed: () {},
                    ),
                    MongIconButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: '뒤로',
                      variant: MongIconButtonVariant.glass,
                      onPressed: () {},
                    ),
                    MongIconButton(
                      icon: _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      semanticLabel: _recording ? '녹음 정지' : '녹음',
                      variant: MongIconButtonVariant.recording,
                      active: _recording,
                      onPressed: () => setState(() => _recording = !_recording),
                    ),
                    MongIconButton(
                      icon: Icons.mic_rounded,
                      semanticLabel: '녹음 불가',
                      variant: MongIconButtonVariant.recording,
                      onPressed: null,
                    ),
                  ],
                ),

                _section(context, '6. MongChip / Switch / Checkbox'),
                Wrap(
                  spacing: MongSpace.xs,
                  runSpacing: MongSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MongChip(
                      label: '선택됨',
                      selected: _chipSelected,
                      onTap: () =>
                          setState(() => _chipSelected = !_chipSelected),
                    ),
                    MongChip(
                      label: '기본',
                      selected: !_chipSelected,
                      onTap: () =>
                          setState(() => _chipSelected = !_chipSelected),
                    ),
                    const MongChip(label: '비활성', selected: false, onTap: null),
                    Switch(
                      value: _switchOn,
                      onChanged: (v) => setState(() => _switchOn = v),
                    ),
                    Checkbox(value: true, onChanged: (_) {}),
                    Checkbox(value: false, onChanged: (_) {}),
                  ],
                ),

                _section(context, '7. MongInput states'),
                const TextField(
                  decoration: InputDecoration(
                    hintText: '기억나는 순서대로 말하거나 적어보세요…',
                  ),
                ),
                const SizedBox(height: MongSpace.xs),
                TextField(
                  focusNode: _focusNode,
                  autofocus: false,
                  decoration: const InputDecoration(hintText: 'Focused (탭)'),
                ),
                const SizedBox(height: MongSpace.xs),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Recording',
                    fillColor: context.isNight
                        ? MongColor.nightSubtle
                        : MongColor.sky50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(MongRadius.field),
                      borderSide: const BorderSide(
                        color: MongColor.sky400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MongSpace.xs),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Error',
                    errorText: '초안을 저장하지 못했어요. 입력은 그대로 남아 있어요.',
                  ),
                ),

                _section(context, '8. MongSheet · 정적 미리보기'),
                MongSurface(
                  level: MongSurfaceLevel.paper,
                  radius: MongRadius.sheet,
                  padding: const EdgeInsets.all(MongSpace.modal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MongSheetHandle(),
                      const SizedBox(height: MongSpace.lg),
                      Text('장면을 조정하기', style: text.headlineSmall),
                      const SizedBox(height: MongSpace.md),
                      Text(
                        "오늘의 '우산을 든 여자', 앞 장면의 그 사람일까요?",
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: MongSpace.md),
                      Wrap(
                        spacing: MongSpace.xs,
                        children: [
                          MongChip(
                            label: '같은 사람',
                            selected: true,
                            onTap: () {},
                          ),
                          MongChip(
                            label: '다른 사람',
                            selected: false,
                            onTap: () {},
                          ),
                          MongChip(
                            label: '모르겠음',
                            selected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: MongSpace.lg),
                      MongButton(label: '완료', onPressed: () {}),
                    ],
                  ),
                ),

                _section(context, '9. Dot system'),
                MetaText('DotCover · 모티프 × clarity (seed 고정)'),
                const SizedBox(height: MongSpace.xs),
                Wrap(
                  spacing: MongSpace.xs,
                  runSpacing: MongSpace.xs,
                  children: [
                    for (final motif in DotMotif.values)
                      for (final clarity in const [.3, .6, .9])
                        _CoverTile(
                          label: '${motif.name} · $clarity',
                          spec: DotCoverSpec(
                            seed: 11,
                            motif: motif,
                            density: .35 + clarity * .5,
                            clarity: clarity,
                          ),
                          night: widget.night,
                        ),
                  ],
                ),
                const SizedBox(height: MongSpace.md),
                MetaText('Manuscript Growth · 1400ms, 한 번'),
                const SizedBox(height: MongSpace.xs),
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MongRadius.panel),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DreamAtmosphere(
                            night: widget.night,
                            animate: false,
                            strength: .5,
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(MongSpace.lg),
                            child: DotCover(
                              spec: _coverSpec,
                              previous: _previousSpec,
                              transition: _growth,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: MongSpace.xs),
                Wrap(
                  spacing: MongSpace.xs,
                  children: [
                    MongButton(
                      label: '원고 성장 +',
                      expanded: false,
                      onPressed: _coverSpec.clarity >= DotCoverSpec.maxClarity
                          ? null
                          : _grow,
                    ),
                    MongButton.ghost(label: '처음으로', onPressed: _resetCover),
                  ],
                ),
                const SizedBox(height: MongSpace.md),
                MetaText('MemoryStamp · 650ms 응집 · Thinking Orb'),
                const SizedBox(height: MongSpace.xs),
                Row(
                  children: [
                    MemoryStamp(key: ValueKey(_stampKey)),
                    const SizedBox(width: MongSpace.md),
                    MongButton.ghost(
                      label: '다시 재생',
                      onPressed: () => setState(() => _stampKey++),
                    ),
                    const Spacer(),
                    ThinkingOrb(
                      state: DreamOrbState.composing,
                      color: widget.night
                          ? MongColor.nightSky
                          : MongColor.orbInk,
                    ),
                  ],
                ),

                _section(context, '10. Motion 토큰'),
                for (final (name, d) in [
                  ('micro', MongMotion.micro),
                  ('base', MongMotion.base),
                  ('page', MongMotion.page),
                  ('settle', MongMotion.settle),
                  ('gather', MongMotion.gather),
                  ('growth', MongMotion.growth),
                  ('reveal', MongMotion.reveal),
                  ('atmosphere', MongMotion.atmosphere),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: MongSpace.xxs),
                    child: Row(
                      children: [
                        SizedBox(width: 96, child: MetaText(name)),
                        Text('${d.inMilliseconds} ms', style: text.labelMedium),
                      ],
                    ),
                  ),
                const SizedBox(height: MongSpace.xs),
                Text(
                  '동작 줄이기: ${widget.reduceMotion ? '켜짐 — 반복 정지, 전환 즉시' : '꺼짐'}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(top: MongSpace.xxl, bottom: MongSpace.md),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(MongSpace.sm),
            border: Border.all(color: context.hairline),
          ),
        ),
        const SizedBox(height: MongSpace.xxs),
        MetaText(name),
      ],
    ),
  );
}

class _CoverTile extends StatelessWidget {
  const _CoverTile({
    required this.label,
    required this.spec,
    required this.night,
  });
  final String label;
  final DotCoverSpec spec;
  final bool night;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 148,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MongRadius.field),
          child: SizedBox(
            height: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DreamAtmosphere(
                    night: night,
                    animate: false,
                    strength: .4,
                  ),
                ),
                Positioned.fill(child: DotCover(spec: spec)),
              ],
            ),
          ),
        ),
        const SizedBox(height: MongSpace.xxs),
        MetaText(label),
      ],
    ),
  );
}
