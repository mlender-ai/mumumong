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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
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
              Text(dream.rawText, style: Theme.of(context).textTheme.bodyLarge),
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
              if (derivedScene != null)
                Row(
                  children: [
                    Expanded(
                      child: EditorialButton(
                        label: '이 꿈에서 온 장면 다시 쓰기',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Center(
                child: QuietTextButton(label: '꿈 삭제', onPressed: () {}),
              ),
            ],
          ),
        ),
      ),
    );
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
