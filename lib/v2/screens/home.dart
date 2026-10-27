// V2 Home / Manuscript Progress (brief §7.2). The manuscript is a halftone
// print of the volume's real material; a fresh progress event flies new dots
// into it once. Data and presentation receipts come from the same providers
// and repository calls as V1.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../../ui/library/library_screen.dart' show CompletionScreen;
import '../components/brand.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/progress.dart';
import '../design/dot_matrix.dart';
import '../design/halftone.dart';
import '../design/press.dart';
import '../design/surface.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'v1_bridge.dart';

class V2HomeScreen extends ConsumerWidget {
  const V2HomeScreen({
    super.key,
    required this.onCapture,
    this.onRead,
    this.onReadScene,
    this.onArchive,
    this.onSettings,
    this.isActive = true,
  });

  final VoidCallback onCapture;
  final VoidCallback? onRead;
  final ValueChanged<String>? onReadScene;
  final VoidCallback? onArchive;
  final VoidCallback? onSettings;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeAsync = ref.watch(activeVolumeProvider);
    return volumeAsync.when(
      loading: () => const _HomeMessage('원고를 펼치는 중'),
      error: (_, _) => _HomeMessage(
        '원고를 불러오지 못했어요.',
        action: '다시 불러오기',
        onAction: () => ref.invalidate(activeVolumeProvider),
      ),
      data: (volume) {
        if (volume == null) {
          return _HomeFrame(
            onSettings: onSettings,
            children: [
              const _Masthead(title: '첫 꿈에서\n원고가 시작돼요', meta: '아직 원고가 없어요'),
              const SizedBox(height: V2Space.lg),
              _ManuscriptCard(
                volumeId: 'empty',
                motif: V2Motif.door,
                progress: 0,
                percent: 0,
              ),
              const SizedBox(height: V2Space.lg),
              V2PrimaryAction(label: '첫 꿈 기록하기', onPressed: onCapture),
            ],
          );
        }
        if (volume.status == VolumeStatus.completed ||
            volume.status == VolumeStatus.completing) {
          return _FinishedHome(volume: volume, onSettings: onSettings);
        }
        final progressAsync = ref.watch(recentProgressProvider(volume.id));
        return progressAsync.when(
          loading: () => const _HomeMessage('원고를 펼치는 중'),
          error: (_, _) => _HomeMessage(
            '원고를 불러오지 못했어요.',
            action: '다시 불러오기',
            onAction: () => ref.invalidate(recentProgressProvider(volume.id)),
          ),
          data: (events) {
            final scenes =
                ref.watch(scenesProvider(volume.id)).value ?? const <Scene>[];
            final dreams =
                ref.watch(dreamsProvider(DreamStatusFilter.all)).value ??
                const <Dream>[];
            return _HomeContent(
              volume: volume,
              latestProgressEvent: events.isEmpty ? null : events.first,
              scenes: scenes,
              dreamCount: dreams.where((d) => d.volumeId == volume.id).length,
              newScene: ref.watch(newSceneProvider(volume.id)),
              pending: dreams
                  .where(
                    (d) =>
                        d.volumeId == volume.id &&
                        (d.status == DreamStatus.queued ||
                            d.status == DreamStatus.processing ||
                            d.status == DreamStatus.failed),
                  )
                  .toList(),
              isActive: isActive,
              consumeGrowth: (eventId) => ref
                  .read(repositoryProvider)
                  .consumePresentation(
                    volumeId: volume.id,
                    kind: PresentationKind.growth,
                    sourceId: eventId,
                  ),
              onCapture: onCapture,
              onRead: scenes.isNotEmpty ? onRead : null,
              onReadScene: onReadScene,
              onArchive: onArchive,
              onSettings: onSettings,
            );
          },
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.volume,
    required this.latestProgressEvent,
    required this.scenes,
    required this.dreamCount,
    required this.newScene,
    required this.pending,
    required this.isActive,
    required this.consumeGrowth,
    required this.onCapture,
    this.onRead,
    this.onReadScene,
    this.onArchive,
    this.onSettings,
  });

  final Volume volume;
  final ProgressEvent? latestProgressEvent;
  final List<Scene> scenes;
  final int dreamCount;
  final Scene? newScene;
  final List<Dream> pending;
  final bool isActive;
  final Future<bool> Function(String) consumeGrowth;
  final VoidCallback onCapture;
  final VoidCallback? onRead;
  final ValueChanged<String>? onReadScene;
  final VoidCallback? onArchive;
  final VoidCallback? onSettings;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with WidgetsBindingObserver {
  String? _latestEventId;
  String? _pendingEventId;
  String? _growingEventId;
  bool _scheduled = false;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _latestEventId = widget.latestProgressEvent?.id;
    _pendingEventId = _latestEventId;
  }

  @override
  void didUpdateWidget(covariant _HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.latestProgressEvent?.id;
    if (incoming != null && incoming != _latestEventId) {
      _latestEventId = incoming;
      _pendingEventId = incoming;
      _growingEventId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  bool get _canPresent =>
      mounted &&
      widget.isActive &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      TickerMode.valuesOf(context).enabled &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  // One growth presentation per real event, claimed through the repository
  // receipt exactly like V1. Decoration never hides or invents progress.
  void _schedulePendingGrowth() {
    if (_pendingEventId == null || _scheduled || _claiming || !_canPresent) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted || _pendingEventId == null || !_canPresent) return;
      final eventId = _pendingEventId!;
      _claiming = true;
      var fresh = false;
      try {
        fresh = await widget.consumeGrowth(eventId);
      } on Object {
        // Optional decoration: a later mount may retry the receipt.
      } finally {
        _claiming = false;
      }
      if (!mounted) return;
      if (_pendingEventId == eventId) {
        _pendingEventId = null;
        if (fresh && _canPresent && !V2Motion.reduced(context)) {
          setState(() => _growingEventId = eventId);
        }
      }
      if (_pendingEventId != null) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _schedulePendingGrowth();
    final volume = widget.volume;
    final progress = progressRatio(
      progressMu: volume.progressMu,
      targetMu: volume.targetMu,
    );
    final empty = volume.progressMu == 0;
    final event = widget.latestProgressEvent;
    final delta = v2Percent(event, volume.targetMu) / 100;
    final growing = _growingEventId != null && _growingEventId == event?.id;
    final percent = (progress * 100).round();
    final hasSaved = widget.pending.isNotEmpty;
    final title =
        volume.title ??
        (empty
            ? hasSaved
                  ? '첫 꿈이\n남아 있어요'
                  : '첫 꿈을\n기다리고 있어요'
            : '이름 없는 원고');
    final meta = empty
        ? '${v2Volume(volume)}  ·  기억나는 장면 하나로 시작해요'
        : '${v2Volume(volume)}  ·  장면 ${widget.scenes.length}  ·  꿈 ${widget.dreamCount}';

    return _HomeFrame(
      onSettings: widget.onSettings,
      children: [
        _Masthead(title: title, meta: meta),
        const SizedBox(height: V2Space.lg),
        _ManuscriptCard(
          volumeId: volume.id,
          motif: motifFor(
            coverMotifId: volume.coverMotifId,
            volumeId: volume.id,
          ),
          progress: progress,
          percent: percent,
          recent: empty ? 0 : delta,
          growFrom: growing ? (progress - delta).clamp(0.0, 1.0) : null,
          growthKey: growing ? _growingEventId : null,
          onGrowthDone: () {
            if (mounted) setState(() => _growingEventId = null);
          },
        ),
        if (!empty && event != null)
          Transform.translate(
            offset: const Offset(0, -20),
            child: Center(
              child: V2StatusPill(
                title: widget.newScene != null ? '새 장면이 원고에 들어왔어요' : '원고가 자랐어요',
                detail: v2ProgressReason(event, volume.targetMu),
              ),
            ),
          )
        else
          const SizedBox(height: V2Space.lg),
        const SizedBox(height: V2Space.xs),
        if (widget.newScene != null && widget.onReadScene != null)
          _SceneCard(
            label: '새 장면',
            fresh: true,
            scene: widget.newScene!,
            number:
                widget.scenes.indexWhere((s) => s.id == widget.newScene!.id) +
                1,
            action: V2Button(
              label: '새 장면 읽기',
              size: V2ButtonSize.compact,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => widget.onReadScene!(widget.newScene!.id),
            ),
          )
        else if (volume.status == VolumeStatus.completable)
          _CompletableCard(volumeId: volume.id, onContinue: widget.onCapture)
        else if (widget.scenes.isNotEmpty && widget.onRead != null)
          _SceneCard(
            label: '최근 장면',
            scene: widget.scenes.last,
            number: widget.scenes.length,
            action: V2Button.glass(
              label: '이어 읽기',
              size: V2ButtonSize.compact,
              trailingIcon: Icons.add_rounded,
              onPressed: widget.onRead,
            ),
          )
        else
          _FirstDreamCard(onCapture: widget.onCapture),
        if (hasSaved && widget.onArchive != null) ...[
          const SizedBox(height: V2Space.sm),
          _PendingRow(
            summary: v2PendingSummary(widget.pending),
            onTap: widget.onArchive!,
          ),
        ],
      ],
    );
  }
}

class _HomeFrame extends StatelessWidget {
  const _HomeFrame({required this.children, this.onSettings});

  final List<Widget> children;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
          child: V2EdgeFade(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                V2Space.gutter,
                V2Space.xs,
                V2Space.gutter,
                V2Size.nav + bottom + V2Space.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const V2Wordmark(),
                      const Spacer(),
                      if (onSettings != null)
                        V2IconButton(
                          icon: Icons.tune_rounded,
                          semanticLabel: '읽기 설정',
                          onPressed: onSettings,
                        ),
                    ],
                  ),
                  const SizedBox(height: V2Space.lg),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            V2DotMatrix(
              v2DotDate(now),
              pitch: 2.4,
              color: V2Color.ink2,
              semanticsLabel: '오늘 ${v2SpokenDate(now)}',
            ),
            const SizedBox(width: 10),
            V2DotMatrix(
              v2Weekday(now),
              pitch: 2.4,
              color: V2Color.ink3,
              semanticsLabel: '',
            ),
          ],
        ),
        const SizedBox(height: V2Space.sm),
        Semantics(
          header: true,
          child: Text(v2KeepAll(title), style: V2Type.display),
        ),
        const SizedBox(height: V2Space.xs),
        V2Meta(meta),
      ],
    );
  }
}

