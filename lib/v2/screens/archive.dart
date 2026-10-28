// V2 dream archive. Every dream is a memory fragment card; the small dot
// cluster on each card is its real clarity (fragment, partial, vivid).
// List, details, raw-text edit, resume, reader and delete use the same
// repository calls as V1 ArchiveScreen.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/offline.dart';
import '../components/inputs.dart';
import '../components/navigation.dart';
import '../design/dot_matrix.dart';
import '../design/press.dart';
import '../design/surface.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'capture.dart';
import 'format.dart';
import 'reader.dart';

class V2ArchiveScreen extends ConsumerStatefulWidget {
  const V2ArchiveScreen({super.key, required this.onCapture});

  final VoidCallback onCapture;

  @override
  ConsumerState<V2ArchiveScreen> createState() => _V2ArchiveScreenState();
}

class _V2ArchiveScreenState extends ConsumerState<V2ArchiveScreen> {
  DreamStatusFilter _filter = DreamStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final dreamsAsync = ref.watch(dreamsProvider(_filter));
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: V2Space.contentMax),
          child: V2EdgeFade(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    V2Space.gutter,
                    V2Space.md,
                    V2Space.gutter,
                    V2Space.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display type grows only so far, like
                                  // the capture heading.
                                  MediaQuery.withClampedTextScaling(
                                    maxScaleFactor: 1.5,
                                    child: Semantics(
                                      header: true,
                                      child: const Text(
                                        '꿈 보관함',
                                        style: V2Type.display,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: V2Space.xxs),
                                  V2Meta(
                                    dreamsAsync.hasValue
                                        ? '기억 조각 ${dreamsAsync.requireValue.length}개'
                                        : '기억 조각을 모으는 중',
                                  ),
                                ],
                              ),
                            ),
                            V2IconButton(
                              icon: Icons.add_rounded,
                              semanticLabel: '꿈 기록하기',
                              onPressed: widget.onCapture,
                            ),
                          ],
                        ),
                        const SizedBox(height: V2Space.lg),
                        const V2OfflineNotice(),
                        V2Segmented<DreamStatusFilter>(
                          segments: const [
                            (DreamStatusFilter.all, '전체'),
                            (DreamStatusFilter.inManuscript, '원고에 반영'),
                            (DreamStatusFilter.archivedOnly, '기록만'),
                          ],
                          value: _filter,
                          onChanged: (value) => setState(() => _filter = value),
                        ),
                      ],
                    ),
                  ),
                ),
                dreamsAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: V2Meta('기억 조각을 모으는 중')),
                  ),
                  error: (_, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ArchiveState(
                      message: '꿈을 불러오지 못했어요.\n저장한 기록은 그대로예요.',
                      action: '다시 불러오기',
                      onAction: () => ref.invalidate(dreamsProvider(_filter)),
                    ),
                  ),
                  data: (dreams) {
                    if (dreams.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ArchiveState(
                          message: _filter == DreamStatusFilter.all
                              ? '아직 기록된 꿈이 없어요.'
                              : '이 조건에 맞는 꿈이 없어요.',
                          action: _filter == DreamStatusFilter.all
                              ? '첫 꿈 기록하기'
                              : '전체 꿈 보기',
                          onAction: _filter == DreamStatusFilter.all
                              ? widget.onCapture
                              : () => setState(
                                  () => _filter = DreamStatusFilter.all,
                                ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        V2Space.gutter,
                        0,
                        V2Space.gutter,
                        V2Size.nav + bottom + V2Space.xxl,
                      ),
                      sliver: SliverList.builder(
                        itemCount: dreams.length,
                        itemBuilder: (context, index) {
                          final dream = dreams[index];
                          final beginsMonth =
                              index == 0 ||
                              !_sameMonth(
                                dream.dreamDate,
                                dreams[index - 1].dreamDate,
                              );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (beginsMonth) ...[
                                if (index > 0)
                                  const SizedBox(height: V2Space.md),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: V2Space.sm,
                                  ),
                                  child: V2DotMatrix(
                                    _monthLabel(dream.dreamDate),
                                    pitch: 1.8,
                                    color: V2Color.ink3,
                                    semanticsLabel:
                                        '${dream.dreamDate.year}년 ${dream.dreamDate.month}월',
                                  ),
                                ),
                              ],
                              _DreamCard(
                                dream: dream,
                                onTap: () => _showDream(dream),
                              ),
                              const SizedBox(height: V2Space.sm),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDream(Dream dream) async {
    try {
      await _showDreamDetails(dream);
    } on Object {
      if (!mounted) return;
      await showV2Dialog<void>(
        context,
        title: '기록을 불러오지 못했어요',
        body: '저장한 꿈은 지우지 않았어요. 다시 불러와 주세요.',
        actions: (dialogContext) => [
          V2Button.secondary(
            label: '닫기',
            size: V2ButtonSize.compact,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          V2Button(
            label: '다시 불러오기',
            size: V2ButtonSize.compact,
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(_showDream(dream));
            },
          ),
        ],
      );
    }
  }

  Future<void> _showDreamDetails(Dream dream) async {
    final repository = ref.read(repositoryProvider);
    final volume = await repository.watchActiveVolume().first;
    final scenes = volume == null
        ? const <Scene>[]
        : await repository.watchScenes(volume.id).first;
    final derivedScene = _sceneForDream(scenes, dream.id);
    final allDreams = await repository.watchDreams(DreamStatusFilter.all).first;
    if (!mounted) return;

    var rawText = dream.rawText;
    var openReader = false;
    await showV2Sheet<void>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .82,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _ClarityCluster(clarity: dream.clarity, size: 34),
                    const SizedBox(width: V2Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          V2DotMatrix(
                            v2DotDate(dream.dreamDate),
                            pitch: 2.2,
                            color: V2Color.ink2,
                            semanticsLabel: v2SpokenDate(dream.dreamDate),
                          ),
                          const SizedBox(height: 4),
                          V2Meta(_clarityLabel(dream.clarity)),
                        ],
                      ),
                    ),
                    _StatusPill(status: dream.status),
                  ],
                ),
                const SizedBox(height: V2Space.lg),
                Text(v2KeepAll(rawText), style: V2Type.capture),
                const SizedBox(height: V2Space.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: V2TextAction(
                    label: '원문 수정',
                    icon: Icons.edit_outlined,
                    onPressed: () async {
                      final edited = await _editDreamText(
                        dream,
                        initialText: rawText,
                      );
                      if (edited != null && context.mounted) {
                        setSheetState(() => rawText = edited);
                      }
                    },
                  ),
                ),
                const SizedBox(height: V2Space.md),
                const V2Meta('기억 보강'),
                const SizedBox(height: V2Space.xs),
                Text(_recallSummary(dream.recallAnswers), style: V2Type.body),
                const SizedBox(height: V2Space.lg),
                const V2Meta('이 꿈에서 온 장면'),
                const SizedBox(height: V2Space.xs),
                if (derivedScene != null)
                  V2Pressable(
                    onPressed: () {
                      openReader = true;
                      Navigator.pop(context);
                    },
                    semanticLabel: '${derivedScene.title ?? '제목 없는 장면'} 읽기',
                    builder: (context, state) => V2Surface(
                      kind: V2SurfaceKind.paper,
                      radius: V2Radius.card - 8,
                      sink: state.sink,
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      child: Row(
                        children: [
                          V2DotMatrix(
                            (scenes.indexOf(derivedScene) + 1)
                                .toString()
                                .padLeft(2, '0'),
                            pitch: 2,
                            color: V2Color.sky600,
                          ),
                          const SizedBox(width: V2Space.sm),
                          Expanded(
                            child: Text(
                              derivedScene.title ?? '제목 없는 장면',
                              style: V2Type.headline,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  )
                else
                  V2Meta(_statusLabel(dream.status), color: V2Color.ink2),
                const SizedBox(height: V2Space.lg),
                if (derivedScene == null &&
                    dream.status != DreamStatus.archivedOnly)
                  V2Button(
                    label: dream.status == DreamStatus.failed
                        ? '다시 처리'
                        : dream.status == DreamStatus.queued
                        ? '장면 만들기'
                        : '처리 이어가기',
                    expand: true,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(this.context).push(
                        v2Route(
                          V2CaptureFlow(
                            dreamNumber:
                                allDreams.length -
                                allDreams.indexWhere((d) => d.id == dream.id),
                            sceneNumber: scenes.length + 1,
                            savedDream: dream,
                          ),
                        ),
                      );
                    },
                  ),
                Center(
                  child: V2TextAction(
                    label: '꿈 삭제',
                    color: V2Color.alert,
                    onPressed: () async {
                      final mode = await _confirmDeleteDream(
                        hasDerivedScene: derivedScene != null,
                      );
                      if (mode == null || !context.mounted) return;
                      Navigator.pop(sheetContext);
                      await _deleteDream(dream.id, mode);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (openReader && mounted) {
      await Navigator.of(context).push(
        v2Route(
          V2ReaderScreen(
            volumeId: volume!.id,
            initialSceneId: derivedScene!.id,
            onCapture: widget.onCapture,
          ),
        ),
      );
    }
  }

  Future<String?> _editDreamText(
    Dream dream, {
    required String initialText,
  }) async {
    final controller = TextEditingController(text: initialText);
    final focus = FocusNode();
    var saving = false;
    String? error;
    final edited = await showV2Sheet<String>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('꿈 원문 수정', style: V2Type.title),
              const SizedBox(height: V2Space.md),
              SizedBox(
                height: 180,
                child: V2CaptureField(
                  controller: controller,
                  focusNode: focus,
                  hint: '기억나는 장면을 적어주세요.',
                  enabled: !saving,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: V2Space.xs),
                Text(
                  error!,
                  style: V2Type.bodySmall.copyWith(color: V2Color.alert),
                ),
              ],
              const SizedBox(height: V2Space.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  V2TextAction(
                    label: '취소',
                    onPressed: saving ? null : () => Navigator.pop(context),
                  ),
                  V2Button(
                    label: '저장',
                    size: V2ButtonSize.compact,
                    loading: saving,
                    loadingLabel: '저장 중',
                    onPressed: saving
                        ? null
                        : () async {
                            final value = controller.text.trim();
                            if (value.isEmpty) return;
                            update(() {
                              saving = true;
                              error = null;
                            });
                            try {
                              await ref
                                  .read(repositoryProvider)
                                  .updateDreamText(dream.id, value);
                              if (context.mounted) {
                                Navigator.pop(context, value);
                              }
                            } on Object {
                              if (context.mounted) {
                                update(() {
                                  saving = false;
                                  error = '원문을 저장하지 못했어요. 입력은 그대로 남아 있어요.';
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    focus.dispose();
    if (edited != null && mounted) showV2Toast(context, '꿈 원문을 수정했어요.');
    return edited;
  }

  Future<DeleteMode?> _confirmDeleteDream({required bool hasDerivedScene}) {
    return showV2Dialog<DeleteMode>(
      context,
      title: hasDerivedScene ? '파생 장면은 어떻게 할까요?' : '꿈을 삭제할까요?',
      body: hasDerivedScene ? '삭제한 꿈은 되돌릴 수 없어요.' : '삭제한 꿈은 되돌릴 수 없어요.',
      actions: (dialogContext) => [
        V2TextAction(
          label: '취소',
          onPressed: () => Navigator.pop(dialogContext),
        ),
        if (hasDerivedScene)
          V2Button.secondary(
            label: '꿈만 삭제하고 장면은 남기기',
            size: V2ButtonSize.compact,
            onPressed: () =>
                Navigator.pop(dialogContext, DeleteMode.keepDerivedContent),
          ),
        V2Button(
          label: hasDerivedScene ? '꿈과 장면 모두 삭제' : '꿈 삭제',
          size: V2ButtonSize.compact,
          onPressed: () =>
              Navigator.pop(dialogContext, DeleteMode.deleteDerivedContent),
        ),
      ],
    );
  }

  Future<void> _deleteDream(String dreamId, DeleteMode mode) async {
    try {
      await ref.read(repositoryProvider).deleteDream(dreamId, mode);
      if (mounted) showV2Toast(context, '꿈을 삭제했어요.');
    } on Object {
      if (mounted) showV2Toast(context, '꿈을 삭제하지 못했어요. 다시 시도해 주세요.');
    }
  }
}

class _DreamCard extends StatelessWidget {
  const _DreamCard({required this.dream, required this.onTap});

  final Dream dream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return V2Pressable(
      onPressed: onTap,
      semanticLabel:
          '${v2SpokenDate(dream.dreamDate)} 꿈, ${_clarityLabel(dream.clarity)}, ${_statusLabel(dream.status)}',
      builder: (context, state) => Transform.scale(
        scale: V2Motion.reduced(context) ? 1 : 1 - .012 * state.depth,
        child: V2Surface(
          kind: V2SurfaceKind.frosted,
          radius: V2Radius.card - 6,
          sink: state.sink,
          hover: state.hover,
          blur: 0,
          chroma: .12,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClarityCluster(clarity: dream.clarity, size: 30),
              const SizedBox(width: V2Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        V2DotMatrix(
                          v2DotDate(dream.dreamDate),
                          pitch: 1.8,
                          color: V2Color.ink2,
                        ),
                        const Spacer(),
                        _StatusPill(status: dream.status),
                      ],
                    ),
                    const SizedBox(height: V2Space.xs),
                    Text(
                      v2KeepAll(dream.rawText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: V2Type.capture.copyWith(fontSize: 16, height: 1.6),
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
}

/// A small packed dot cluster: more dots and a tighter shape for clearer
/// memories. Dream clarity is real data from the engine.
class _ClarityCluster extends StatelessWidget {
  const _ClarityCluster({required this.clarity, required this.size});

  final DreamClarity? clarity;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ClusterPainter(clarity)),
  );
}

class _ClusterPainter extends CustomPainter {
  const _ClusterPainter(this.clarity);

  final DreamClarity? clarity;

  @override
  void paint(Canvas canvas, Size size) {
    final count = switch (clarity) {
      DreamClarity.fragment => 7,
      DreamClarity.partial => 14,
      DreamClarity.vivid => 24,
      null => 4,
    };
    final spread = switch (clarity) {
      DreamClarity.vivid => .9,
      DreamClarity.partial => 1.15,
      _ => 1.45,
    };
    final c = size.center(Offset.zero);
    final pitch = size.width / 9 * spread;
    for (var i = 0; i < count; i++) {
      final a = i * 2.39996;
      final r = pitch * math.sqrt(i + .5);
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      final ink = i < count * .55 && clarity != null;
      canvas.drawCircle(
        p,
        size.width * (ink ? .055 : .045),
        Paint()
          ..color = (ink ? V2Color.inkDot : V2Color.sky500).withValues(
            alpha: .9,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_ClusterPainter old) => old.clarity != clarity;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DreamStatus status;

  @override
  Widget build(BuildContext context) {
    final strong = status == DreamStatus.inManuscript;
    final alert = status == DreamStatus.failed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(V2Radius.chip),
        color: strong
            ? V2Color.sky100
            : alert
            ? const Color(0xFFF6E5E0)
            : V2Color.well,
      ),
      child: Text(
        _statusLabel(status),
        style: V2Type.meta.copyWith(
          letterSpacing: 0,
          fontSize: 11.5,
          color: strong
              ? V2Color.sky800
              : alert
              ? V2Color.alert
              : V2Color.ink2,
        ),
      ),
    );
  }
}

class _ArchiveState extends StatelessWidget {
  const _ArchiveState({
    required this.message,
    required this.action,
    required this.onAction,
  });

  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(V2Space.gutter),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, textAlign: TextAlign.center, style: V2Type.body),
        const SizedBox(height: V2Space.lg),
        V2Button(label: action, onPressed: onAction),
      ],
    ),
  );
}

String _statusLabel(DreamStatus status) => switch (status) {
  DreamStatus.queued => '저장됨 · 생성 전',
  DreamStatus.processing => '처리 중',
  DreamStatus.inManuscript => '원고에 반영',
  DreamStatus.archivedOnly => '기록만',
  DreamStatus.failed => '처리 실패',
};

String _clarityLabel(DreamClarity? clarity) => switch (clarity) {
  DreamClarity.fragment => '흐릿한 기억',
  DreamClarity.partial => '이어진 기억',
  DreamClarity.vivid => '선명한 기억',
  null => '기억 정리 전',
};

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String _monthLabel(DateTime date) {
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
  return '${months[date.month - 1]} ${date.year}';
}

String _recallSummary(Map<String, String> answers) {
  final known = answers.values.where((a) => a.trim().isNotEmpty && a != '모름');
  return known.isEmpty ? '기억 보강 없음' : known.join('  ·  ');
}

Scene? _sceneForDream(List<Scene> scenes, String dreamId) {
  for (final scene in scenes.reversed) {
    if (scene.sourceDreamIds.contains(dreamId)) return scene;
  }
  return null;
}
