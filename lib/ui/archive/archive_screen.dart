import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../capture/capture_flow.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../reader/reader_screen.dart';
import '../shared/content_state.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key, required this.onCapture});

  final VoidCallback onCapture;

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  DreamStatusFilter _filter = DreamStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final dreamsAsync = ref.watch(dreamsProvider(_filter));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: MongPageHeader(
                  title: '꿈 보관함',
                  description: dreamsAsync.hasValue
                      ? '기록된 꿈 ${dreamsAsync.requireValue.length}'
                      : null,
                  trailing: MongIconButton(
                    icon: Icons.add_rounded,
                    semanticLabel: '꿈 기록하기',
                    onPressed: widget.onCapture,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: MongSpace.screen,
                  ),
                  child: Row(
                    children: [
                      for (final filter in DreamStatusFilter.values) ...[
                        ChoiceChipEditorial(
                          label: _filterLabel(filter),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                        const SizedBox(width: MongSpace.xs),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: MongSpace.lg)),
              const SliverToBoxAdapter(child: OfflineNotice()),
              dreamsAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ContentState(message: '꿈을 불러오는 중'),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ContentState(
                    message: '꿈을 불러오지 못했어요. 저장한 기록을 다시 확인해 보세요.',
                    action: '다시 불러오기',
                    onAction: () => ref.invalidate(dreamsProvider(_filter)),
                  ),
                ),
                data: (dreams) {
                  if (dreams.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: ContentState(
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
                    padding: const EdgeInsets.fromLTRB(
                      MongSpace.screen,
                      0,
                      MongSpace.screen,
                      MongSpace.xl,
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
                                const SizedBox(height: MongSpace.lg),
                              MetaText(_monthLabel(dream.dreamDate)),
                              const SizedBox(height: MongSpace.md),
                            ],
                            _ArchiveRow(
                              dream: dream,
                              onTap: () => _showDream(dream),
                            ),
                            if (index < dreams.length - 1) const Divider(),
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
    );
  }

  Future<void> _showDream(Dream dream) async {
    try {
      await _showDreamDetails(dream);
    } on Object {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('기록을 불러오지 못했어요'),
          content: const Text('저장한 꿈은 지우지 않았어요. 다시 불러와 주세요.'),
          actions: [
            MongButton.ghost(
              label: '닫기',
              onPressed: () => Navigator.pop(context),
            ),
            MongButton.ghost(
              label: '다시 불러오기',
              onPressed: () {
                Navigator.pop(context);
                unawaited(_showDream(dream));
              },
            ),
          ],
        ),
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
    if (!mounted) {
      return;
    }

    var rawText = dream.rawText;
    var openReader = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .5,
          maxChildSize: .94,
          builder: (context, controller) => SafeArea(
            top: false,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                const MongSheetHandle(),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MetaText('DREAM     ${_dateLabel(dream.dreamDate)}'),
                    MetaText(_clarityLabel(dream.clarity)),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rawText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    MongButton.ghost(
                      label: '원문 수정',
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
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Divider(),
                ),
                const MetaText('기억 보강'),
                const SizedBox(height: 12),
                Text(
                  _recallSummary(dream.recallAnswers),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                const MetaText('파생 장면'),
                const SizedBox(height: 12),
                if (derivedScene != null)
                  MongListRow(
                    title: derivedScene.title ?? '제목 없는 장면',
                    subtitle:
                        'SCENE ${scenes.indexOf(derivedScene) + 1}     '
                        '${_statusLabel(dream.status)}',
                    onTap: () {
                      openReader = true;
                      Navigator.pop(context);
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: MetaText(
                      _statusLabel(dream.status),
                      color: context.metaInk,
                    ),
                  ),
                const Divider(),
                const SizedBox(height: 8),
                if (derivedScene == null &&
                    dream.status != DreamStatus.archivedOnly)
                  Row(
                    children: [
                      Expanded(
                        child: EditorialButton(
                          label: dream.status == DreamStatus.failed
                              ? '다시 처리'
                              : dream.status == DreamStatus.queued
                              ? '장면 만들기'
                              : '처리 이어가기',
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            Navigator.of(this.context).push(
                              quietPageRoute(
                                CaptureFlow(
                                  dreamNumber:
                                      allDreams.length -
                                      allDreams.indexWhere(
                                        (d) => d.id == dream.id,
                                      ),
                                  sceneNumber: scenes.length + 1,
                                  savedDream: dream,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Center(
                  child: MongButton.ghost(
                    label: '꿈 삭제',
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
        quietPageRoute(
          ReaderScreen(
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
    var saving = false;
    String? error;
    final edited = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            backgroundColor: context.raised,
            title: const Text('꿈 원문 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '기억나는 장면을 적어주세요.',
                    ),
                  ),
                  if (error != null) Text(error!),
                ],
              ),
            ),
            actions: [
              MongButton.ghost(
                label: '취소',
                onPressed: saving ? null : () => Navigator.pop(context),
              ),
              MongButton.ghost(
                label: saving ? '저장 중' : '저장',
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
                          if (context.mounted) Navigator.pop(context, value);
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
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (edited != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('꿈 원문을 수정했어요.')));
    }
    return edited;
  }

  Future<DeleteMode?> _confirmDeleteDream({required bool hasDerivedScene}) {
    if (!hasDerivedScene) {
      return showDialog<DeleteMode>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.raised,
          title: const Text('꿈을 삭제할까요?'),
          content: const Text('삭제한 꿈은 되돌릴 수 없어요.'),
          actions: [
            MongButton.ghost(
              label: '취소',
              onPressed: () => Navigator.pop(context),
            ),
            MongButton.ghost(
              label: '꿈 삭제',
              onPressed: () =>
                  Navigator.pop(context, DeleteMode.deleteDerivedContent),
            ),
          ],
        ),
      );
    }
    return showDialog<DeleteMode>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: context.raised,
        title: const Text('파생 장면은 어떻게 할까요?'),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, DeleteMode.deleteDerivedContent),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('꿈과 장면 모두 삭제'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(context, DeleteMode.keepDerivedContent),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('꿈만 삭제하고 장면은 남기기'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('취소'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDream(String dreamId, DeleteMode mode) async {
    try {
      await ref.read(repositoryProvider).deleteDream(dreamId, mode);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('꿈을 삭제했어요.')));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('꿈을 삭제하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.dream, required this.onTap});

  final Dream dream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stackDate = MediaQuery.textScalerOf(context).scale(12) > 15;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MongSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stackDate) ...[
              MetaText(_dateLabel(dream.dreamDate)),
              const SizedBox(height: MongSpace.xs),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!stackDate)
                  SizedBox(
                    width: 62,
                    child: MetaText(_dateLabel(dream.dreamDate)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dream.rawText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: MongSpace.xs),
                      Wrap(
                        spacing: MongSpace.sm,
                        runSpacing: MongSpace.xxs,
                        children: [
                          MetaText(_clarityLabel(dream.clarity)),
                          MetaText(_statusLabel(dream.status)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: MongSpace.sm,
                    top: MongSpace.sm,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: context.metaInk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _filterLabel(DreamStatusFilter filter) => switch (filter) {
  DreamStatusFilter.all => '전체',
  DreamStatusFilter.inManuscript => '원고에 반영',
  DreamStatusFilter.archivedOnly => '기록만',
};

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

String _dateLabel(DateTime date) => '${date.month}월 ${date.day}일';

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String _monthLabel(DateTime date) {
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _recallSummary(Map<String, String> answers) {
  final known = answers.values.where(
    (answer) => answer.trim().isNotEmpty && answer != '모름',
  );
  return known.isEmpty ? '기억 보강 없음' : known.join('     ');
}

Scene? _sceneForDream(List<Scene> scenes, String dreamId) {
  for (final scene in scenes.reversed) {
    if (scene.sourceDreamIds.contains(dreamId)) {
      return scene;
    }
  }
  return null;
}