class _ManuscriptCard extends StatelessWidget {
  const _ManuscriptCard({
    required this.volumeId,
    required this.motif,
    required this.progress,
    required this.percent,
    this.recent = 0,
    this.growFrom,
    this.growthKey,
    this.onGrowthDone,
  });

  final String volumeId;
  final V2Motif motif;
  final double progress;
  final int percent;
  final double recent;
  final double? growFrom;
  final Object? growthKey;
  final VoidCallback? onGrowthDone;

  @override
  Widget build(BuildContext context) {
    final from = growFrom == null ? percent : (growFrom! * 100).round();
    return V2Surface(
      kind: V2SurfaceKind.paper,
      radius: V2Radius.hero,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 34),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 248),
            child: V2Manuscript(
              columns: 38,
              motif: motif,
              seed: v2Seed(volumeId),
              progress: progress,
              growFrom: growFrom,
              growthKey: growthKey,
              onGrowthDone: onGrowthDone,
            ),
          ),
          const SizedBox(height: V2Space.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    V2Meta(percent == 0 ? '아직 형상이 없는 원고' : '원고의 재료'),
                    const SizedBox(height: V2Space.xs),
                    V2DotProgress(
                      value: progress,
                      recent: recent,
                      dots: 24,
                      semanticsLabel: '원고 재료 $percent%',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: V2Space.md),
              TweenAnimationBuilder<double>(
                key: ValueKey(growthKey),
                tween: Tween(begin: from.toDouble(), end: percent.toDouble()),
                duration: V2Motion.of(context, V2Motion.growth),
                curve: V2Motion.settle,
                builder: (context, value, _) => V2DotMatrix(
                  '${value.round()}%',
                  pitch: 4,
                  color: V2Color.inkDot,
                  semanticsLabel: '원고 $percent%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SceneCard extends ConsumerWidget {
  const _SceneCard({
    required this.label,
    required this.scene,
    required this.number,
    required this.action,
    this.fresh = false,
  });

  final String label;
  final Scene scene;
  final int number;
  final Widget action;
  final bool fresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passages = ref.watch(passagesProvider(scene.id)).value;
    final first = passages?.firstOrNull;
    return V2Surface(
      kind: V2SurfaceKind.frosted,
      radius: V2Radius.card,
      chroma: fresh ? .5 : .22,
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (fresh) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: V2Color.sky500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              V2Meta(label, color: fresh ? V2Color.sky700 : null),
              const Spacer(),
              V2DotMatrix(
                number.toString().padLeft(2, '0'),
                pitch: 2.2,
                color: V2Color.ink3,
                semanticsLabel: '$number번째 장면',
              ),
            ],
          ),
          const SizedBox(height: V2Space.sm),
          Text(v2KeepAll(scene.title ?? '제목 없는 장면'), style: V2Type.title),
          if (first != null) ...[
            const SizedBox(height: V2Space.xs),
            Text(
              v2KeepAll(first.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: V2Type.bodySmall,
            ),
          ],
          const SizedBox(height: V2Space.md),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    );
  }
}

