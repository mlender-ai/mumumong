import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dot_cover.dart';
import '../../core/design/dream_atmosphere.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../shared/content_state.dart';
import '../library/library_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onCapture,
    this.onRead,
    this.onReadScene,
    this.onArchive,
    this.isActive = true,
  });

  final VoidCallback onCapture;
  final VoidCallback? onRead;
  final ValueChanged<String>? onReadScene;
  final VoidCallback? onArchive;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeAsync = ref.watch(activeVolumeProvider);
    return volumeAsync.when(
      loading: () => const _HomeMessage('원고를 불러오는 중'),
      error: (_, _) => ContentState(
        message: '원고를 불러오지 못했어요.',
        action: '다시 불러오기',
        onAction: () => ref.invalidate(activeVolumeProvider),
      ),
      data: (volume) {
        if (volume == null) {
          return ContentState(
            message: '첫 꿈에서 원고가 시작됩니다.',
            action: '첫 꿈 기록하기',
            onAction: onCapture,
          );
        }
        final progressAsync = ref.watch(recentProgressProvider(volume.id));
        if ([
          VolumeStatus.completed,
          VolumeStatus.completing,
        ].contains(volume.status)) {
          return FinishedVolumeHome(volume: volume);
        }
        return progressAsync.when(
          loading: () => const _HomeMessage('원고를 불러오는 중'),
          error: (_, _) => ContentState(
            message: '원고를 불러오지 못했어요.',
            action: '다시 불러오기',
            onAction: () => ref.invalidate(recentProgressProvider(volume.id)),
          ),
          data: (events) => _HomeContent(
            volume: volume,
            latestProgressEvent: events.isEmpty ? null : events.first,
            onCapture: onCapture,
            isActive: isActive,
            consumeGrowth: (eventId) => ref
                .read(repositoryProvider)
                .consumePresentation(
                  volumeId: volume.id,
                  kind: PresentationKind.growth,
                  sourceId: eventId,
                ),
            onRead:
                (ref.watch(scenesProvider(volume.id)).value?.isNotEmpty ??
                    false)
                ? onRead
                : null,
            newScene: ref.watch(newSceneProvider(volume.id)),
            pending:
                (ref.watch(dreamsProvider(DreamStatusFilter.all)).value ??
                        const <Dream>[])
                    .where(
                      (d) =>
                          d.volumeId == volume.id &&
                          (d.status == DreamStatus.queued ||
                              d.status == DreamStatus.processing ||
                              d.status == DreamStatus.failed),
                    )
                    .toList(),
            onReadScene: onReadScene,
            onArchive: onArchive,
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.volume,
    required this.latestProgressEvent,
    required this.onCapture,
    required this.consumeGrowth,
    required this.isActive,
    this.onRead,
    this.newScene,
    this.onReadScene,
    this.onArchive,
    this.pending = const [],
  });

  final Volume volume;
  final ProgressEvent? latestProgressEvent;
  final Scene? newScene;
  final ValueChanged<String>? onReadScene;
  final VoidCallback? onArchive;
  final List<Dream> pending;
  final VoidCallback onCapture;
  final VoidCallback? onRead;
  final Future<bool> Function(String) consumeGrowth;
  final bool isActive;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _growthController;
  String? _latestEventId;
  String? _pendingEventId;
  bool _animateGrowth = false;
  bool _animationScheduled = false;
  bool _growthClaimInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _latestEventId = widget.latestProgressEvent?.id;
    _pendingEventId = _latestEventId;
    // One controller for the whole growth recipe (DESIGN.md §9): the number
    // counts up during the first `gather` span, the cover keeps arriving
    // until `growth` completes. Plays once per fresh progress event.
    _growthController =
        AnimationController(vsync: this, duration: MongMotion.growth)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _animateGrowth = false);
            }
          });
  }

  @override
  void didUpdateWidget(covariant _HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingId = widget.latestProgressEvent?.id;
    if (incomingId != null && incomingId != _latestEventId) {
      _latestEventId = incomingId;
      _pendingEventId = incomingId;
      _growthController.stop();
      _animateGrowth = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _growthController.dispose();
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

  void _schedulePendingGrowth() {
    if (_pendingEventId == null ||
        _animationScheduled ||
        _growthClaimInFlight) {
      return;
    }
    if (!_canPresent) return;

    _animationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _animationScheduled = false;
      if (!mounted || _pendingEventId == null) return;
      if (!_canPresent) return;
      final eventId = _pendingEventId!;
      _growthClaimInFlight = true;
      var fresh = false;
      try {
        fresh = await widget.consumeGrowth(eventId);
      } on Object {
        // Decoration is optional: do not hide real progress or loop on a
        // failing device store. A later mount can retry the receipt.
      } finally {
        _growthClaimInFlight = false;
      }
      if (!mounted) return;
      if (_pendingEventId == eventId) {
        _pendingEventId = null;
        if (fresh && _canPresent && !MediaQuery.disableAnimationsOf(context)) {
          setState(() => _animateGrowth = true);
          _growthController.forward(from: 0);
        }
      }
      if (_pendingEventId != null) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _schedulePendingGrowth();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = progressRatio(
      progressMu: widget.volume.progressMu,
      targetMu: widget.volume.targetMu,
    );
    final empty = widget.volume.progressMu == 0;
    final hasSavedDream = widget.pending.isNotEmpty;
    final growthDelta =
        _progressPercent(widget.latestProgressEvent, widget.volume.targetMu) /
        100;
    final coverSpec = homeCoverSpec(widget.volume.id, progress);
    final previousCover = _animateGrowth && !reduceMotion
        ? homeCoverSpec(widget.volume.id, progress - growthDelta)
        : null;
    final title =
        widget.volume.title ??
        (empty
            ? hasSavedDream
                  ? '첫 꿈이 남아 있어요'
                  : '첫 꿈을 기다리고 있어요'
            : '이름 없는 원고');
    final volumeLabel = 'VOL.${widget.volume.volNo.toString().padLeft(2, '0')}';
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox.expand(
          child: SafeArea(
            top: false,
            // Scaffold.extendBody contributes the real GNB height here. Keep
            // scroll/focus targets above it, including with enlarged text.
            bottom: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topInset = MediaQuery.paddingOf(context).top;
                // Large type needs the copy and actions above the GNB at
                // rest; the cover gives up height before the actions do.
                final largeType =
                    MediaQuery.textScalerOf(context).scale(16) > 20;
                final heroHeight =
                    ((constraints.maxHeight + bottomInset) *
                            (largeType ? .40 : .54))
                        .clamp(largeType ? 240.0 : 340.0, 440.0) +
                    topInset;

                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(MongRadius.panel),
                          child: SizedBox(
                            width: double.infinity,
                            height: heroHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DreamAtmosphere(
                                    animate: _canPresent,
                                    night: context.isNight,
                                  ),
                                ),
                                // DESIGN.md §8: the cover is the volume's dot
                                // field; density/clarity follow real progress.
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      MongSpace.lg,
                                      topInset + MongSpace.xxl + MongSpace.md,
                                      MongSpace.lg,
                                      MongSpace.xxl,
                                    ),
                                    child: DotCover(
                                      key: const ValueKey('home-cover'),
                                      spec: coverSpec,
                                      previous: previousCover,
                                      transition: _growthController,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: topInset + 22,
                                  left: 22,
                                  child: const MongWordmark(),
                                ),
                                Positioned(
                                  top: topInset + 24,
                                  right: 22,
                                  child: MetaText(
                                    volumeLabel,
                                    color: context.secondaryInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MongSpace.screen,
                          MongSpace.lg,
                          MongSpace.screen,
                          MongSpace.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displayMedium,
                                  ),
                                ),
                                if (!empty)
                                  AnimatedBuilder(
                                    animation: _growthController,
                                    builder: (context, _) {
                                      final completed = (progress * 100)
                                          .round();
                                      final delta = _progressPercent(
                                        widget.latestProgressEvent,
                                        widget.volume.targetMu,
                                      );
                                      // Count-up spans the `gather` portion
                                      // of the growth controller.
                                      final countUp = MongMotion.enter
                                          .transform(
                                            (_growthController.value /
                                                    (MongMotion
                                                            .gather
                                                            .inMilliseconds /
                                                        MongMotion
                                                            .growth
                                                            .inMilliseconds))
                                                .clamp(0.0, 1.0),
                                          );
                                      final shown =
                                          _animateGrowth && !reduceMotion
                                          ? (completed -
                                                    delta +
                                                    delta * countUp)
                                                .round()
                                          : completed;
                                      return Text(
                                        '$shown%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: context.primaryInk,
                                            ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: MongSpace.xs),
                            MetaText(
                              empty
                                  ? hasSavedDream
                                        ? '기록한 기억은 보관함에서 다시 볼 수 있어요.'
                                        : '기억나는 장면 하나로 시작해요.'
                                  : '$volumeLabel  ·  원고 진행',
                            ),
                            // Today's change and why, from the real event.
                            if (!empty && widget.latestProgressEvent != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: MongSpace.xxs,
                                ),
                                child: MetaText(
                                  progressReasonLabel(
                                    widget.latestProgressEvent!,
                                    widget.volume.targetMu,
                                  ),
                                  color: context.accentInk,
                                ),
                              ),
                            const OfflineNotice(),
                            const SizedBox(height: MongSpace.xl),
                            MongActionGroup(
                              primary: EditorialButton(
                                label:
                                    widget.newScene != null &&
                                        widget.onReadScene != null
                                    ? '새 장면 읽기'
                                    : widget.volume.status ==
                                          VolumeStatus.completable
                                    ? '원고 완성하기'
                                    : '꿈 기록하기',
                                onPressed:
                                    widget.newScene != null &&
                                        widget.onReadScene != null
                                    ? () => widget.onReadScene!(
                                        widget.newScene!.id,
                                      )
                                    : widget.volume.status ==
                                          VolumeStatus.completable
                                    ? () => Navigator.push(
                                        context,
                                        quietPageRoute(
                                          CompletionScreen(
                                            volumeId: widget.volume.id,
                                          ),
                                        ),
                                      )
                                    : widget.onCapture,
                              ),
                              secondary: [
                                if (widget.volume.status ==
                                        VolumeStatus.completable &&
                                    widget.newScene == null)
                                  MongButton.ghost(
                                    label: '계속 쌓기',
                                    onPressed: widget.onCapture,
                                  ),
                                if (widget.newScene != null &&
                                    widget.onReadScene != null)
                                  MongButton.ghost(
                                    label: '꿈 기록하기',
                                    onPressed: widget.onCapture,
                                  )
                                else if (widget.onRead != null)
                                  MongButton.ghost(
                                    label: '이어 읽기',
                                    onPressed: widget.onRead,
                                  ),
                              ],
                            ),
                            if (widget.pending.isNotEmpty &&
                                widget.onArchive != null) ...[
                              const SizedBox(height: MongSpace.lg),
                              Center(
                                child: MongButton.ghost(
                                  label:
                                      '보관함에서 확인 · ${_pendingSummary(widget.pending)}',
                                  onPressed: widget.onArchive,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) =>
      SafeArea(child: Center(child: MetaText(message)));
}

int _progressPercent(ProgressEvent? event, double targetMu) {
  if (event == null || targetMu <= 0) return 0;
  return (event.deltaMu / targetMu * 100).round();
}

/// "+4% · 새 장면 · 보강 2" from the event's recorded reasons only. Never
/// invents a cause; unknown reason types are skipped.
@visibleForTesting
String progressReasonLabel(ProgressEvent event, double targetMu) {
  final percent = _progressPercent(event, targetMu);
  final parts = <String>['${percent >= 0 ? '+' : ''}$percent%'];
  for (final reason in event.reasons) {
    final n = reason['n'];
    final count = n is num ? n.toInt() : 1;
    final label = switch (reason['type']) {
      'new_scene' => '새 장면',
      'recall' => '보강 $count',
      'link_decision' => '연결 결정',
      'dream_removed' => '기록 제외',
      'user_passage' => '내 문장',
      _ => null,
    };
    if (label != null) parts.add(label);
  }
  return parts.join('  ·  ');
}

String _pendingSummary(List<Dream> dreams) => [
  for (final (status, label) in [
    (DreamStatus.queued, '생성 전'),
    (DreamStatus.processing, '진행 중'),
    (DreamStatus.failed, '재시도'),
  ])
    if (dreams.any((dream) => dream.status == status))
      '${dreams.where((dream) => dream.status == status).length}개 $label',
].join(' · ');
