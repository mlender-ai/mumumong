// Small V2 text helpers shared by screens. Never formats dream text.
import '../../domain/model/models.dart';

export '../design/keep_all.dart';

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

String v2DotDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

String v2Weekday(DateTime date) => _weekdays[date.weekday - 1];

String v2SpokenDate(DateTime date) => '${date.month}월 ${date.day}일';

String v2Volume(Volume volume) =>
    'VOL.${volume.volNo.toString().padLeft(2, '0')}';

int v2Percent(ProgressEvent? event, double targetMu) {
  if (event == null || targetMu <= 0) return 0;
  return (event.deltaMu / targetMu * 100).round();
}

/// "+4%  ·  새 장면  ·  보강 2" from recorded reasons only.
String v2ProgressReason(ProgressEvent event, double targetMu) {
  final percent = v2Percent(event, targetMu);
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

String v2PendingSummary(List<Dream> dreams) => [
  for (final (status, label) in [
    (DreamStatus.queued, '생성 전'),
    (DreamStatus.processing, '진행 중'),
    (DreamStatus.failed, '재시도'),
  ])
    if (dreams.any((dream) => dream.status == status))
      '${dreams.where((dream) => dream.status == status).length}개 $label',
].join(' · ');
