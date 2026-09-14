import 'serialization.dart';

class ProgressEvent {
  ProgressEvent({
    required this.id,
    required this.volumeId,
    required this.dreamId,
    required this.deltaMu,
    required List<Map<String, dynamic>> reasons,
    required this.createdAt,
  }) : reasons = List.unmodifiable(
         reasons.map((reason) => Map<String, dynamic>.unmodifiable(reason)),
       );

  static const Object _unset = Object();

  final String id;
  final String volumeId;
  final String? dreamId;
  final double deltaMu;
  final List<Map<String, dynamic>> reasons;
  final DateTime createdAt;

  ProgressEvent copyWith({
    String? id,
    String? volumeId,
    Object? dreamId = _unset,
    double? deltaMu,
    List<Map<String, dynamic>>? reasons,
    DateTime? createdAt,
  }) {
    return ProgressEvent(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      dreamId: identical(dreamId, _unset) ? this.dreamId : dreamId as String?,
      deltaMu: deltaMu ?? this.deltaMu,
      reasons: reasons ?? this.reasons,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'volume_id': volumeId,
    'dream_id': dreamId,
    'delta_mu': deltaMu,
    'reasons': reasons,
    'created_at': createdAt.toIso8601String(),
  };

  factory ProgressEvent.fromJson(Map<String, dynamic> json) {
    return ProgressEvent(
      id: json['id'] as String,
      volumeId: json['volume_id'] as String,
      dreamId: json['dream_id'] as String?,
      deltaMu: jsonDouble(json['delta_mu'], 'delta_mu'),
      reasons: jsonObjectList(json['reasons'], 'reasons'),
      createdAt: jsonDateTime(json['created_at'], 'created_at'),
    );
  }
}
