import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_system.dart';
import '../../di/providers.dart';
import '../../domain/model/models.dart';
import '../../domain/repository/mumumong_repository.dart';

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
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('꿈 보관함', style: Theme.of(context).textTheme.displayMedium),
                QuietTextButton(label: '+ 기록', onPressed: widget.onCapture),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (final filter in DreamStatusFilter.values) ...[
                  ChoiceChipEditorial(
                    label: _filterLabel(filter),
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: dreamsAsync.when(
              loading: () => const Center(
                child: MetaText('꿈을 불러오는 중', color: MongColor.ink3),
              ),
              error: (_, _) => const Center(
                child: MetaText('꿈을 불러오지 못했어요.', color: MongColor.ink3),
              ),
              data: (dreams) {
                if (dreams.isEmpty) {
                  return const Center(
                    child: MetaText('아직 기록된 꿈이 없어요.', color: MongColor.ink3),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
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
                          if (index > 0) const SizedBox(height: 26),
                          MetaText(_monthLabel(dream.dreamDate)),
                          const SizedBox(height: 10),
                        ],
                        _ArchiveRow(
                          dream: dream,
                          onTap: () => _showDream(dream),
                        ),
                        if (index < dreams.length - 1) const Divider(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDream(Dream dream) async {
    final repository = ref.read(repositoryProvider);
    final volume = await repository.watchActiveVolume().first;
    final scenes = volume == null
        ? const <Scene>[]
        : await repository.watchScenes(volume.id).first;
    final derivedScene = _sceneForDream(scenes, dream.id);
    if (!mounted) {
      return;
    }

    var rawText = dream.rawText;
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
                Center(
                  child: Container(width: 34, height: 2, color: MongColor.line),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MetaText('DREAM     ${_dateLabel(dream.dreamDate)}'),
                    _ClarityDots(count: _clarityCount(dream.clarity)),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rawText,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    QuietTextButton(
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(derivedScene.title ?? '제목 없는 장면'),
                    subtitle: Text(
                      'SCENE ${scenes.indexOf(derivedScene) + 1}     '
                      '${_statusLabel(dream.status)}',
                    ),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                    onTap: () => Navigator.pop(context),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: MetaText(
                      _statusLabel(dream.status),
                      color: MongColor.ink3,
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
                              : '처리 이어가기',
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            unawaited(_resumeProcessing(dream));
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Center(
                  child: QuietTextButton(
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
  }

  Future<String?> _editDreamText(
    Dream dream, {
    required String initialText,
  }) async {
    final controller = TextEditingController(text: initialText);
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MongColor.paper,
        title: const Text('꿈 원문 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(hintText: '기억나는 장면을 적어주세요.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (edited == null || edited == initialText || !mounted) return null;
    try {
      await ref.read(repositoryProvider).updateDreamText(dream.id, edited);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('꿈 원문을 수정했어요.')));
      }
      return edited;
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('원문을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
      return null;
    }
  }

  Future<void> _resumeProcessing(Dream dream) async {
    if (!mounted) return;
    final repository = ref.read(repositoryProvider);
    final engine = ref.read(engineClientProvider);
    try {
      if (dream.status != DreamStatus.processing) {
        await repository.answerRecall(dream.id, dream.recallAnswers);
      }
      if (dream.status == DreamStatus.failed) {
        await engine.retry(dream.id);
      } else {
        await engine.enqueue(dream.id, dream.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('장면 처리를 이어갈게요.')));
      }
      final result = await engine
          .watch(dream.id)
          .firstWhere(
            (progress) =>
                progress.status == JobStatus.failed ||
                (progress.status == JobStatus.done &&
                    (progress.type == JobType.commit ||
                        progress.type == JobType.remember)),
          )
          .timeout(const Duration(minutes: 3));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == JobStatus.failed
                ? '장면을 만들지 못했어요. 다시 시도해 주세요.'
                : '새 장면이 원고에 들어갔어요.',
          ),
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('처리 상태를 확인하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  Future<DeleteMode?> _confirmDeleteDream({required bool hasDerivedScene}) {
    if (!hasDerivedScene) {
      return showDialog<DeleteMode>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: MongColor.paper,
          title: const Text('꿈을 삭제할까요?'),
          content: const Text('삭제한 꿈은 되돌릴 수 없어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, DeleteMode.deleteDerivedContent),
              child: const Text('꿈 삭제'),
            ),
          ],
        ),
      );
    }
    return showDialog<DeleteMode>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: MongColor.paper,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 62, child: MetaText(_dateLabel(dream.dreamDate))),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ClarityDots(count: _clarityCount(dream.clarity)),
                      const SizedBox(width: 12),
                      MetaText(_statusLabel(dream.status)),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12, top: 12),
              child: Icon(Icons.arrow_forward, size: 17, color: MongColor.ink3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClarityDots extends StatelessWidget {
  const _ClarityDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < count ? MongColor.ink : MongColor.line,
            ),
          ),
      ],
    );
  }
}

String _filterLabel(DreamStatusFilter filter) => switch (filter) {
  DreamStatusFilter.all => '전체',
  DreamStatusFilter.inManuscript => '원고에 반영',
  DreamStatusFilter.archivedOnly => '기록만',
};

String _statusLabel(DreamStatus status) => switch (status) {
  DreamStatus.queued => '처리 대기',
  DreamStatus.processing => '처리 중',
  DreamStatus.inManuscript => '원고에 반영',
  DreamStatus.archivedOnly => '기록만',
  DreamStatus.failed => '처리 실패',
};

int _clarityCount(DreamClarity? clarity) => switch (clarity) {
  DreamClarity.fragment => 1,
  DreamClarity.partial => 2,
  DreamClarity.vivid => 3,
  null => 0,
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
