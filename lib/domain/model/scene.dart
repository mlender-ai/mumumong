import 'enums.dart';
import 'serialization.dart';

class Scene {
  Scene({
    required this.id,
    required this.volumeId,
    required this.orderKey,
    required this.chapterNo,
    required this.kind,
    required this.placement,
    required this.title,
    required List<String> sourceDreamIds,
    required this.openImage,
  }) : sourceDreamIds = List.unmodifiable(sourceDreamIds);

  static const Object _unset = Object();

  final String id;
  final String volumeId;
  final String orderKey;
  final int? chapterNo;
  final SceneKind kind;
  final PlacementKind placement;
  final String? title;
  final List<String> sourceDreamIds;
  final String? openImage;

  Scene copyWith({
    String? id,
    String? volumeId,
    String? orderKey,
    Object? chapterNo = _unset,
    SceneKind? kind,
    PlacementKind? placement,
    Object? title = _unset,
    List<String>? sourceDreamIds,
    Object? openImage = _unset,
  }) {
    return Scene(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      orderKey: orderKey ?? this.orderKey,
      chapterNo: identical(chapterNo, _unset)
          ? this.chapterNo
          : chapterNo as int?,
      kind: kind ?? this.kind,
      placement: placement ?? this.placement,
      title: identical(title, _unset) ? this.title : title as String?,
      sourceDreamIds: sourceDreamIds ?? this.sourceDreamIds,
      openImage: identical(openImage, _unset)
          ? this.openImage
          : openImage as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'volume_id': volumeId,
    'order_key': orderKey,
    'chapter_no': chapterNo,
    'kind': kind.databaseValue,
    'placement': placement.databaseValue,
    'title': title,
    'source_dream_ids': sourceDreamIds,
    'open_image': openImage,
  };

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      volumeId: json['volume_id'] as String,
      orderKey: json['order_key'] as String,
      chapterNo: json['chapter_no'] == null
          ? null
          : jsonInt(json['chapter_no'], 'chapter_no'),
      kind: enumFromDatabase(json['kind'], SceneKind.values),
      placement: enumFromDatabase(json['placement'], PlacementKind.values),
      title: json['title'] as String?,
      sourceDreamIds: jsonStringList(
        json['source_dream_ids'],
        'source_dream_ids',
      ),
      openImage: json['open_image'] as String?,
    );
  }
}
