import 'package:flutter/material.dart';

import '../../core/design/design_system.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({
    super.key,
    required this.includeNewDream,
    required this.onCapture,
  });

  final bool includeNewDream;
  final VoidCallback onCapture;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    final dreams = <_DreamEntry>[
      if (widget.includeNewDream)
        const _DreamEntry(
          date: '9월 13일',
          firstLine: '복도 바닥에 물이 차 있었고 끝에 붉은 문이…',
          clarity: 3,
          status: '원고에 반영',
        ),
      const _DreamEntry(
        date: '9월 11일',
        firstLine: '비어 있는 학교 복도를 계속 걸었다.',
        clarity: 2,
        status: '원고에 반영',
      ),
      const _DreamEntry(
        date: '9월 7일',
        firstLine: '전화기에서 누군가의 숨소리만 들렸다.',
        clarity: 2,
        status: '원고에 반영',
      ),
      const _DreamEntry(
        date: '9월 3일',
        firstLine: '이름 모를 역에서 우산을 든 사람을 봤다.',
        clarity: 3,
        status: '원고에 반영',
      ),
      const _DreamEntry(
        date: '9월 1일',
        firstLine: '작은 열쇠가 손바닥 위에 있었다.',
        clarity: 1,
        status: '기록만',
      ),
      const _DreamEntry(
        date: '8월 28일',
        firstLine: '버스의 맨 뒷자리에 혼자 앉아 있었다.',
        clarity: 2,
        status: '원고에 반영',
      ),
    ];
    final filtered = dreams.where((dream) {
      if (_filter == '전체') return true;
      if (_filter == '원고에 반영') return dream.status == '원고에 반영';
      return dream.status == '기록만';
    }).toList();

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
                for (final filter in const ['전체', '원고에 반영', '기록만']) ...[
                  ChoiceChipEditorial(
                    label: filter,
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: MetaText('SEPTEMBER 2026'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final dream = filtered[index];
                return _ArchiveRow(
                  dream: dream,
                  onTap: () => _showDream(dream),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDream(_DreamEntry dream) {
    showModalBottomSheet<void>(
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
                  MetaText('DREAM     ${dream.date}'),
                  _ClarityDots(count: dream.clarity),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                dream.firstLine.replaceAll('…', ''),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '복도 바닥의 물은 잠잠했고, 끝의 문에서만 붉은 빛이 났다. '
                '얼굴이 보이지 않는 사람이 우산을 든 채 그 옆에 서 있었다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Divider(),
              ),
              const MetaText('기억 보강'),
              const SizedBox(height: 12),
              Text(
                '어두움     모르는 사람     불안',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              const MetaText('파생 장면'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('문 밖의 여자'),
                subtitle: const Text('SCENE 12     원고에 반영'),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () => Navigator.pop(context),
              ),
              const Divider(),
              const SizedBox(height: 8),
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

class _DreamEntry {
  const _DreamEntry({
    required this.date,
    required this.firstLine,
    required this.clarity,
    required this.status,
  });

  final String date;
  final String firstLine;
  final int clarity;
  final String status;
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.dream, required this.onTap});

  final _DreamEntry dream;
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
            SizedBox(width: 62, child: MetaText(dream.date)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dream.firstLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ClarityDots(count: dream.clarity),
                      const SizedBox(width: 12),
                      MetaText(dream.status),
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
        for (var i = 0; i < 3; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < count ? MongColor.ink : MongColor.line,
            ),
          ),
      ],
    );
  }
}
