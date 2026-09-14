import 'enums.dart';
import 'serialization.dart';

class JobProgress {
  const JobProgress({
    required this.dreamId,
    required this.type,
    required this.status,
    required this.attempt,
    required this.stageLabel,
  });

  final String dreamId;
  final JobType type;
  final JobStatus status;
  final int attempt;
  final String stageLabel;

  JobProgress copyWith({
    String? dreamId,
    JobType? type,
    JobStatus? status,
    int? attempt,
    String? stageLabel,
  }) {
    return JobProgress(
      dreamId: dreamId ?? this.dreamId,
      type: type ?? this.type,
      status: status ?? this.status,
      attempt: attempt ?? this.attempt,
      stageLabel: stageLabel ?? this.stageLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'dream_id': dreamId,
    'type': type.databaseValue,
    'status': status.databaseValue,
    'attempt': attempt,
    'stage_label': stageLabel,
  };

  factory JobProgress.fromJson(Map<String, dynamic> json) {
    return JobProgress(
      dreamId: json['dream_id'] as String,
      type: enumFromDatabase(json['type'], JobType.values),
      status: enumFromDatabase(json['status'], JobStatus.values),
      attempt: jsonInt(json['attempt'], 'attempt'),
      stageLabel: json['stage_label'] as String,
    );
  }
}
