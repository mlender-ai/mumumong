import 'enums.dart';
import 'serialization.dart';

class Dream {
  Dream({
    required this.id,
    required this.volumeId,
    required this.dreamDate,
    required this.recordedAt,
    required this.inputMode,
    required this.rawText,
    required Map<String, String> recallAnswers,
    required this.clarity,
    required this.status,
    required this.isBackfill,
  }) : recallAnswers = Map.unmodifiable(recallAnswers);

  static const Object _unset = Object();

  final String id;
  final String? volumeId;
  final DateTime dreamDate;
  final DateTime recordedAt;
  final DreamInputMode inputMode;
  final String rawText;
  final Map<String, String> recallAnswers;
  final DreamClarity? clarity;
  final DreamStatus status;
  final bool isBackfill;

  Dream copyWith({
    String? id,
    Object? volumeId = _unset,
    DateTime? dreamDate,
    DateTime? recordedAt,
    DreamInputMode? inputMode,
    String? rawText,
    Map<String, String>? recallAnswers,
    Object? clarity = _unset,
    DreamStatus? status,
    bool? isBackfill,
  }) {
    return Dream(
      id: id ?? this.id,
      volumeId: identical(volumeId, _unset)
          ? this.volumeId
          : volumeId as String?,
      dreamDate: dreamDate ?? this.dreamDate,
      recordedAt: recordedAt ?? this.recordedAt,
      inputMode: inputMode ?? this.inputMode,
      rawText: rawText ?? this.rawText,
      recallAnswers: recallAnswers ?? this.recallAnswers,
      clarity: identical(clarity, _unset)
          ? this.clarity
          : clarity as DreamClarity?,
      status: status ?? this.status,
      isBackfill: isBackfill ?? this.isBackfill,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'volume_id': volumeId,
    'dream_date': databaseDate(dreamDate),
    'recorded_at': recordedAt.toIso8601String(),
    'input_mode': inputMode.databaseValue,
    'raw_text': rawText,
    'recall_answers': recallAnswers,
    'clarity': clarity?.databaseValue,
    'status': status.databaseValue,
    'is_backfill': isBackfill,
  };

  factory Dream.fromJson(Map<String, dynamic> json) {
    return Dream(
      id: json['id'] as String,
      volumeId: json['volume_id'] as String?,
      dreamDate: jsonDate(json['dream_date'], 'dream_date'),
      recordedAt: jsonDateTime(json['recorded_at'], 'recorded_at'),
      inputMode: enumFromDatabase(json['input_mode'], DreamInputMode.values),
      rawText: json['raw_text'] as String,
      recallAnswers: jsonStringMap(json['recall_answers'], 'recall_answers'),
      clarity: json['clarity'] == null
          ? null
          : enumFromDatabase(json['clarity'], DreamClarity.values),
      status: enumFromDatabase(json['status'], DreamStatus.values),
      isBackfill: json['is_backfill'] as bool,
    );
  }
}
