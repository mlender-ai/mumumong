import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../core/design/dot_field.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../reader/reader_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeAsync = ref.watch(activeVolumeProvider);
    return volumeAsync.when(
      loading: () => const _HomeMessage('원고를 불러오는 중'),
      error: (_, _) => const _HomeMessage('원고를 불러오지 못했어요.'),
      data: (volume) {
        if (volume == null) {
          return const _HomeMessage('첫 꿈에서 원고가 시작됩니다.');
        }
        final dreamsAsync = ref.watch(dreamsProvider(DreamStatusFilter.all));
        final scenesAsync = ref.watch(scenesProvider(volume.id));
        final progressAsync = ref.watch(recentProgressProvider(volume.id));
        return dreamsAsync.when(
          loading: () => const _HomeMessage('원고를 불러오는 중'),
          error: (_, _) => const _HomeMessage('원고를 불러오지 못했어요.'),
          data: (dreams) => scenesAsync.when(
            loading: () => const _HomeMessage('원고를 불러오는 중'),
            error: (_, _) => const _HomeMessage('원고를 불러오지 못했어요.'),
            data: (scenes) => progressAsync.when(
              loading: () => const _HomeMessage('원고를 불러오는 중'),
              error: (_, _) => const _HomeMessage('원고를 불러오지 못했어요.'),
              data: (events) => _HomeContent(
                volume: volume,
                dreams: dreams,
                scenes: scenes,
                latestProgressEvent: events.isEmpty ? null : events.first,
                onCapture: onCapture,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.volume,
    required this.dreams,
    required this.scenes,
    required this.latestProgressEvent,
    required this.onCapture,
  });

  final Volume volume;
  final List<Dream> dreams;
  final List<Scene> scenes;
  final ProgressEvent? latestProgressEvent;
  final VoidCallback onCapture;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _growthController;
  String? _latestEventId;
  String? _pendingEventId;
  bool _animateGrowth = false;
  bool _animationScheduled = false;

  @override
  void initState() {
    super.initState();
    _latestEventId = widget.latestProgressEvent?.id;
    _growthController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 3000),
        )..addStatusListener((status) {
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
    }
  }

  @override
  void dispose() {
    _growthController.dispose();
    super.dispose();
  }

  void _schedulePendingGrowth() {
    if (_pendingEventId == null || _animationScheduled) {
      return;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    _animationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationScheduled = false;
      if (!mounted || _pendingEventId == null) {
        return;
      }
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }
      _pendingEventId = null;
      setState(() => _animateGrowth = true);
      _growthController.forward(from: 0);
    });
  }

  void _openReader() {
    Navigator.of(context).push(quietPageRoute(const ReaderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    _schedulePendingGrowth();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = progressRatio(
      progressMu: widget.volume.progressMu,
      targetMu: widget.volume.targetMu,
    );
    final latestDream = widget.dreams.isEmpty ? null : widget.dreams.first;
    final openScene = _latestOpenScene(widget.scenes);
    final title = widget.volume.title ?? '이름 없는 원고';

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverWidth = (constraints.maxWidth - 96).clamp(220.0, 292.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MetaText(
                        'VOL.${widget.volume.volNo.toString().padLeft(2, '0')}',
                      ),
                      MetaText(
                        latestDream == null
                            ? 'YOUR FIRST DREAM'
                            : _englishDate(latestDream.dreamDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: GestureDetector(
                      onTap: _openReader,
                      child: SizedBox(
                        width: coverWidth,
                        child: AnimatedBuilder(
                          animation: _growthController,
                          builder: (context, _) {
                            final value = !_animateGrowth || reduceMotion
                                ? 1.0
                                : MongMotion.form.transform(
                                    (_growthController.value / .5).clamp(0, 1),
                                  );
                            return DotCover(
                              clarity: (.10 + .70 * progress).clamp(0, .9),
                              growth: value,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _growthController,
                        builder: (context, _) {
                          final completed = (progress * 100).round();
                          final deltaPercent = _deltaPercent(
                            widget.latestProgressEvent,
                            widget.volume.targetMu,
                          ).abs();
                          final shown = _animateGrowth && !reduceMotion
                              ? (completed -
                                        deltaPercent +
                                        deltaPercent *
                                            Curves.easeOut.transform(
                                              _growthController.value,
                                            ))
                                    .round()
                              : completed;
                          return Text(
                            '$shown%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontSize: 15, color: MongColor.ink),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MetaText(
                    '${widget.dreams.length} dreams     '
                    '${widget.scenes.length} scenes     '
                    '약 ${(progress * 84).round()}p',
                  ),
                  AnimatedSize(
                    duration: MongMotion.base,
                    alignment: Alignment.topCenter,
                    child: _animateGrowth
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _ProgressDeltaLine(
                              event: widget.latestProgressEvent,
                              targetMu: widget.volume.targetMu,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Text(
                    _genreLine(widget.volume.genreProfile),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: MongColor.ink2),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: EditorialButton(
                          label: '꿈 기록하기',
                          onPressed: widget.onCapture,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: EditorialButton(
                          label: '이어 읽기',
                          onPressed: _openReader,
                          dark: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (openScene != null)
                    InkWell(
                      onTap: _openReader,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3,
                              height: 42,
                              margin: const EdgeInsets.only(right: 14, top: 2),
                              color: MongColor.sky500,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const MetaText('열린 장면'),
                                  const SizedBox(height: 5),
                                  Text(
                                    openScene.openImage!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: MongColor.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressDeltaLine extends StatelessWidget {
  const _ProgressDeltaLine({required this.event, required this.targetMu});

  final ProgressEvent? event;
  final double targetMu;

  @override
  Widget build(BuildContext context) {
    final current = event;
    if (current == null) {
      return const SizedBox.shrink();
    }
    final labels = current.reasons.map(_reasonLabel).whereType<String>();
    final percent = _deltaPercent(current, targetMu);
    return Row(
      children: [
        const MetaText('오늘', color: MongColor.ink3),
        for (final label in labels.take(2)) ...[
          const SizedBox(width: 18),
          MetaText(label, color: MongColor.ink),
        ],
        const Spacer(),
        MetaText('${percent >= 0 ? '+' : ''}$percent%', color: MongColor.ink),
      ],
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(child: MetaText(message, color: MongColor.ink3)),
    );
  }
}

Scene? _latestOpenScene(List<Scene> scenes) {
  for (final scene in scenes.reversed) {
    if (scene.openImage != null && scene.openImage!.isNotEmpty) {
      return scene;
    }
  }
  return null;
}

int _deltaPercent(ProgressEvent? event, double targetMu) {
  if (event == null || targetMu <= 0) {
    return 0;
  }
  return (event.deltaMu / targetMu * 100).round();
}

String? _reasonLabel(Map<String, dynamic> reason) {
  final count = reason['n'] is num ? (reason['n'] as num).toInt() : 1;
  return switch (reason['type']) {
    'new_scene' => '새 장면 $count',
    'recall' => '기억 보강 $count',
    'link_decision' => '연결 $count 확정',
    'dream_removed' => '꿈 $count 제외',
    _ => null,
  };
}

String _genreLine(Map<String, double> profile) {
  if (profile.isEmpty) {
    return '꿈이 쌓이면 원고의 성격이 보여요.';
  }
  final genres = profile.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return '${genres.take(2).map((entry) => entry.key).join('와 ')}의 성격이 보여요.';
}

String _englishDate(DateTime date) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${months[date.month - 1]} ${date.day} ${date.year}';
}