class _FirstDreamCard extends StatelessWidget {
  const _FirstDreamCard({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) => V2Surface(
    kind: V2SurfaceKind.frosted,
    radius: V2Radius.card,
    chroma: .35,
    padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('막 깨어난 장면 하나면 충분해요', style: V2Type.headline),
        const SizedBox(height: V2Space.xs),
        Text(
          v2KeepAll('말하거나 적은 만큼 도트가 모이고, 원고의 첫 형상이 생겨요.'),
          style: V2Type.bodySmall,
        ),
        const SizedBox(height: V2Space.md),
        Align(
          alignment: Alignment.centerRight,
          child: V2Button(
            label: '첫 꿈 기록하기',
            size: V2ButtonSize.compact,
            icon: Icons.edit_outlined,
            onPressed: onCapture,
          ),
        ),
      ],
    ),
  );
}

class _CompletableCard extends StatelessWidget {
  const _CompletableCard({required this.volumeId, required this.onContinue});

  final String volumeId;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => V2Surface(
    kind: V2SurfaceKind.frosted,
    radius: V2Radius.card,
    chroma: .5,
    padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('한 권으로 묶을 수 있어요', style: V2Type.headline),
        const SizedBox(height: V2Space.xs),
        const Text(
          '현재 문장을 그대로 고정한 완성본이에요. 계속 쌓아도 괜찮아요.',
          style: V2Type.bodySmall,
        ),
        const SizedBox(height: V2Space.md),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            V2Button.secondary(
              label: '계속 쌓기',
              size: V2ButtonSize.compact,
              onPressed: onContinue,
            ),
            V2Button(
              label: '원고 완성하기',
              size: V2ButtonSize.compact,
              onPressed: () => openV1Completion(context, volumeId),
            ),
          ],
        ),
      ],
    ),
  );
}

