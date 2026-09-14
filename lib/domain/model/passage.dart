import 'enums.dart';
import 'serialization.dart';

class Passage {
  Passage({
    required this.id,
    required this.sceneId,
    required this.orderKey,
    required this.text,
    required this.origin,
    required this.sourceDreamId,
    required List<String> sourceElementIds,
    required this.cReason,
    required this.originalText,
    required this.locked,
    required this.firstReadAt,
  }) : sourceElementIds = List.unmodifiable(sourceElementIds) {
    if (origin == PassageOrigin.dream && sourceElementIds.isEmpty) {
      throw ArgumentError.value(
        sourceElementIds,
        'sourceElementIds',
        'a dream-origin passage requires at least one source element',
      );
    }
    if (origin == PassageOrigin.user && !locked) {
      throw ArgumentError.value(
        locked,
        'locked',
        'a user-origin passage must be locked',
      );
    }
  }

  static const Object _unset = Object();

  final String id;
  final String sceneId;
  final String orderKey;
  final String text;
  final PassageOrigin origin;
  final String? sourceDreamId;
  final List<String> sourceElementIds;
  final String? cReason;
  final String? originalText;
  final bool locked;
  final DateTime? firstReadAt;

  Passage copyWith({
    String? id,
    String? sceneId,
    String? orderKey,
    String? text,
    PassageOrigin? origin,
    Object? sourceDreamId = _unset,
    List<String>? sourceElementIds,
    Object? cReason = _unset,
    Object? originalText = _unset,
    bool? locked,
    Object? firstReadAt = _unset,
  }) {
    return Passage(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      orderKey: orderKey ?? this.orderKey,
      text: text ?? this.text,
      origin: origin ?? this.origin,
      sourceDreamId: identical(sourceDreamId, _unset)
          ? this.sourceDreamId
          : sourceDreamId as String?,
      sourceElementIds: sourceElementIds ?? this.sourceElementIds,
      cReason: identical(cReason, _unset) ? this.cReason : cReason as String?,
      originalText: identical(originalText, _unset)
          ? this.originalText
          : originalText as String?,
      locked: locked ?? this.locked,
      firstReadAt: identical(firstReadAt, _unset)
          ? this.firstReadAt
          : firstReadAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scene_id': sceneId,
    'order_key': orderKey,
    'text': text,
    'origin': origin.databaseValue,
    'source_dream_id': sourceDreamId,
    'source_element_ids': sourceElementIds,
    'c_reason': cReason,
    'original_text': originalText,
    'locked': locked,
    'first_read_at': firstReadAt?.toIso8601String(),
  };

  factory Passage.fromJson(Map<String, dynamic> json) {
    return Passage(
      id: json['id'] as String,
      sceneId: json['scene_id'] as String,
      orderKey: json['order_key'] as String,
      text: json['text'] as String,
      origin: enumFromDatabase(json['origin'], PassageOrigin.values),
      sourceDreamId: json['source_dream_id'] as String?,
      sourceElementIds: jsonStringList(
        json['source_element_ids'],
        'source_element_ids',
      ),
      cReason: json['c_reason'] as String?,
      originalText: json['original_text'] as String?,
      locked: json['locked'] as bool,
      firstReadAt: json['first_read_at'] == null
          ? null
          : jsonDateTime(json['first_read_at'], 'first_read_at'),
    );
  }
}
