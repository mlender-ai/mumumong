import 'enums.dart';
import 'serialization.dart';

class StoryEntity {
  StoryEntity({
    required this.id,
    required this.volumeId,
    required this.type,
    required this.roleName,
    required this.description,
    required List<String> aliases,
    required this.status,
    required this.mentionCount,
  }) : aliases = List.unmodifiable(aliases);

  static const Object _unset = Object();

  final String id;
  final String volumeId;
  final String type;
  final String roleName;
  final String? description;
  final List<String> aliases;
  final StoryEntityStatus status;
  final int mentionCount;

  StoryEntity copyWith({
    String? id,
    String? volumeId,
    String? type,
    String? roleName,
    Object? description = _unset,
    List<String>? aliases,
    StoryEntityStatus? status,
    int? mentionCount,
  }) {
    return StoryEntity(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      type: type ?? this.type,
      roleName: roleName ?? this.roleName,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      aliases: aliases ?? this.aliases,
      status: status ?? this.status,
      mentionCount: mentionCount ?? this.mentionCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'volume_id': volumeId,
    'type': type,
    'role_name': roleName,
    'description': description,
    'aliases': aliases,
    'status': status.databaseValue,
    'mention_count': mentionCount,
  };

  factory StoryEntity.fromJson(Map<String, dynamic> json) {
    return StoryEntity(
      id: json['id'] as String,
      volumeId: json['volume_id'] as String,
      type: json['type'] as String,
      roleName: json['role_name'] as String,
      description: json['description'] as String?,
      aliases: jsonStringList(json['aliases'], 'aliases'),
      status: enumFromDatabase(json['status'], StoryEntityStatus.values),
      mentionCount: jsonInt(json['mention_count'], 'mention_count'),
    );
  }
}