/// The completion request flow stays on the V1 screen until it is redrawn
/// (it owns BookStore and server confirmation).
void openV1Completion(BuildContext context, String volumeId) {
  openInV1(context, CompletionScreen(volumeId: volumeId));
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => V2Pressable(
    onPressed: onTap,
    semanticLabel: '보관함에서 확인, $summary',
    builder: (context, state) => V2Surface(
      kind: V2SurfaceKind.frosted,
      radius: V2Radius.chip,
      sink: state.sink,
      hover: state.hover,
      blur: 0,
      padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: V2Color.ink2),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '보관함  ·  $summary',
              style: V2Type.bodySmall.copyWith(color: V2Color.ink),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: V2Color.ink3,
          ),
        ],
      ),
    ),
  );
}

class _FinishedHome extends StatelessWidget {
  const _FinishedHome({required this.volume, this.onSettings});

  final Volume volume;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) => _HomeFrame(
    onSettings: onSettings,
    children: [
      _Masthead(
        title: volume.status == VolumeStatus.completing
            ? '완성본을\n저장하고 있어요'
            : '한 권의 이야기가\n남았어요',
        meta: '${v2Volume(volume)}  ·  ${volume.title ?? '이름 없는 원고'}',
      ),
      const SizedBox(height: V2Space.lg),
      V2CompletionReveal(
        motif: motifFor(coverMotifId: volume.coverMotifId, volumeId: volume.id),
        seed: v2Seed(volume.id),
        playKey: 'completion-${volume.id}',
      ),
      const SizedBox(height: V2Space.lg),
      V2PrimaryAction(
        label: volume.status == VolumeStatus.completing ? '저장 상태 확인' : '완성본 열기',
        onPressed: () => openV1Completion(context, volume.id),
      ),
    ],
  );
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage(this.message, {this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(V2Space.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: V2Type.headline,
                textAlign: TextAlign.center,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: V2Space.lg),
              V2Button(label: action!, onPressed: onAction),
            ],
          ],
        ),
      ),
    ),
  );
}
