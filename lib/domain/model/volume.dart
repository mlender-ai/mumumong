import 'enums.dart';
import 'serialization.dart';

class Volume {
  Volume({
    required this.id,
    required this.volNo,
    required this.title,
    required this.format,
    required this.adaptation,
    required this.style,
    required this.narrativeVoice,
    required this.status,
    required this.progressMu,
    required this.targetMu,
    required Map<String, double> genreProfile,
    required this.coverMotifId,
    required this.prologueSceneId,
  }) : genreProfile = Map.unmodifiable(genreProfile);

  static const Object _unset = Object();

  final String id;
  final int volNo;
  final String? title;
  final VolumeFormat format;
  final AdaptationLevel adaptation;
  final WritingStyle style;
  final NarrativeVoice narrativeVoice;
  final VolumeStatus status;
  final double progressMu;
  final double targetMu;
  final Map<String, double> genreProfile;
  final String? coverMotifId;
  final String? prologueSceneId;

  Volume copyWith({
    String? id,
    int? volNo,
    Object? title = _unset,
    VolumeFormat? format,
    AdaptationLevel? adaptation,
    WritingStyle? style,
    NarrativeVoice? narrativeVoice,
    VolumeStatus? status,
    double? progressMu,
    double? targetMu,
    Map<String, double>? genreProfile,
    Object? coverMotifId = _unset,
    Object? prologueSceneId = _unset,
  }) {
    return Volume(
      id: id ?? this.id,
      volNo: volNo ?? this.volNo,
      title: identical(title, _unset) ? this.title : title as String?,
      format: format ?? this.format,
      adaptation: adaptation ?? this.adaptation,
      style: style ?? this.style,
      narrativeVoice: narrativeVoice ?? this.narrativeVoice,
      status: status ?? this.status,
      progressMu: progressMu ?? this.progressMu,
      targetMu: targetMu ?? this.targetMu,
      genreProfile: genreProfile ?? this.genreProfile,
      coverMotifId: identical(coverMotifId, _unset)
          ? this.coverMotifId
          : coverMotifId as String?,
      prologueSceneId: identical(prologueSceneId, _unset)
          ? this.prologueSceneId
          : prologueSceneId as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vol_no': volNo,
    'title': title,
    'format': format.databaseValue,
    'adaptation': adaptation.databaseValue,
    'style': style.databaseValue,
    'narrative_voice': narrativeVoice.databaseValue,
    'status': status.databaseValue,
    'progress_mu': progressMu,
    'target_mu': targetMu,
    'genre_profile': genreProfile,
    'cover_motif_id': coverMotifId,
    'prologue_scene_id': prologueSceneId,
  };

  factory Volume.fromJson(Map<String, dynamic> json) {
    return Volume(
      id: json['id'] as String,
      volNo: jsonInt(json['vol_no'], 'vol_no'),
      title: json['title'] as String?,
      format: enumFromDatabase(json['format'], VolumeFormat.values),
      adaptation: enumFromDatabase(json['adaptation'], AdaptationLevel.values),
      style: enumFromDatabase(json['style'], WritingStyle.values),
      narrativeVoice: enumFromDatabase(
        json['narrative_voice'],
        NarrativeVoice.values,
      ),
      status: enumFromDatabase(json['status'], VolumeStatus.values),
      progressMu: jsonDouble(json['progress_mu'], 'progress_mu'),
      targetMu: jsonDouble(json['target_mu'], 'target_mu'),
      genreProfile: jsonDoubleMap(json['genre_profile'], 'genre_profile'),
      coverMotifId: json['cover_motif_id'] as String?,
      prologueSceneId: json['prologue_scene_id'] as String?,
    );
  }
}
