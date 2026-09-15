// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VolumesTable extends Volumes
    with TableInfo<$VolumesTable, LocalVolumeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VolumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUserId),
  );
  static const VerificationMeta _volNoMeta = const VerificationMeta('volNo');
  @override
  late final GeneratedColumn<int> volNo = GeneratedColumn<int>(
    'vol_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adaptationMeta = const VerificationMeta(
    'adaptation',
  );
  @override
  late final GeneratedColumn<String> adaptation = GeneratedColumn<String>(
    'adaptation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _narrativeVoiceMeta = const VerificationMeta(
    'narrativeVoice',
  );
  @override
  late final GeneratedColumn<String> narrativeVoice = GeneratedColumn<String>(
    'narrative_voice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMuMeta = const VerificationMeta(
    'targetMu',
  );
  @override
  late final GeneratedColumn<double> targetMu = GeneratedColumn<double>(
    'target_mu',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMuMeta = const VerificationMeta(
    'progressMu',
  );
  @override
  late final GeneratedColumn<double> progressMu = GeneratedColumn<double>(
    'progress_mu',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreProfileMeta = const VerificationMeta(
    'genreProfile',
  );
  @override
  late final GeneratedColumn<String> genreProfile = GeneratedColumn<String>(
    'genre_profile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _genreDirectiveMeta = const VerificationMeta(
    'genreDirective',
  );
  @override
  late final GeneratedColumn<String> genreDirective = GeneratedColumn<String>(
    'genre_directive',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{"mode":"keep"}'),
  );
  static const VerificationMeta _coverMotifIdMeta = const VerificationMeta(
    'coverMotifId',
  );
  @override
  late final GeneratedColumn<String> coverMotifId = GeneratedColumn<String>(
    'cover_motif_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverSeedMeta = const VerificationMeta(
    'coverSeed',
  );
  @override
  late final GeneratedColumn<int> coverSeed = GeneratedColumn<int>(
    'cover_seed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNoteMeta = const VerificationMeta(
    'authorNote',
  );
  @override
  late final GeneratedColumn<String> authorNote = GeneratedColumn<String>(
    'author_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prologueSceneIdMeta = const VerificationMeta(
    'prologueSceneId',
  );
  @override
  late final GeneratedColumn<String> prologueSceneId = GeneratedColumn<String>(
    'prologue_scene_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    userId,
    volNo,
    title,
    format,
    adaptation,
    style,
    narrativeVoice,
    status,
    targetMu,
    progressMu,
    genreProfile,
    genreDirective,
    coverMotifId,
    coverSeed,
    authorNote,
    prologueSceneId,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'volumes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVolumeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('vol_no')) {
      context.handle(
        _volNoMeta,
        volNo.isAcceptableOrUnknown(data['vol_no']!, _volNoMeta),
      );
    } else if (isInserting) {
      context.missing(_volNoMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('adaptation')) {
      context.handle(
        _adaptationMeta,
        adaptation.isAcceptableOrUnknown(data['adaptation']!, _adaptationMeta),
      );
    } else if (isInserting) {
      context.missing(_adaptationMeta);
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('narrative_voice')) {
      context.handle(
        _narrativeVoiceMeta,
        narrativeVoice.isAcceptableOrUnknown(
          data['narrative_voice']!,
          _narrativeVoiceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_narrativeVoiceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('target_mu')) {
      context.handle(
        _targetMuMeta,
        targetMu.isAcceptableOrUnknown(data['target_mu']!, _targetMuMeta),
      );
    } else if (isInserting) {
      context.missing(_targetMuMeta);
    }
    if (data.containsKey('progress_mu')) {
      context.handle(
        _progressMuMeta,
        progressMu.isAcceptableOrUnknown(data['progress_mu']!, _progressMuMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMuMeta);
    }
    if (data.containsKey('genre_profile')) {
      context.handle(
        _genreProfileMeta,
        genreProfile.isAcceptableOrUnknown(
          data['genre_profile']!,
          _genreProfileMeta,
        ),
      );
    }
    if (data.containsKey('genre_directive')) {
      context.handle(
        _genreDirectiveMeta,
        genreDirective.isAcceptableOrUnknown(
          data['genre_directive']!,
          _genreDirectiveMeta,
        ),
      );
    }
    if (data.containsKey('cover_motif_id')) {
      context.handle(
        _coverMotifIdMeta,
        coverMotifId.isAcceptableOrUnknown(
          data['cover_motif_id']!,
          _coverMotifIdMeta,
        ),
      );
    }
    if (data.containsKey('cover_seed')) {
      context.handle(
        _coverSeedMeta,
        coverSeed.isAcceptableOrUnknown(data['cover_seed']!, _coverSeedMeta),
      );
    }
    if (data.containsKey('author_note')) {
      context.handle(
        _authorNoteMeta,
        authorNote.isAcceptableOrUnknown(data['author_note']!, _authorNoteMeta),
      );
    }
    if (data.containsKey('prologue_scene_id')) {
      context.handle(
        _prologueSceneIdMeta,
        prologueSceneId.isAcceptableOrUnknown(
          data['prologue_scene_id']!,
          _prologueSceneIdMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalVolumeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVolumeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      volNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vol_no'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      adaptation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adaptation'],
      )!,
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      narrativeVoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrative_voice'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      targetMu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_mu'],
      )!,
      progressMu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_mu'],
      )!,
      genreProfile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_profile'],
      )!,
      genreDirective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_directive'],
      )!,
      coverMotifId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_motif_id'],
      ),
      coverSeed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_seed'],
      ),
      authorNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_note'],
      ),
      prologueSceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prologue_scene_id'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $VolumesTable createAlias(String alias) {
    return $VolumesTable(attachedDatabase, alias);
  }
}

class LocalVolumeRow extends DataClass implements Insertable<LocalVolumeRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final int volNo;
  final String? title;
  final String format;
  final String adaptation;
  final String style;
  final String narrativeVoice;
  final String status;
  final double targetMu;
  final double progressMu;
  final String genreProfile;
  final String genreDirective;
  final String? coverMotifId;
  final int? coverSeed;
  final String? authorNote;
  final String? prologueSceneId;
  final DateTime? completedAt;
  const LocalVolumeRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.volNo,
    this.title,
    required this.format,
    required this.adaptation,
    required this.style,
    required this.narrativeVoice,
    required this.status,
    required this.targetMu,
    required this.progressMu,
    required this.genreProfile,
    required this.genreDirective,
    this.coverMotifId,
    this.coverSeed,
    this.authorNote,
    this.prologueSceneId,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    map['vol_no'] = Variable<int>(volNo);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['format'] = Variable<String>(format);
    map['adaptation'] = Variable<String>(adaptation);
    map['style'] = Variable<String>(style);
    map['narrative_voice'] = Variable<String>(narrativeVoice);
    map['status'] = Variable<String>(status);
    map['target_mu'] = Variable<double>(targetMu);
    map['progress_mu'] = Variable<double>(progressMu);
    map['genre_profile'] = Variable<String>(genreProfile);
    map['genre_directive'] = Variable<String>(genreDirective);
    if (!nullToAbsent || coverMotifId != null) {
      map['cover_motif_id'] = Variable<String>(coverMotifId);
    }
    if (!nullToAbsent || coverSeed != null) {
      map['cover_seed'] = Variable<int>(coverSeed);
    }
    if (!nullToAbsent || authorNote != null) {
      map['author_note'] = Variable<String>(authorNote);
    }
    if (!nullToAbsent || prologueSceneId != null) {
      map['prologue_scene_id'] = Variable<String>(prologueSceneId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  VolumesCompanion toCompanion(bool nullToAbsent) {
    return VolumesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      volNo: Value(volNo),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      format: Value(format),
      adaptation: Value(adaptation),
      style: Value(style),
      narrativeVoice: Value(narrativeVoice),
      status: Value(status),
      targetMu: Value(targetMu),
      progressMu: Value(progressMu),
      genreProfile: Value(genreProfile),
      genreDirective: Value(genreDirective),
      coverMotifId: coverMotifId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverMotifId),
      coverSeed: coverSeed == null && nullToAbsent
          ? const Value.absent()
          : Value(coverSeed),
      authorNote: authorNote == null && nullToAbsent
          ? const Value.absent()
          : Value(authorNote),
      prologueSceneId: prologueSceneId == null && nullToAbsent
          ? const Value.absent()
          : Value(prologueSceneId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory LocalVolumeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVolumeRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      volNo: serializer.fromJson<int>(json['volNo']),
      title: serializer.fromJson<String?>(json['title']),
      format: serializer.fromJson<String>(json['format']),
      adaptation: serializer.fromJson<String>(json['adaptation']),
      style: serializer.fromJson<String>(json['style']),
      narrativeVoice: serializer.fromJson<String>(json['narrativeVoice']),
      status: serializer.fromJson<String>(json['status']),
      targetMu: serializer.fromJson<double>(json['targetMu']),
      progressMu: serializer.fromJson<double>(json['progressMu']),
      genreProfile: serializer.fromJson<String>(json['genreProfile']),
      genreDirective: serializer.fromJson<String>(json['genreDirective']),
      coverMotifId: serializer.fromJson<String?>(json['coverMotifId']),
      coverSeed: serializer.fromJson<int?>(json['coverSeed']),
      authorNote: serializer.fromJson<String?>(json['authorNote']),
      prologueSceneId: serializer.fromJson<String?>(json['prologueSceneId']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'volNo': serializer.toJson<int>(volNo),
      'title': serializer.toJson<String?>(title),
      'format': serializer.toJson<String>(format),
      'adaptation': serializer.toJson<String>(adaptation),
      'style': serializer.toJson<String>(style),
      'narrativeVoice': serializer.toJson<String>(narrativeVoice),
      'status': serializer.toJson<String>(status),
      'targetMu': serializer.toJson<double>(targetMu),
      'progressMu': serializer.toJson<double>(progressMu),
      'genreProfile': serializer.toJson<String>(genreProfile),
      'genreDirective': serializer.toJson<String>(genreDirective),
      'coverMotifId': serializer.toJson<String?>(coverMotifId),
      'coverSeed': serializer.toJson<int?>(coverSeed),
      'authorNote': serializer.toJson<String?>(authorNote),
      'prologueSceneId': serializer.toJson<String?>(prologueSceneId),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  LocalVolumeRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? volNo,
    Value<String?> title = const Value.absent(),
    String? format,
    String? adaptation,
    String? style,
    String? narrativeVoice,
    String? status,
    double? targetMu,
    double? progressMu,
    String? genreProfile,
    String? genreDirective,
    Value<String?> coverMotifId = const Value.absent(),
    Value<int?> coverSeed = const Value.absent(),
    Value<String?> authorNote = const Value.absent(),
    Value<String?> prologueSceneId = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => LocalVolumeRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    volNo: volNo ?? this.volNo,
    title: title.present ? title.value : this.title,
    format: format ?? this.format,
    adaptation: adaptation ?? this.adaptation,
    style: style ?? this.style,
    narrativeVoice: narrativeVoice ?? this.narrativeVoice,
    status: status ?? this.status,
    targetMu: targetMu ?? this.targetMu,
    progressMu: progressMu ?? this.progressMu,
    genreProfile: genreProfile ?? this.genreProfile,
    genreDirective: genreDirective ?? this.genreDirective,
    coverMotifId: coverMotifId.present ? coverMotifId.value : this.coverMotifId,
    coverSeed: coverSeed.present ? coverSeed.value : this.coverSeed,
    authorNote: authorNote.present ? authorNote.value : this.authorNote,
    prologueSceneId: prologueSceneId.present
        ? prologueSceneId.value
        : this.prologueSceneId,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  LocalVolumeRow copyWithCompanion(VolumesCompanion data) {
    return LocalVolumeRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      volNo: data.volNo.present ? data.volNo.value : this.volNo,
      title: data.title.present ? data.title.value : this.title,
      format: data.format.present ? data.format.value : this.format,
      adaptation: data.adaptation.present
          ? data.adaptation.value
          : this.adaptation,
      style: data.style.present ? data.style.value : this.style,
      narrativeVoice: data.narrativeVoice.present
          ? data.narrativeVoice.value
          : this.narrativeVoice,
      status: data.status.present ? data.status.value : this.status,
      targetMu: data.targetMu.present ? data.targetMu.value : this.targetMu,
      progressMu: data.progressMu.present
          ? data.progressMu.value
          : this.progressMu,
      genreProfile: data.genreProfile.present
          ? data.genreProfile.value
          : this.genreProfile,
      genreDirective: data.genreDirective.present
          ? data.genreDirective.value
          : this.genreDirective,
      coverMotifId: data.coverMotifId.present
          ? data.coverMotifId.value
          : this.coverMotifId,
      coverSeed: data.coverSeed.present ? data.coverSeed.value : this.coverSeed,
      authorNote: data.authorNote.present
          ? data.authorNote.value
          : this.authorNote,
      prologueSceneId: data.prologueSceneId.present
          ? data.prologueSceneId.value
          : this.prologueSceneId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVolumeRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('volNo: $volNo, ')
          ..write('title: $title, ')
          ..write('format: $format, ')
          ..write('adaptation: $adaptation, ')
          ..write('style: $style, ')
          ..write('narrativeVoice: $narrativeVoice, ')
          ..write('status: $status, ')
          ..write('targetMu: $targetMu, ')
          ..write('progressMu: $progressMu, ')
          ..write('genreProfile: $genreProfile, ')
          ..write('genreDirective: $genreDirective, ')
          ..write('coverMotifId: $coverMotifId, ')
          ..write('coverSeed: $coverSeed, ')
          ..write('authorNote: $authorNote, ')
          ..write('prologueSceneId: $prologueSceneId, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    userId,
    volNo,
    title,
    format,
    adaptation,
    style,
    narrativeVoice,
    status,
    targetMu,
    progressMu,
    genreProfile,
    genreDirective,
    coverMotifId,
    coverSeed,
    authorNote,
    prologueSceneId,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVolumeRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.volNo == this.volNo &&
          other.title == this.title &&
          other.format == this.format &&
          other.adaptation == this.adaptation &&
          other.style == this.style &&
          other.narrativeVoice == this.narrativeVoice &&
          other.status == this.status &&
          other.targetMu == this.targetMu &&
          other.progressMu == this.progressMu &&
          other.genreProfile == this.genreProfile &&
          other.genreDirective == this.genreDirective &&
          other.coverMotifId == this.coverMotifId &&
          other.coverSeed == this.coverSeed &&
          other.authorNote == this.authorNote &&
          other.prologueSceneId == this.prologueSceneId &&
          other.completedAt == this.completedAt);
}

class VolumesCompanion extends UpdateCompanion<LocalVolumeRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<int> volNo;
  final Value<String?> title;
  final Value<String> format;
  final Value<String> adaptation;
  final Value<String> style;
  final Value<String> narrativeVoice;
  final Value<String> status;
  final Value<double> targetMu;
  final Value<double> progressMu;
  final Value<String> genreProfile;
  final Value<String> genreDirective;
  final Value<String?> coverMotifId;
  final Value<int?> coverSeed;
  final Value<String?> authorNote;
  final Value<String?> prologueSceneId;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const VolumesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.volNo = const Value.absent(),
    this.title = const Value.absent(),
    this.format = const Value.absent(),
    this.adaptation = const Value.absent(),
    this.style = const Value.absent(),
    this.narrativeVoice = const Value.absent(),
    this.status = const Value.absent(),
    this.targetMu = const Value.absent(),
    this.progressMu = const Value.absent(),
    this.genreProfile = const Value.absent(),
    this.genreDirective = const Value.absent(),
    this.coverMotifId = const Value.absent(),
    this.coverSeed = const Value.absent(),
    this.authorNote = const Value.absent(),
    this.prologueSceneId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.userId = const Value.absent(),
    required int volNo,
    this.title = const Value.absent(),
    required String format,
    required String adaptation,
    required String style,
    required String narrativeVoice,
    required String status,
    required double targetMu,
    required double progressMu,
    this.genreProfile = const Value.absent(),
    this.genreDirective = const Value.absent(),
    this.coverMotifId = const Value.absent(),
    this.coverSeed = const Value.absent(),
    this.authorNote = const Value.absent(),
    this.prologueSceneId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       volNo = Value(volNo),
       format = Value(format),
       adaptation = Value(adaptation),
       style = Value(style),
       narrativeVoice = Value(narrativeVoice),
       status = Value(status),
       targetMu = Value(targetMu),
       progressMu = Value(progressMu);
  static Insertable<LocalVolumeRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<int>? volNo,
    Expression<String>? title,
    Expression<String>? format,
    Expression<String>? adaptation,
    Expression<String>? style,
    Expression<String>? narrativeVoice,
    Expression<String>? status,
    Expression<double>? targetMu,
    Expression<double>? progressMu,
    Expression<String>? genreProfile,
    Expression<String>? genreDirective,
    Expression<String>? coverMotifId,
    Expression<int>? coverSeed,
    Expression<String>? authorNote,
    Expression<String>? prologueSceneId,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (volNo != null) 'vol_no': volNo,
      if (title != null) 'title': title,
      if (format != null) 'format': format,
      if (adaptation != null) 'adaptation': adaptation,
      if (style != null) 'style': style,
      if (narrativeVoice != null) 'narrative_voice': narrativeVoice,
      if (status != null) 'status': status,
      if (targetMu != null) 'target_mu': targetMu,
      if (progressMu != null) 'progress_mu': progressMu,
      if (genreProfile != null) 'genre_profile': genreProfile,
      if (genreDirective != null) 'genre_directive': genreDirective,
      if (coverMotifId != null) 'cover_motif_id': coverMotifId,
      if (coverSeed != null) 'cover_seed': coverSeed,
      if (authorNote != null) 'author_note': authorNote,
      if (prologueSceneId != null) 'prologue_scene_id': prologueSceneId,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VolumesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? userId,
    Value<int>? volNo,
    Value<String?>? title,
    Value<String>? format,
    Value<String>? adaptation,
    Value<String>? style,
    Value<String>? narrativeVoice,
    Value<String>? status,
    Value<double>? targetMu,
    Value<double>? progressMu,
    Value<String>? genreProfile,
    Value<String>? genreDirective,
    Value<String?>? coverMotifId,
    Value<int?>? coverSeed,
    Value<String?>? authorNote,
    Value<String?>? prologueSceneId,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return VolumesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      volNo: volNo ?? this.volNo,
      title: title ?? this.title,
      format: format ?? this.format,
      adaptation: adaptation ?? this.adaptation,
      style: style ?? this.style,
      narrativeVoice: narrativeVoice ?? this.narrativeVoice,
      status: status ?? this.status,
      targetMu: targetMu ?? this.targetMu,
      progressMu: progressMu ?? this.progressMu,
      genreProfile: genreProfile ?? this.genreProfile,
      genreDirective: genreDirective ?? this.genreDirective,
      coverMotifId: coverMotifId ?? this.coverMotifId,
      coverSeed: coverSeed ?? this.coverSeed,
      authorNote: authorNote ?? this.authorNote,
      prologueSceneId: prologueSceneId ?? this.prologueSceneId,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (volNo.present) {
      map['vol_no'] = Variable<int>(volNo.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (adaptation.present) {
      map['adaptation'] = Variable<String>(adaptation.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (narrativeVoice.present) {
      map['narrative_voice'] = Variable<String>(narrativeVoice.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (targetMu.present) {
      map['target_mu'] = Variable<double>(targetMu.value);
    }
    if (progressMu.present) {
      map['progress_mu'] = Variable<double>(progressMu.value);
    }
    if (genreProfile.present) {
      map['genre_profile'] = Variable<String>(genreProfile.value);
    }
    if (genreDirective.present) {
      map['genre_directive'] = Variable<String>(genreDirective.value);
    }
    if (coverMotifId.present) {
      map['cover_motif_id'] = Variable<String>(coverMotifId.value);
    }
    if (coverSeed.present) {
      map['cover_seed'] = Variable<int>(coverSeed.value);
    }
    if (authorNote.present) {
      map['author_note'] = Variable<String>(authorNote.value);
    }
    if (prologueSceneId.present) {
      map['prologue_scene_id'] = Variable<String>(prologueSceneId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VolumesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('volNo: $volNo, ')
          ..write('title: $title, ')
          ..write('format: $format, ')
          ..write('adaptation: $adaptation, ')
          ..write('style: $style, ')
          ..write('narrativeVoice: $narrativeVoice, ')
          ..write('status: $status, ')
          ..write('targetMu: $targetMu, ')
          ..write('progressMu: $progressMu, ')
          ..write('genreProfile: $genreProfile, ')
          ..write('genreDirective: $genreDirective, ')
          ..write('coverMotifId: $coverMotifId, ')
          ..write('coverSeed: $coverSeed, ')
          ..write('authorNote: $authorNote, ')
          ..write('prologueSceneId: $prologueSceneId, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DreamsTable extends Dreams with TableInfo<$DreamsTable, LocalDreamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUserId),
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _dreamDateMeta = const VerificationMeta(
    'dreamDate',
  );
  @override
  late final GeneratedColumn<DateTime> dreamDate = GeneratedColumn<DateTime>(
    'dream_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputModeMeta = const VerificationMeta(
    'inputMode',
  );
  @override
  late final GeneratedColumn<String> inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextEditedAtMeta = const VerificationMeta(
    'rawTextEditedAt',
  );
  @override
  late final GeneratedColumn<DateTime> rawTextEditedAt =
      GeneratedColumn<DateTime>(
        'raw_text_edited_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recallAnswersMeta = const VerificationMeta(
    'recallAnswers',
  );
  @override
  late final GeneratedColumn<String> recallAnswers = GeneratedColumn<String>(
    'recall_answers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _clarityMeta = const VerificationMeta(
    'clarity',
  );
  @override
  late final GeneratedColumn<String> clarity = GeneratedColumn<String>(
    'clarity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sensitiveFlagsMeta = const VerificationMeta(
    'sensitiveFlags',
  );
  @override
  late final GeneratedColumn<String> sensitiveFlags = GeneratedColumn<String>(
    'sensitive_flags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isBackfillMeta = const VerificationMeta(
    'isBackfill',
  );
  @override
  late final GeneratedColumn<bool> isBackfill = GeneratedColumn<bool>(
    'is_backfill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_backfill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    userId,
    volumeId,
    dreamDate,
    recordedAt,
    inputMode,
    rawText,
    rawTextEditedAt,
    recallAnswers,
    clarity,
    status,
    sensitiveFlags,
    isBackfill,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dreams';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDreamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    }
    if (data.containsKey('dream_date')) {
      context.handle(
        _dreamDateMeta,
        dreamDate.isAcceptableOrUnknown(data['dream_date']!, _dreamDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dreamDateMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('input_mode')) {
      context.handle(
        _inputModeMeta,
        inputMode.isAcceptableOrUnknown(data['input_mode']!, _inputModeMeta),
      );
    } else if (isInserting) {
      context.missing(_inputModeMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('raw_text_edited_at')) {
      context.handle(
        _rawTextEditedAtMeta,
        rawTextEditedAt.isAcceptableOrUnknown(
          data['raw_text_edited_at']!,
          _rawTextEditedAtMeta,
        ),
      );
    }
    if (data.containsKey('recall_answers')) {
      context.handle(
        _recallAnswersMeta,
        recallAnswers.isAcceptableOrUnknown(
          data['recall_answers']!,
          _recallAnswersMeta,
        ),
      );
    }
    if (data.containsKey('clarity')) {
      context.handle(
        _clarityMeta,
        clarity.isAcceptableOrUnknown(data['clarity']!, _clarityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sensitive_flags')) {
      context.handle(
        _sensitiveFlagsMeta,
        sensitiveFlags.isAcceptableOrUnknown(
          data['sensitive_flags']!,
          _sensitiveFlagsMeta,
        ),
      );
    }
    if (data.containsKey('is_backfill')) {
      context.handle(
        _isBackfillMeta,
        isBackfill.isAcceptableOrUnknown(data['is_backfill']!, _isBackfillMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDreamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDreamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      ),
      dreamDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dream_date'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      inputMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_mode'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      rawTextEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}raw_text_edited_at'],
      ),
      recallAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recall_answers'],
      )!,
      clarity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clarity'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sensitiveFlags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensitive_flags'],
      )!,
      isBackfill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_backfill'],
      )!,
    );
  }

  @override
  $DreamsTable createAlias(String alias) {
    return $DreamsTable(attachedDatabase, alias);
  }
}

class LocalDreamRow extends DataClass implements Insertable<LocalDreamRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? volumeId;
  final DateTime dreamDate;
  final DateTime recordedAt;
  final String inputMode;
  final String rawText;
  final DateTime? rawTextEditedAt;
  final String recallAnswers;
  final String? clarity;
  final String status;
  final String sensitiveFlags;
  final bool isBackfill;
  const LocalDreamRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.volumeId,
    required this.dreamDate,
    required this.recordedAt,
    required this.inputMode,
    required this.rawText,
    this.rawTextEditedAt,
    required this.recallAnswers,
    this.clarity,
    required this.status,
    required this.sensitiveFlags,
    required this.isBackfill,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || volumeId != null) {
      map['volume_id'] = Variable<String>(volumeId);
    }
    map['dream_date'] = Variable<DateTime>(dreamDate);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['input_mode'] = Variable<String>(inputMode);
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || rawTextEditedAt != null) {
      map['raw_text_edited_at'] = Variable<DateTime>(rawTextEditedAt);
    }
    map['recall_answers'] = Variable<String>(recallAnswers);
    if (!nullToAbsent || clarity != null) {
      map['clarity'] = Variable<String>(clarity);
    }
    map['status'] = Variable<String>(status);
    map['sensitive_flags'] = Variable<String>(sensitiveFlags);
    map['is_backfill'] = Variable<bool>(isBackfill);
    return map;
  }

  DreamsCompanion toCompanion(bool nullToAbsent) {
    return DreamsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      volumeId: volumeId == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeId),
      dreamDate: Value(dreamDate),
      recordedAt: Value(recordedAt),
      inputMode: Value(inputMode),
      rawText: Value(rawText),
      rawTextEditedAt: rawTextEditedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(rawTextEditedAt),
      recallAnswers: Value(recallAnswers),
      clarity: clarity == null && nullToAbsent
          ? const Value.absent()
          : Value(clarity),
      status: Value(status),
      sensitiveFlags: Value(sensitiveFlags),
      isBackfill: Value(isBackfill),
    );
  }

  factory LocalDreamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDreamRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      volumeId: serializer.fromJson<String?>(json['volumeId']),
      dreamDate: serializer.fromJson<DateTime>(json['dreamDate']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      inputMode: serializer.fromJson<String>(json['inputMode']),
      rawText: serializer.fromJson<String>(json['rawText']),
      rawTextEditedAt: serializer.fromJson<DateTime?>(json['rawTextEditedAt']),
      recallAnswers: serializer.fromJson<String>(json['recallAnswers']),
      clarity: serializer.fromJson<String?>(json['clarity']),
      status: serializer.fromJson<String>(json['status']),
      sensitiveFlags: serializer.fromJson<String>(json['sensitiveFlags']),
      isBackfill: serializer.fromJson<bool>(json['isBackfill']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'volumeId': serializer.toJson<String?>(volumeId),
      'dreamDate': serializer.toJson<DateTime>(dreamDate),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'inputMode': serializer.toJson<String>(inputMode),
      'rawText': serializer.toJson<String>(rawText),
      'rawTextEditedAt': serializer.toJson<DateTime?>(rawTextEditedAt),
      'recallAnswers': serializer.toJson<String>(recallAnswers),
      'clarity': serializer.toJson<String?>(clarity),
      'status': serializer.toJson<String>(status),
      'sensitiveFlags': serializer.toJson<String>(sensitiveFlags),
      'isBackfill': serializer.toJson<bool>(isBackfill),
    };
  }

  LocalDreamRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    Value<String?> volumeId = const Value.absent(),
    DateTime? dreamDate,
    DateTime? recordedAt,
    String? inputMode,
    String? rawText,
    Value<DateTime?> rawTextEditedAt = const Value.absent(),
    String? recallAnswers,
    Value<String?> clarity = const Value.absent(),
    String? status,
    String? sensitiveFlags,
    bool? isBackfill,
  }) => LocalDreamRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    volumeId: volumeId.present ? volumeId.value : this.volumeId,
    dreamDate: dreamDate ?? this.dreamDate,
    recordedAt: recordedAt ?? this.recordedAt,
    inputMode: inputMode ?? this.inputMode,
    rawText: rawText ?? this.rawText,
    rawTextEditedAt: rawTextEditedAt.present
        ? rawTextEditedAt.value
        : this.rawTextEditedAt,
    recallAnswers: recallAnswers ?? this.recallAnswers,
    clarity: clarity.present ? clarity.value : this.clarity,
    status: status ?? this.status,
    sensitiveFlags: sensitiveFlags ?? this.sensitiveFlags,
    isBackfill: isBackfill ?? this.isBackfill,
  );
  LocalDreamRow copyWithCompanion(DreamsCompanion data) {
    return LocalDreamRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      dreamDate: data.dreamDate.present ? data.dreamDate.value : this.dreamDate,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      rawTextEditedAt: data.rawTextEditedAt.present
          ? data.rawTextEditedAt.value
          : this.rawTextEditedAt,
      recallAnswers: data.recallAnswers.present
          ? data.recallAnswers.value
          : this.recallAnswers,
      clarity: data.clarity.present ? data.clarity.value : this.clarity,
      status: data.status.present ? data.status.value : this.status,
      sensitiveFlags: data.sensitiveFlags.present
          ? data.sensitiveFlags.value
          : this.sensitiveFlags,
      isBackfill: data.isBackfill.present
          ? data.isBackfill.value
          : this.isBackfill,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDreamRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamDate: $dreamDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('inputMode: $inputMode, ')
          ..write('rawText: $rawText, ')
          ..write('rawTextEditedAt: $rawTextEditedAt, ')
          ..write('recallAnswers: $recallAnswers, ')
          ..write('clarity: $clarity, ')
          ..write('status: $status, ')
          ..write('sensitiveFlags: $sensitiveFlags, ')
          ..write('isBackfill: $isBackfill')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    userId,
    volumeId,
    dreamDate,
    recordedAt,
    inputMode,
    rawText,
    rawTextEditedAt,
    recallAnswers,
    clarity,
    status,
    sensitiveFlags,
    isBackfill,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDreamRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.volumeId == this.volumeId &&
          other.dreamDate == this.dreamDate &&
          other.recordedAt == this.recordedAt &&
          other.inputMode == this.inputMode &&
          other.rawText == this.rawText &&
          other.rawTextEditedAt == this.rawTextEditedAt &&
          other.recallAnswers == this.recallAnswers &&
          other.clarity == this.clarity &&
          other.status == this.status &&
          other.sensitiveFlags == this.sensitiveFlags &&
          other.isBackfill == this.isBackfill);
}

class DreamsCompanion extends UpdateCompanion<LocalDreamRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<String?> volumeId;
  final Value<DateTime> dreamDate;
  final Value<DateTime> recordedAt;
  final Value<String> inputMode;
  final Value<String> rawText;
  final Value<DateTime?> rawTextEditedAt;
  final Value<String> recallAnswers;
  final Value<String?> clarity;
  final Value<String> status;
  final Value<String> sensitiveFlags;
  final Value<bool> isBackfill;
  final Value<int> rowid;
  const DreamsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.dreamDate = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.rawText = const Value.absent(),
    this.rawTextEditedAt = const Value.absent(),
    this.recallAnswers = const Value.absent(),
    this.clarity = const Value.absent(),
    this.status = const Value.absent(),
    this.sensitiveFlags = const Value.absent(),
    this.isBackfill = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.userId = const Value.absent(),
    this.volumeId = const Value.absent(),
    required DateTime dreamDate,
    required DateTime recordedAt,
    required String inputMode,
    required String rawText,
    this.rawTextEditedAt = const Value.absent(),
    this.recallAnswers = const Value.absent(),
    this.clarity = const Value.absent(),
    required String status,
    this.sensitiveFlags = const Value.absent(),
    this.isBackfill = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       dreamDate = Value(dreamDate),
       recordedAt = Value(recordedAt),
       inputMode = Value(inputMode),
       rawText = Value(rawText),
       status = Value(status);
  static Insertable<LocalDreamRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<String>? volumeId,
    Expression<DateTime>? dreamDate,
    Expression<DateTime>? recordedAt,
    Expression<String>? inputMode,
    Expression<String>? rawText,
    Expression<DateTime>? rawTextEditedAt,
    Expression<String>? recallAnswers,
    Expression<String>? clarity,
    Expression<String>? status,
    Expression<String>? sensitiveFlags,
    Expression<bool>? isBackfill,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (volumeId != null) 'volume_id': volumeId,
      if (dreamDate != null) 'dream_date': dreamDate,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (inputMode != null) 'input_mode': inputMode,
      if (rawText != null) 'raw_text': rawText,
      if (rawTextEditedAt != null) 'raw_text_edited_at': rawTextEditedAt,
      if (recallAnswers != null) 'recall_answers': recallAnswers,
      if (clarity != null) 'clarity': clarity,
      if (status != null) 'status': status,
      if (sensitiveFlags != null) 'sensitive_flags': sensitiveFlags,
      if (isBackfill != null) 'is_backfill': isBackfill,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? userId,
    Value<String?>? volumeId,
    Value<DateTime>? dreamDate,
    Value<DateTime>? recordedAt,
    Value<String>? inputMode,
    Value<String>? rawText,
    Value<DateTime?>? rawTextEditedAt,
    Value<String>? recallAnswers,
    Value<String?>? clarity,
    Value<String>? status,
    Value<String>? sensitiveFlags,
    Value<bool>? isBackfill,
    Value<int>? rowid,
  }) {
    return DreamsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      volumeId: volumeId ?? this.volumeId,
      dreamDate: dreamDate ?? this.dreamDate,
      recordedAt: recordedAt ?? this.recordedAt,
      inputMode: inputMode ?? this.inputMode,
      rawText: rawText ?? this.rawText,
      rawTextEditedAt: rawTextEditedAt ?? this.rawTextEditedAt,
      recallAnswers: recallAnswers ?? this.recallAnswers,
      clarity: clarity ?? this.clarity,
      status: status ?? this.status,
      sensitiveFlags: sensitiveFlags ?? this.sensitiveFlags,
      isBackfill: isBackfill ?? this.isBackfill,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (dreamDate.present) {
      map['dream_date'] = Variable<DateTime>(dreamDate.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(inputMode.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (rawTextEditedAt.present) {
      map['raw_text_edited_at'] = Variable<DateTime>(rawTextEditedAt.value);
    }
    if (recallAnswers.present) {
      map['recall_answers'] = Variable<String>(recallAnswers.value);
    }
    if (clarity.present) {
      map['clarity'] = Variable<String>(clarity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sensitiveFlags.present) {
      map['sensitive_flags'] = Variable<String>(sensitiveFlags.value);
    }
    if (isBackfill.present) {
      map['is_backfill'] = Variable<bool>(isBackfill.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamDate: $dreamDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('inputMode: $inputMode, ')
          ..write('rawText: $rawText, ')
          ..write('rawTextEditedAt: $rawTextEditedAt, ')
          ..write('recallAnswers: $recallAnswers, ')
          ..write('clarity: $clarity, ')
          ..write('status: $status, ')
          ..write('sensitiveFlags: $sensitiveFlags, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DreamElementsTable extends DreamElements
    with TableInfo<$DreamElementsTable, LocalDreamElementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamElementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dreamIdMeta = const VerificationMeta(
    'dreamId',
  );
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
    'dream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dreams (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salienceMeta = const VerificationMeta(
    'salience',
  );
  @override
  late final GeneratedColumn<String> salience = GeneratedColumn<String>(
    'salience',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spanMeta = const VerificationMeta('span');
  @override
  late final GeneratedColumn<String> span = GeneratedColumn<String>(
    'span',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dreamId,
    type,
    label,
    detail,
    salience,
    source,
    span,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dream_elements';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDreamElementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dream_id')) {
      context.handle(
        _dreamIdMeta,
        dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dreamIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('salience')) {
      context.handle(
        _salienceMeta,
        salience.isAcceptableOrUnknown(data['salience']!, _salienceMeta),
      );
    } else if (isInserting) {
      context.missing(_salienceMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('span')) {
      context.handle(
        _spanMeta,
        span.isAcceptableOrUnknown(data['span']!, _spanMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDreamElementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDreamElementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      salience: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salience'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      span: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}span'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DreamElementsTable createAlias(String alias) {
    return $DreamElementsTable(attachedDatabase, alias);
  }
}

class LocalDreamElementRow extends DataClass
    implements Insertable<LocalDreamElementRow> {
  final String id;
  final String dreamId;
  final String type;
  final String label;
  final String? detail;
  final String salience;
  final String source;
  final String? span;
  final DateTime createdAt;
  const LocalDreamElementRow({
    required this.id,
    required this.dreamId,
    required this.type,
    required this.label,
    this.detail,
    required this.salience,
    required this.source,
    this.span,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dream_id'] = Variable<String>(dreamId);
    map['type'] = Variable<String>(type);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['salience'] = Variable<String>(salience);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || span != null) {
      map['span'] = Variable<String>(span);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DreamElementsCompanion toCompanion(bool nullToAbsent) {
    return DreamElementsCompanion(
      id: Value(id),
      dreamId: Value(dreamId),
      type: Value(type),
      label: Value(label),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      salience: Value(salience),
      source: Value(source),
      span: span == null && nullToAbsent ? const Value.absent() : Value(span),
      createdAt: Value(createdAt),
    );
  }

  factory LocalDreamElementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDreamElementRow(
      id: serializer.fromJson<String>(json['id']),
      dreamId: serializer.fromJson<String>(json['dreamId']),
      type: serializer.fromJson<String>(json['type']),
      label: serializer.fromJson<String>(json['label']),
      detail: serializer.fromJson<String?>(json['detail']),
      salience: serializer.fromJson<String>(json['salience']),
      source: serializer.fromJson<String>(json['source']),
      span: serializer.fromJson<String?>(json['span']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dreamId': serializer.toJson<String>(dreamId),
      'type': serializer.toJson<String>(type),
      'label': serializer.toJson<String>(label),
      'detail': serializer.toJson<String?>(detail),
      'salience': serializer.toJson<String>(salience),
      'source': serializer.toJson<String>(source),
      'span': serializer.toJson<String?>(span),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalDreamElementRow copyWith({
    String? id,
    String? dreamId,
    String? type,
    String? label,
    Value<String?> detail = const Value.absent(),
    String? salience,
    String? source,
    Value<String?> span = const Value.absent(),
    DateTime? createdAt,
  }) => LocalDreamElementRow(
    id: id ?? this.id,
    dreamId: dreamId ?? this.dreamId,
    type: type ?? this.type,
    label: label ?? this.label,
    detail: detail.present ? detail.value : this.detail,
    salience: salience ?? this.salience,
    source: source ?? this.source,
    span: span.present ? span.value : this.span,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalDreamElementRow copyWithCompanion(DreamElementsCompanion data) {
    return LocalDreamElementRow(
      id: data.id.present ? data.id.value : this.id,
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      detail: data.detail.present ? data.detail.value : this.detail,
      salience: data.salience.present ? data.salience.value : this.salience,
      source: data.source.present ? data.source.value : this.source,
      span: data.span.present ? data.span.value : this.span,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDreamElementRow(')
          ..write('id: $id, ')
          ..write('dreamId: $dreamId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('detail: $detail, ')
          ..write('salience: $salience, ')
          ..write('source: $source, ')
          ..write('span: $span, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dreamId,
    type,
    label,
    detail,
    salience,
    source,
    span,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDreamElementRow &&
          other.id == this.id &&
          other.dreamId == this.dreamId &&
          other.type == this.type &&
          other.label == this.label &&
          other.detail == this.detail &&
          other.salience == this.salience &&
          other.source == this.source &&
          other.span == this.span &&
          other.createdAt == this.createdAt);
}

class DreamElementsCompanion extends UpdateCompanion<LocalDreamElementRow> {
  final Value<String> id;
  final Value<String> dreamId;
  final Value<String> type;
  final Value<String> label;
  final Value<String?> detail;
  final Value<String> salience;
  final Value<String> source;
  final Value<String?> span;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DreamElementsCompanion({
    this.id = const Value.absent(),
    this.dreamId = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.detail = const Value.absent(),
    this.salience = const Value.absent(),
    this.source = const Value.absent(),
    this.span = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamElementsCompanion.insert({
    required String id,
    required String dreamId,
    required String type,
    required String label,
    this.detail = const Value.absent(),
    required String salience,
    required String source,
    this.span = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dreamId = Value(dreamId),
       type = Value(type),
       label = Value(label),
       salience = Value(salience),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<LocalDreamElementRow> custom({
    Expression<String>? id,
    Expression<String>? dreamId,
    Expression<String>? type,
    Expression<String>? label,
    Expression<String>? detail,
    Expression<String>? salience,
    Expression<String>? source,
    Expression<String>? span,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dreamId != null) 'dream_id': dreamId,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (detail != null) 'detail': detail,
      if (salience != null) 'salience': salience,
      if (source != null) 'source': source,
      if (span != null) 'span': span,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamElementsCompanion copyWith({
    Value<String>? id,
    Value<String>? dreamId,
    Value<String>? type,
    Value<String>? label,
    Value<String?>? detail,
    Value<String>? salience,
    Value<String>? source,
    Value<String?>? span,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DreamElementsCompanion(
      id: id ?? this.id,
      dreamId: dreamId ?? this.dreamId,
      type: type ?? this.type,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      salience: salience ?? this.salience,
      source: source ?? this.source,
      span: span ?? this.span,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (salience.present) {
      map['salience'] = Variable<String>(salience.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (span.present) {
      map['span'] = Variable<String>(span.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamElementsCompanion(')
          ..write('id: $id, ')
          ..write('dreamId: $dreamId, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('detail: $detail, ')
          ..write('salience: $salience, ')
          ..write('source: $source, ')
          ..write('span: $span, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitiesTable extends Entities
    with TableInfo<$EntitiesTable, LocalEntityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstSceneIdMeta = const VerificationMeta(
    'firstSceneId',
  );
  @override
  late final GeneratedColumn<String> firstSceneId = GeneratedColumn<String>(
    'first_scene_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mentionCountMeta = const VerificationMeta(
    'mentionCount',
  );
  @override
  late final GeneratedColumn<int> mentionCount = GeneratedColumn<int>(
    'mention_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    volumeId,
    type,
    roleName,
    description,
    aliases,
    status,
    firstSceneId,
    mentionCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEntityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_roleNameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('first_scene_id')) {
      context.handle(
        _firstSceneIdMeta,
        firstSceneId.isAcceptableOrUnknown(
          data['first_scene_id']!,
          _firstSceneIdMeta,
        ),
      );
    }
    if (data.containsKey('mention_count')) {
      context.handle(
        _mentionCountMeta,
        mentionCount.isAcceptableOrUnknown(
          data['mention_count']!,
          _mentionCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEntityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEntityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      firstSceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_scene_id'],
      ),
      mentionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mention_count'],
      )!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class LocalEntityRow extends DataClass implements Insertable<LocalEntityRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String volumeId;
  final String type;
  final String roleName;
  final String? description;
  final String aliases;
  final String status;
  final String? firstSceneId;
  final int mentionCount;
  const LocalEntityRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.volumeId,
    required this.type,
    required this.roleName,
    this.description,
    required this.aliases,
    required this.status,
    this.firstSceneId,
    required this.mentionCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['volume_id'] = Variable<String>(volumeId);
    map['type'] = Variable<String>(type);
    map['role_name'] = Variable<String>(roleName);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['aliases'] = Variable<String>(aliases);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || firstSceneId != null) {
      map['first_scene_id'] = Variable<String>(firstSceneId);
    }
    map['mention_count'] = Variable<int>(mentionCount);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      volumeId: Value(volumeId),
      type: Value(type),
      roleName: Value(roleName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      aliases: Value(aliases),
      status: Value(status),
      firstSceneId: firstSceneId == null && nullToAbsent
          ? const Value.absent()
          : Value(firstSceneId),
      mentionCount: Value(mentionCount),
    );
  }

  factory LocalEntityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEntityRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      type: serializer.fromJson<String>(json['type']),
      roleName: serializer.fromJson<String>(json['roleName']),
      description: serializer.fromJson<String?>(json['description']),
      aliases: serializer.fromJson<String>(json['aliases']),
      status: serializer.fromJson<String>(json['status']),
      firstSceneId: serializer.fromJson<String?>(json['firstSceneId']),
      mentionCount: serializer.fromJson<int>(json['mentionCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'volumeId': serializer.toJson<String>(volumeId),
      'type': serializer.toJson<String>(type),
      'roleName': serializer.toJson<String>(roleName),
      'description': serializer.toJson<String?>(description),
      'aliases': serializer.toJson<String>(aliases),
      'status': serializer.toJson<String>(status),
      'firstSceneId': serializer.toJson<String?>(firstSceneId),
      'mentionCount': serializer.toJson<int>(mentionCount),
    };
  }

  LocalEntityRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? volumeId,
    String? type,
    String? roleName,
    Value<String?> description = const Value.absent(),
    String? aliases,
    String? status,
    Value<String?> firstSceneId = const Value.absent(),
    int? mentionCount,
  }) => LocalEntityRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    volumeId: volumeId ?? this.volumeId,
    type: type ?? this.type,
    roleName: roleName ?? this.roleName,
    description: description.present ? description.value : this.description,
    aliases: aliases ?? this.aliases,
    status: status ?? this.status,
    firstSceneId: firstSceneId.present ? firstSceneId.value : this.firstSceneId,
    mentionCount: mentionCount ?? this.mentionCount,
  );
  LocalEntityRow copyWithCompanion(EntitiesCompanion data) {
    return LocalEntityRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      type: data.type.present ? data.type.value : this.type,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      description: data.description.present
          ? data.description.value
          : this.description,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
      status: data.status.present ? data.status.value : this.status,
      firstSceneId: data.firstSceneId.present
          ? data.firstSceneId.value
          : this.firstSceneId,
      mentionCount: data.mentionCount.present
          ? data.mentionCount.value
          : this.mentionCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEntityRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('volumeId: $volumeId, ')
          ..write('type: $type, ')
          ..write('roleName: $roleName, ')
          ..write('description: $description, ')
          ..write('aliases: $aliases, ')
          ..write('status: $status, ')
          ..write('firstSceneId: $firstSceneId, ')
          ..write('mentionCount: $mentionCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    volumeId,
    type,
    roleName,
    description,
    aliases,
    status,
    firstSceneId,
    mentionCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEntityRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.volumeId == this.volumeId &&
          other.type == this.type &&
          other.roleName == this.roleName &&
          other.description == this.description &&
          other.aliases == this.aliases &&
          other.status == this.status &&
          other.firstSceneId == this.firstSceneId &&
          other.mentionCount == this.mentionCount);
}

class EntitiesCompanion extends UpdateCompanion<LocalEntityRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> volumeId;
  final Value<String> type;
  final Value<String> roleName;
  final Value<String?> description;
  final Value<String> aliases;
  final Value<String> status;
  final Value<String?> firstSceneId;
  final Value<int> mentionCount;
  final Value<int> rowid;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.type = const Value.absent(),
    this.roleName = const Value.absent(),
    this.description = const Value.absent(),
    this.aliases = const Value.absent(),
    this.status = const Value.absent(),
    this.firstSceneId = const Value.absent(),
    this.mentionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitiesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String volumeId,
    required String type,
    required String roleName,
    this.description = const Value.absent(),
    this.aliases = const Value.absent(),
    required String status,
    this.firstSceneId = const Value.absent(),
    this.mentionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       volumeId = Value(volumeId),
       type = Value(type),
       roleName = Value(roleName),
       status = Value(status);
  static Insertable<LocalEntityRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? volumeId,
    Expression<String>? type,
    Expression<String>? roleName,
    Expression<String>? description,
    Expression<String>? aliases,
    Expression<String>? status,
    Expression<String>? firstSceneId,
    Expression<int>? mentionCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (volumeId != null) 'volume_id': volumeId,
      if (type != null) 'type': type,
      if (roleName != null) 'role_name': roleName,
      if (description != null) 'description': description,
      if (aliases != null) 'aliases': aliases,
      if (status != null) 'status': status,
      if (firstSceneId != null) 'first_scene_id': firstSceneId,
      if (mentionCount != null) 'mention_count': mentionCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitiesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? volumeId,
    Value<String>? type,
    Value<String>? roleName,
    Value<String?>? description,
    Value<String>? aliases,
    Value<String>? status,
    Value<String?>? firstSceneId,
    Value<int>? mentionCount,
    Value<int>? rowid,
  }) {
    return EntitiesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      volumeId: volumeId ?? this.volumeId,
      type: type ?? this.type,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      aliases: aliases ?? this.aliases,
      status: status ?? this.status,
      firstSceneId: firstSceneId ?? this.firstSceneId,
      mentionCount: mentionCount ?? this.mentionCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (firstSceneId.present) {
      map['first_scene_id'] = Variable<String>(firstSceneId.value);
    }
    if (mentionCount.present) {
      map['mention_count'] = Variable<int>(mentionCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('volumeId: $volumeId, ')
          ..write('type: $type, ')
          ..write('roleName: $roleName, ')
          ..write('description: $description, ')
          ..write('aliases: $aliases, ')
          ..write('status: $status, ')
          ..write('firstSceneId: $firstSceneId, ')
          ..write('mentionCount: $mentionCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScenesTable extends Scenes with TableInfo<$ScenesTable, LocalSceneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterNoMeta = const VerificationMeta(
    'chapterNo',
  );
  @override
  late final GeneratedColumn<int> chapterNo = GeneratedColumn<int>(
    'chapter_no',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placementMeta = const VerificationMeta(
    'placement',
  );
  @override
  late final GeneratedColumn<String> placement = GeneratedColumn<String>(
    'placement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceDreamIdsMeta = const VerificationMeta(
    'sourceDreamIds',
  );
  @override
  late final GeneratedColumn<String> sourceDreamIds = GeneratedColumn<String>(
    'source_dream_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _openImageMeta = const VerificationMeta(
    'openImage',
  );
  @override
  late final GeneratedColumn<String> openImage = GeneratedColumn<String>(
    'open_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    volumeId,
    orderKey,
    chapterNo,
    kind,
    placement,
    title,
    sourceDreamIds,
    version,
    openImage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scenes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSceneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('chapter_no')) {
      context.handle(
        _chapterNoMeta,
        chapterNo.isAcceptableOrUnknown(data['chapter_no']!, _chapterNoMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('placement')) {
      context.handle(
        _placementMeta,
        placement.isAcceptableOrUnknown(data['placement']!, _placementMeta),
      );
    } else if (isInserting) {
      context.missing(_placementMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('source_dream_ids')) {
      context.handle(
        _sourceDreamIdsMeta,
        sourceDreamIds.isAcceptableOrUnknown(
          data['source_dream_ids']!,
          _sourceDreamIdsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('open_image')) {
      context.handle(
        _openImageMeta,
        openImage.isAcceptableOrUnknown(data['open_image']!, _openImageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSceneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSceneRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      chapterNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_no'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      placement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}placement'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      sourceDreamIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_dream_ids'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      openImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}open_image'],
      ),
    );
  }

  @override
  $ScenesTable createAlias(String alias) {
    return $ScenesTable(attachedDatabase, alias);
  }
}

class LocalSceneRow extends DataClass implements Insertable<LocalSceneRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String volumeId;
  final String orderKey;
  final int? chapterNo;
  final String kind;
  final String placement;
  final String? title;
  final String sourceDreamIds;
  final int version;
  final String? openImage;
  const LocalSceneRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.volumeId,
    required this.orderKey,
    this.chapterNo,
    required this.kind,
    required this.placement,
    this.title,
    required this.sourceDreamIds,
    required this.version,
    this.openImage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['volume_id'] = Variable<String>(volumeId);
    map['order_key'] = Variable<String>(orderKey);
    if (!nullToAbsent || chapterNo != null) {
      map['chapter_no'] = Variable<int>(chapterNo);
    }
    map['kind'] = Variable<String>(kind);
    map['placement'] = Variable<String>(placement);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['source_dream_ids'] = Variable<String>(sourceDreamIds);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || openImage != null) {
      map['open_image'] = Variable<String>(openImage);
    }
    return map;
  }

  ScenesCompanion toCompanion(bool nullToAbsent) {
    return ScenesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      volumeId: Value(volumeId),
      orderKey: Value(orderKey),
      chapterNo: chapterNo == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterNo),
      kind: Value(kind),
      placement: Value(placement),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      sourceDreamIds: Value(sourceDreamIds),
      version: Value(version),
      openImage: openImage == null && nullToAbsent
          ? const Value.absent()
          : Value(openImage),
    );
  }

  factory LocalSceneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSceneRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      chapterNo: serializer.fromJson<int?>(json['chapterNo']),
      kind: serializer.fromJson<String>(json['kind']),
      placement: serializer.fromJson<String>(json['placement']),
      title: serializer.fromJson<String?>(json['title']),
      sourceDreamIds: serializer.fromJson<String>(json['sourceDreamIds']),
      version: serializer.fromJson<int>(json['version']),
      openImage: serializer.fromJson<String?>(json['openImage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'volumeId': serializer.toJson<String>(volumeId),
      'orderKey': serializer.toJson<String>(orderKey),
      'chapterNo': serializer.toJson<int?>(chapterNo),
      'kind': serializer.toJson<String>(kind),
      'placement': serializer.toJson<String>(placement),
      'title': serializer.toJson<String?>(title),
      'sourceDreamIds': serializer.toJson<String>(sourceDreamIds),
      'version': serializer.toJson<int>(version),
      'openImage': serializer.toJson<String?>(openImage),
    };
  }

  LocalSceneRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? volumeId,
    String? orderKey,
    Value<int?> chapterNo = const Value.absent(),
    String? kind,
    String? placement,
    Value<String?> title = const Value.absent(),
    String? sourceDreamIds,
    int? version,
    Value<String?> openImage = const Value.absent(),
  }) => LocalSceneRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    volumeId: volumeId ?? this.volumeId,
    orderKey: orderKey ?? this.orderKey,
    chapterNo: chapterNo.present ? chapterNo.value : this.chapterNo,
    kind: kind ?? this.kind,
    placement: placement ?? this.placement,
    title: title.present ? title.value : this.title,
    sourceDreamIds: sourceDreamIds ?? this.sourceDreamIds,
    version: version ?? this.version,
    openImage: openImage.present ? openImage.value : this.openImage,
  );
  LocalSceneRow copyWithCompanion(ScenesCompanion data) {
    return LocalSceneRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      chapterNo: data.chapterNo.present ? data.chapterNo.value : this.chapterNo,
      kind: data.kind.present ? data.kind.value : this.kind,
      placement: data.placement.present ? data.placement.value : this.placement,
      title: data.title.present ? data.title.value : this.title,
      sourceDreamIds: data.sourceDreamIds.present
          ? data.sourceDreamIds.value
          : this.sourceDreamIds,
      version: data.version.present ? data.version.value : this.version,
      openImage: data.openImage.present ? data.openImage.value : this.openImage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSceneRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('volumeId: $volumeId, ')
          ..write('orderKey: $orderKey, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('kind: $kind, ')
          ..write('placement: $placement, ')
          ..write('title: $title, ')
          ..write('sourceDreamIds: $sourceDreamIds, ')
          ..write('version: $version, ')
          ..write('openImage: $openImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    volumeId,
    orderKey,
    chapterNo,
    kind,
    placement,
    title,
    sourceDreamIds,
    version,
    openImage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSceneRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.volumeId == this.volumeId &&
          other.orderKey == this.orderKey &&
          other.chapterNo == this.chapterNo &&
          other.kind == this.kind &&
          other.placement == this.placement &&
          other.title == this.title &&
          other.sourceDreamIds == this.sourceDreamIds &&
          other.version == this.version &&
          other.openImage == this.openImage);
}

class ScenesCompanion extends UpdateCompanion<LocalSceneRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> volumeId;
  final Value<String> orderKey;
  final Value<int?> chapterNo;
  final Value<String> kind;
  final Value<String> placement;
  final Value<String?> title;
  final Value<String> sourceDreamIds;
  final Value<int> version;
  final Value<String?> openImage;
  final Value<int> rowid;
  const ScenesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.chapterNo = const Value.absent(),
    this.kind = const Value.absent(),
    this.placement = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceDreamIds = const Value.absent(),
    this.version = const Value.absent(),
    this.openImage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScenesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String volumeId,
    required String orderKey,
    this.chapterNo = const Value.absent(),
    required String kind,
    required String placement,
    this.title = const Value.absent(),
    this.sourceDreamIds = const Value.absent(),
    this.version = const Value.absent(),
    this.openImage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       volumeId = Value(volumeId),
       orderKey = Value(orderKey),
       kind = Value(kind),
       placement = Value(placement);
  static Insertable<LocalSceneRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? volumeId,
    Expression<String>? orderKey,
    Expression<int>? chapterNo,
    Expression<String>? kind,
    Expression<String>? placement,
    Expression<String>? title,
    Expression<String>? sourceDreamIds,
    Expression<int>? version,
    Expression<String>? openImage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (volumeId != null) 'volume_id': volumeId,
      if (orderKey != null) 'order_key': orderKey,
      if (chapterNo != null) 'chapter_no': chapterNo,
      if (kind != null) 'kind': kind,
      if (placement != null) 'placement': placement,
      if (title != null) 'title': title,
      if (sourceDreamIds != null) 'source_dream_ids': sourceDreamIds,
      if (version != null) 'version': version,
      if (openImage != null) 'open_image': openImage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScenesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? volumeId,
    Value<String>? orderKey,
    Value<int?>? chapterNo,
    Value<String>? kind,
    Value<String>? placement,
    Value<String?>? title,
    Value<String>? sourceDreamIds,
    Value<int>? version,
    Value<String?>? openImage,
    Value<int>? rowid,
  }) {
    return ScenesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      volumeId: volumeId ?? this.volumeId,
      orderKey: orderKey ?? this.orderKey,
      chapterNo: chapterNo ?? this.chapterNo,
      kind: kind ?? this.kind,
      placement: placement ?? this.placement,
      title: title ?? this.title,
      sourceDreamIds: sourceDreamIds ?? this.sourceDreamIds,
      version: version ?? this.version,
      openImage: openImage ?? this.openImage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (chapterNo.present) {
      map['chapter_no'] = Variable<int>(chapterNo.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (placement.present) {
      map['placement'] = Variable<String>(placement.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceDreamIds.present) {
      map['source_dream_ids'] = Variable<String>(sourceDreamIds.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (openImage.present) {
      map['open_image'] = Variable<String>(openImage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScenesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('volumeId: $volumeId, ')
          ..write('orderKey: $orderKey, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('kind: $kind, ')
          ..write('placement: $placement, ')
          ..write('title: $title, ')
          ..write('sourceDreamIds: $sourceDreamIds, ')
          ..write('version: $version, ')
          ..write('openImage: $openImage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PassagesTable extends Passages
    with TableInfo<$PassagesTable, LocalPassageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PassagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUserId),
  );
  static const VerificationMeta _sceneIdMeta = const VerificationMeta(
    'sceneId',
  );
  @override
  late final GeneratedColumn<String> sceneId = GeneratedColumn<String>(
    'scene_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scenes (id)',
    ),
  );
  static const VerificationMeta _orderKeyMeta = const VerificationMeta(
    'orderKey',
  );
  @override
  late final GeneratedColumn<String> orderKey = GeneratedColumn<String>(
    'order_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDreamIdMeta = const VerificationMeta(
    'sourceDreamId',
  );
  @override
  late final GeneratedColumn<String> sourceDreamId = GeneratedColumn<String>(
    'source_dream_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dreams (id)',
    ),
  );
  static const VerificationMeta _sourceElementIdsMeta = const VerificationMeta(
    'sourceElementIds',
  );
  @override
  late final GeneratedColumn<String> sourceElementIds = GeneratedColumn<String>(
    'source_element_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cReasonMeta = const VerificationMeta(
    'cReason',
  );
  @override
  late final GeneratedColumn<String> cReason = GeneratedColumn<String>(
    'c_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstReadAtMeta = const VerificationMeta(
    'firstReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstReadAt = GeneratedColumn<DateTime>(
    'first_read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    userId,
    sceneId,
    orderKey,
    content,
    origin,
    sourceDreamId,
    sourceElementIds,
    cReason,
    originalText,
    locked,
    createdBy,
    firstReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPassageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('scene_id')) {
      context.handle(
        _sceneIdMeta,
        sceneId.isAcceptableOrUnknown(data['scene_id']!, _sceneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sceneIdMeta);
    }
    if (data.containsKey('order_key')) {
      context.handle(
        _orderKeyMeta,
        orderKey.isAcceptableOrUnknown(data['order_key']!, _orderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_orderKeyMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('source_dream_id')) {
      context.handle(
        _sourceDreamIdMeta,
        sourceDreamId.isAcceptableOrUnknown(
          data['source_dream_id']!,
          _sourceDreamIdMeta,
        ),
      );
    }
    if (data.containsKey('source_element_ids')) {
      context.handle(
        _sourceElementIdsMeta,
        sourceElementIds.isAcceptableOrUnknown(
          data['source_element_ids']!,
          _sourceElementIdsMeta,
        ),
      );
    }
    if (data.containsKey('c_reason')) {
      context.handle(
        _cReasonMeta,
        cReason.isAcceptableOrUnknown(data['c_reason']!, _cReasonMeta),
      );
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    }
    if (data.containsKey('locked')) {
      context.handle(
        _lockedMeta,
        locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('first_read_at')) {
      context.handle(
        _firstReadAtMeta,
        firstReadAt.isAcceptableOrUnknown(
          data['first_read_at']!,
          _firstReadAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPassageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPassageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      sceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scene_id'],
      )!,
      orderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_key'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      sourceDreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_dream_id'],
      ),
      sourceElementIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_element_ids'],
      )!,
      cReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}c_reason'],
      ),
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      ),
      locked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      firstReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_read_at'],
      ),
    );
  }

  @override
  $PassagesTable createAlias(String alias) {
    return $PassagesTable(attachedDatabase, alias);
  }
}

class LocalPassageRow extends DataClass implements Insertable<LocalPassageRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String sceneId;
  final String orderKey;
  final String content;
  final String origin;
  final String? sourceDreamId;
  final String sourceElementIds;
  final String? cReason;
  final String? originalText;
  final bool locked;
  final String createdBy;
  final DateTime? firstReadAt;
  const LocalPassageRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.sceneId,
    required this.orderKey,
    required this.content,
    required this.origin,
    this.sourceDreamId,
    required this.sourceElementIds,
    this.cReason,
    this.originalText,
    required this.locked,
    required this.createdBy,
    this.firstReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    map['scene_id'] = Variable<String>(sceneId);
    map['order_key'] = Variable<String>(orderKey);
    map['text'] = Variable<String>(content);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || sourceDreamId != null) {
      map['source_dream_id'] = Variable<String>(sourceDreamId);
    }
    map['source_element_ids'] = Variable<String>(sourceElementIds);
    if (!nullToAbsent || cReason != null) {
      map['c_reason'] = Variable<String>(cReason);
    }
    if (!nullToAbsent || originalText != null) {
      map['original_text'] = Variable<String>(originalText);
    }
    map['locked'] = Variable<bool>(locked);
    map['created_by'] = Variable<String>(createdBy);
    if (!nullToAbsent || firstReadAt != null) {
      map['first_read_at'] = Variable<DateTime>(firstReadAt);
    }
    return map;
  }

  PassagesCompanion toCompanion(bool nullToAbsent) {
    return PassagesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      sceneId: Value(sceneId),
      orderKey: Value(orderKey),
      content: Value(content),
      origin: Value(origin),
      sourceDreamId: sourceDreamId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDreamId),
      sourceElementIds: Value(sourceElementIds),
      cReason: cReason == null && nullToAbsent
          ? const Value.absent()
          : Value(cReason),
      originalText: originalText == null && nullToAbsent
          ? const Value.absent()
          : Value(originalText),
      locked: Value(locked),
      createdBy: Value(createdBy),
      firstReadAt: firstReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstReadAt),
    );
  }

  factory LocalPassageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPassageRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      sceneId: serializer.fromJson<String>(json['sceneId']),
      orderKey: serializer.fromJson<String>(json['orderKey']),
      content: serializer.fromJson<String>(json['content']),
      origin: serializer.fromJson<String>(json['origin']),
      sourceDreamId: serializer.fromJson<String?>(json['sourceDreamId']),
      sourceElementIds: serializer.fromJson<String>(json['sourceElementIds']),
      cReason: serializer.fromJson<String?>(json['cReason']),
      originalText: serializer.fromJson<String?>(json['originalText']),
      locked: serializer.fromJson<bool>(json['locked']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      firstReadAt: serializer.fromJson<DateTime?>(json['firstReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'sceneId': serializer.toJson<String>(sceneId),
      'orderKey': serializer.toJson<String>(orderKey),
      'content': serializer.toJson<String>(content),
      'origin': serializer.toJson<String>(origin),
      'sourceDreamId': serializer.toJson<String?>(sourceDreamId),
      'sourceElementIds': serializer.toJson<String>(sourceElementIds),
      'cReason': serializer.toJson<String?>(cReason),
      'originalText': serializer.toJson<String?>(originalText),
      'locked': serializer.toJson<bool>(locked),
      'createdBy': serializer.toJson<String>(createdBy),
      'firstReadAt': serializer.toJson<DateTime?>(firstReadAt),
    };
  }

  LocalPassageRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? sceneId,
    String? orderKey,
    String? content,
    String? origin,
    Value<String?> sourceDreamId = const Value.absent(),
    String? sourceElementIds,
    Value<String?> cReason = const Value.absent(),
    Value<String?> originalText = const Value.absent(),
    bool? locked,
    String? createdBy,
    Value<DateTime?> firstReadAt = const Value.absent(),
  }) => LocalPassageRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    sceneId: sceneId ?? this.sceneId,
    orderKey: orderKey ?? this.orderKey,
    content: content ?? this.content,
    origin: origin ?? this.origin,
    sourceDreamId: sourceDreamId.present
        ? sourceDreamId.value
        : this.sourceDreamId,
    sourceElementIds: sourceElementIds ?? this.sourceElementIds,
    cReason: cReason.present ? cReason.value : this.cReason,
    originalText: originalText.present ? originalText.value : this.originalText,
    locked: locked ?? this.locked,
    createdBy: createdBy ?? this.createdBy,
    firstReadAt: firstReadAt.present ? firstReadAt.value : this.firstReadAt,
  );
  LocalPassageRow copyWithCompanion(PassagesCompanion data) {
    return LocalPassageRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      sceneId: data.sceneId.present ? data.sceneId.value : this.sceneId,
      orderKey: data.orderKey.present ? data.orderKey.value : this.orderKey,
      content: data.content.present ? data.content.value : this.content,
      origin: data.origin.present ? data.origin.value : this.origin,
      sourceDreamId: data.sourceDreamId.present
          ? data.sourceDreamId.value
          : this.sourceDreamId,
      sourceElementIds: data.sourceElementIds.present
          ? data.sourceElementIds.value
          : this.sourceElementIds,
      cReason: data.cReason.present ? data.cReason.value : this.cReason,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      locked: data.locked.present ? data.locked.value : this.locked,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      firstReadAt: data.firstReadAt.present
          ? data.firstReadAt.value
          : this.firstReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPassageRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('sceneId: $sceneId, ')
          ..write('orderKey: $orderKey, ')
          ..write('content: $content, ')
          ..write('origin: $origin, ')
          ..write('sourceDreamId: $sourceDreamId, ')
          ..write('sourceElementIds: $sourceElementIds, ')
          ..write('cReason: $cReason, ')
          ..write('originalText: $originalText, ')
          ..write('locked: $locked, ')
          ..write('createdBy: $createdBy, ')
          ..write('firstReadAt: $firstReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    userId,
    sceneId,
    orderKey,
    content,
    origin,
    sourceDreamId,
    sourceElementIds,
    cReason,
    originalText,
    locked,
    createdBy,
    firstReadAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPassageRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.sceneId == this.sceneId &&
          other.orderKey == this.orderKey &&
          other.content == this.content &&
          other.origin == this.origin &&
          other.sourceDreamId == this.sourceDreamId &&
          other.sourceElementIds == this.sourceElementIds &&
          other.cReason == this.cReason &&
          other.originalText == this.originalText &&
          other.locked == this.locked &&
          other.createdBy == this.createdBy &&
          other.firstReadAt == this.firstReadAt);
}

class PassagesCompanion extends UpdateCompanion<LocalPassageRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<String> sceneId;
  final Value<String> orderKey;
  final Value<String> content;
  final Value<String> origin;
  final Value<String?> sourceDreamId;
  final Value<String> sourceElementIds;
  final Value<String?> cReason;
  final Value<String?> originalText;
  final Value<bool> locked;
  final Value<String> createdBy;
  final Value<DateTime?> firstReadAt;
  final Value<int> rowid;
  const PassagesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.orderKey = const Value.absent(),
    this.content = const Value.absent(),
    this.origin = const Value.absent(),
    this.sourceDreamId = const Value.absent(),
    this.sourceElementIds = const Value.absent(),
    this.cReason = const Value.absent(),
    this.originalText = const Value.absent(),
    this.locked = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.firstReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PassagesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.userId = const Value.absent(),
    required String sceneId,
    required String orderKey,
    required String content,
    required String origin,
    this.sourceDreamId = const Value.absent(),
    this.sourceElementIds = const Value.absent(),
    this.cReason = const Value.absent(),
    this.originalText = const Value.absent(),
    this.locked = const Value.absent(),
    required String createdBy,
    this.firstReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sceneId = Value(sceneId),
       orderKey = Value(orderKey),
       content = Value(content),
       origin = Value(origin),
       createdBy = Value(createdBy);
  static Insertable<LocalPassageRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<String>? sceneId,
    Expression<String>? orderKey,
    Expression<String>? content,
    Expression<String>? origin,
    Expression<String>? sourceDreamId,
    Expression<String>? sourceElementIds,
    Expression<String>? cReason,
    Expression<String>? originalText,
    Expression<bool>? locked,
    Expression<String>? createdBy,
    Expression<DateTime>? firstReadAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (sceneId != null) 'scene_id': sceneId,
      if (orderKey != null) 'order_key': orderKey,
      if (content != null) 'text': content,
      if (origin != null) 'origin': origin,
      if (sourceDreamId != null) 'source_dream_id': sourceDreamId,
      if (sourceElementIds != null) 'source_element_ids': sourceElementIds,
      if (cReason != null) 'c_reason': cReason,
      if (originalText != null) 'original_text': originalText,
      if (locked != null) 'locked': locked,
      if (createdBy != null) 'created_by': createdBy,
      if (firstReadAt != null) 'first_read_at': firstReadAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PassagesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? userId,
    Value<String>? sceneId,
    Value<String>? orderKey,
    Value<String>? content,
    Value<String>? origin,
    Value<String?>? sourceDreamId,
    Value<String>? sourceElementIds,
    Value<String?>? cReason,
    Value<String?>? originalText,
    Value<bool>? locked,
    Value<String>? createdBy,
    Value<DateTime?>? firstReadAt,
    Value<int>? rowid,
  }) {
    return PassagesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      sceneId: sceneId ?? this.sceneId,
      orderKey: orderKey ?? this.orderKey,
      content: content ?? this.content,
      origin: origin ?? this.origin,
      sourceDreamId: sourceDreamId ?? this.sourceDreamId,
      sourceElementIds: sourceElementIds ?? this.sourceElementIds,
      cReason: cReason ?? this.cReason,
      originalText: originalText ?? this.originalText,
      locked: locked ?? this.locked,
      createdBy: createdBy ?? this.createdBy,
      firstReadAt: firstReadAt ?? this.firstReadAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sceneId.present) {
      map['scene_id'] = Variable<String>(sceneId.value);
    }
    if (orderKey.present) {
      map['order_key'] = Variable<String>(orderKey.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (sourceDreamId.present) {
      map['source_dream_id'] = Variable<String>(sourceDreamId.value);
    }
    if (sourceElementIds.present) {
      map['source_element_ids'] = Variable<String>(sourceElementIds.value);
    }
    if (cReason.present) {
      map['c_reason'] = Variable<String>(cReason.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (firstReadAt.present) {
      map['first_read_at'] = Variable<DateTime>(firstReadAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PassagesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('sceneId: $sceneId, ')
          ..write('orderKey: $orderKey, ')
          ..write('content: $content, ')
          ..write('origin: $origin, ')
          ..write('sourceDreamId: $sourceDreamId, ')
          ..write('sourceElementIds: $sourceElementIds, ')
          ..write('cReason: $cReason, ')
          ..write('originalText: $originalText, ')
          ..write('locked: $locked, ')
          ..write('createdBy: $createdBy, ')
          ..write('firstReadAt: $firstReadAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressEventsTable extends ProgressEvents
    with TableInfo<$ProgressEventsTable, LocalProgressEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUserId),
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _dreamIdMeta = const VerificationMeta(
    'dreamId',
  );
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
    'dream_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dreams (id)',
    ),
  );
  static const VerificationMeta _deltaMuMeta = const VerificationMeta(
    'deltaMu',
  );
  @override
  late final GeneratedColumn<double> deltaMu = GeneratedColumn<double>(
    'delta_mu',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonsMeta = const VerificationMeta(
    'reasons',
  );
  @override
  late final GeneratedColumn<String> reasons = GeneratedColumn<String>(
    'reasons',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    volumeId,
    dreamId,
    deltaMu,
    reasons,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProgressEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('dream_id')) {
      context.handle(
        _dreamIdMeta,
        dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta),
      );
    }
    if (data.containsKey('delta_mu')) {
      context.handle(
        _deltaMuMeta,
        deltaMu.isAcceptableOrUnknown(data['delta_mu']!, _deltaMuMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMuMeta);
    }
    if (data.containsKey('reasons')) {
      context.handle(
        _reasonsMeta,
        reasons.isAcceptableOrUnknown(data['reasons']!, _reasonsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalProgressEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProgressEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      dreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_id'],
      ),
      deltaMu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}delta_mu'],
      )!,
      reasons: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reasons'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProgressEventsTable createAlias(String alias) {
    return $ProgressEventsTable(attachedDatabase, alias);
  }
}

class LocalProgressEventRow extends DataClass
    implements Insertable<LocalProgressEventRow> {
  final String id;
  final String userId;
  final String volumeId;
  final String? dreamId;
  final double deltaMu;
  final String reasons;
  final DateTime createdAt;
  const LocalProgressEventRow({
    required this.id,
    required this.userId,
    required this.volumeId,
    this.dreamId,
    required this.deltaMu,
    required this.reasons,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['volume_id'] = Variable<String>(volumeId);
    if (!nullToAbsent || dreamId != null) {
      map['dream_id'] = Variable<String>(dreamId);
    }
    map['delta_mu'] = Variable<double>(deltaMu);
    map['reasons'] = Variable<String>(reasons);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProgressEventsCompanion toCompanion(bool nullToAbsent) {
    return ProgressEventsCompanion(
      id: Value(id),
      userId: Value(userId),
      volumeId: Value(volumeId),
      dreamId: dreamId == null && nullToAbsent
          ? const Value.absent()
          : Value(dreamId),
      deltaMu: Value(deltaMu),
      reasons: Value(reasons),
      createdAt: Value(createdAt),
    );
  }

  factory LocalProgressEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProgressEventRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      dreamId: serializer.fromJson<String?>(json['dreamId']),
      deltaMu: serializer.fromJson<double>(json['deltaMu']),
      reasons: serializer.fromJson<String>(json['reasons']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'volumeId': serializer.toJson<String>(volumeId),
      'dreamId': serializer.toJson<String?>(dreamId),
      'deltaMu': serializer.toJson<double>(deltaMu),
      'reasons': serializer.toJson<String>(reasons),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalProgressEventRow copyWith({
    String? id,
    String? userId,
    String? volumeId,
    Value<String?> dreamId = const Value.absent(),
    double? deltaMu,
    String? reasons,
    DateTime? createdAt,
  }) => LocalProgressEventRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    volumeId: volumeId ?? this.volumeId,
    dreamId: dreamId.present ? dreamId.value : this.dreamId,
    deltaMu: deltaMu ?? this.deltaMu,
    reasons: reasons ?? this.reasons,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalProgressEventRow copyWithCompanion(ProgressEventsCompanion data) {
    return LocalProgressEventRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      deltaMu: data.deltaMu.present ? data.deltaMu.value : this.deltaMu,
      reasons: data.reasons.present ? data.reasons.value : this.reasons,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProgressEventRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamId: $dreamId, ')
          ..write('deltaMu: $deltaMu, ')
          ..write('reasons: $reasons, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, volumeId, dreamId, deltaMu, reasons, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProgressEventRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.volumeId == this.volumeId &&
          other.dreamId == this.dreamId &&
          other.deltaMu == this.deltaMu &&
          other.reasons == this.reasons &&
          other.createdAt == this.createdAt);
}

class ProgressEventsCompanion extends UpdateCompanion<LocalProgressEventRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> volumeId;
  final Value<String?> dreamId;
  final Value<double> deltaMu;
  final Value<String> reasons;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProgressEventsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.dreamId = const Value.absent(),
    this.deltaMu = const Value.absent(),
    this.reasons = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressEventsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String volumeId,
    this.dreamId = const Value.absent(),
    required double deltaMu,
    this.reasons = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       volumeId = Value(volumeId),
       deltaMu = Value(deltaMu),
       createdAt = Value(createdAt);
  static Insertable<LocalProgressEventRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? volumeId,
    Expression<String>? dreamId,
    Expression<double>? deltaMu,
    Expression<String>? reasons,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (volumeId != null) 'volume_id': volumeId,
      if (dreamId != null) 'dream_id': dreamId,
      if (deltaMu != null) 'delta_mu': deltaMu,
      if (reasons != null) 'reasons': reasons,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? volumeId,
    Value<String?>? dreamId,
    Value<double>? deltaMu,
    Value<String>? reasons,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProgressEventsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      volumeId: volumeId ?? this.volumeId,
      dreamId: dreamId ?? this.dreamId,
      deltaMu: deltaMu ?? this.deltaMu,
      reasons: reasons ?? this.reasons,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (deltaMu.present) {
      map['delta_mu'] = Variable<double>(deltaMu.value);
    }
    if (reasons.present) {
      map['reasons'] = Variable<String>(reasons.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEventsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamId: $dreamId, ')
          ..write('deltaMu: $deltaMu, ')
          ..write('reasons: $reasons, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JobsTable extends Jobs with TableInfo<$JobsTable, LocalJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUserId),
  );
  static const VerificationMeta _dreamIdMeta = const VerificationMeta(
    'dreamId',
  );
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
    'dream_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dreams (id)',
    ),
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _stageLabelMeta = const VerificationMeta(
    'stageLabel',
  );
  @override
  late final GeneratedColumn<String> stageLabel = GeneratedColumn<String>(
    'stage_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    userId,
    dreamId,
    volumeId,
    type,
    status,
    attempt,
    error,
    idempotencyKey,
    payload,
    stageLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('dream_id')) {
      context.handle(
        _dreamIdMeta,
        dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta),
      );
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('stage_label')) {
      context.handle(
        _stageLabelMeta,
        stageLabel.isAcceptableOrUnknown(data['stage_label']!, _stageLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_stageLabelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      dreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_id'],
      ),
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      stageLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage_label'],
      )!,
    );
  }

  @override
  $JobsTable createAlias(String alias) {
    return $JobsTable(attachedDatabase, alias);
  }
}

class LocalJobRow extends DataClass implements Insertable<LocalJobRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? dreamId;
  final String volumeId;
  final String type;
  final String status;
  final int attempt;
  final String? error;
  final String idempotencyKey;
  final String payload;
  final String stageLabel;
  const LocalJobRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.dreamId,
    required this.volumeId,
    required this.type,
    required this.status,
    required this.attempt,
    this.error,
    required this.idempotencyKey,
    required this.payload,
    required this.stageLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || dreamId != null) {
      map['dream_id'] = Variable<String>(dreamId);
    }
    map['volume_id'] = Variable<String>(volumeId);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    map['attempt'] = Variable<int>(attempt);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload'] = Variable<String>(payload);
    map['stage_label'] = Variable<String>(stageLabel);
    return map;
  }

  JobsCompanion toCompanion(bool nullToAbsent) {
    return JobsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      dreamId: dreamId == null && nullToAbsent
          ? const Value.absent()
          : Value(dreamId),
      volumeId: Value(volumeId),
      type: Value(type),
      status: Value(status),
      attempt: Value(attempt),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      idempotencyKey: Value(idempotencyKey),
      payload: Value(payload),
      stageLabel: Value(stageLabel),
    );
  }

  factory LocalJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalJobRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      dreamId: serializer.fromJson<String?>(json['dreamId']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      attempt: serializer.fromJson<int>(json['attempt']),
      error: serializer.fromJson<String?>(json['error']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payload: serializer.fromJson<String>(json['payload']),
      stageLabel: serializer.fromJson<String>(json['stageLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'dreamId': serializer.toJson<String?>(dreamId),
      'volumeId': serializer.toJson<String>(volumeId),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'attempt': serializer.toJson<int>(attempt),
      'error': serializer.toJson<String?>(error),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payload': serializer.toJson<String>(payload),
      'stageLabel': serializer.toJson<String>(stageLabel),
    };
  }

  LocalJobRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    Value<String?> dreamId = const Value.absent(),
    String? volumeId,
    String? type,
    String? status,
    int? attempt,
    Value<String?> error = const Value.absent(),
    String? idempotencyKey,
    String? payload,
    String? stageLabel,
  }) => LocalJobRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    userId: userId ?? this.userId,
    dreamId: dreamId.present ? dreamId.value : this.dreamId,
    volumeId: volumeId ?? this.volumeId,
    type: type ?? this.type,
    status: status ?? this.status,
    attempt: attempt ?? this.attempt,
    error: error.present ? error.value : this.error,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    payload: payload ?? this.payload,
    stageLabel: stageLabel ?? this.stageLabel,
  );
  LocalJobRow copyWithCompanion(JobsCompanion data) {
    return LocalJobRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      error: data.error.present ? data.error.value : this.error,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      stageLabel: data.stageLabel.present
          ? data.stageLabel.value
          : this.stageLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalJobRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('dreamId: $dreamId, ')
          ..write('volumeId: $volumeId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('attempt: $attempt, ')
          ..write('error: $error, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payload: $payload, ')
          ..write('stageLabel: $stageLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    userId,
    dreamId,
    volumeId,
    type,
    status,
    attempt,
    error,
    idempotencyKey,
    payload,
    stageLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalJobRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.dreamId == this.dreamId &&
          other.volumeId == this.volumeId &&
          other.type == this.type &&
          other.status == this.status &&
          other.attempt == this.attempt &&
          other.error == this.error &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payload == this.payload &&
          other.stageLabel == this.stageLabel);
}

class JobsCompanion extends UpdateCompanion<LocalJobRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<String?> dreamId;
  final Value<String> volumeId;
  final Value<String> type;
  final Value<String> status;
  final Value<int> attempt;
  final Value<String?> error;
  final Value<String> idempotencyKey;
  final Value<String> payload;
  final Value<String> stageLabel;
  final Value<int> rowid;
  const JobsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.dreamId = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.attempt = const Value.absent(),
    this.error = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.stageLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JobsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.userId = const Value.absent(),
    this.dreamId = const Value.absent(),
    required String volumeId,
    required String type,
    required String status,
    this.attempt = const Value.absent(),
    this.error = const Value.absent(),
    required String idempotencyKey,
    this.payload = const Value.absent(),
    required String stageLabel,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       volumeId = Value(volumeId),
       type = Value(type),
       status = Value(status),
       idempotencyKey = Value(idempotencyKey),
       stageLabel = Value(stageLabel);
  static Insertable<LocalJobRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<String>? dreamId,
    Expression<String>? volumeId,
    Expression<String>? type,
    Expression<String>? status,
    Expression<int>? attempt,
    Expression<String>? error,
    Expression<String>? idempotencyKey,
    Expression<String>? payload,
    Expression<String>? stageLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (dreamId != null) 'dream_id': dreamId,
      if (volumeId != null) 'volume_id': volumeId,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (attempt != null) 'attempt': attempt,
      if (error != null) 'error': error,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payload != null) 'payload': payload,
      if (stageLabel != null) 'stage_label': stageLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JobsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? userId,
    Value<String?>? dreamId,
    Value<String>? volumeId,
    Value<String>? type,
    Value<String>? status,
    Value<int>? attempt,
    Value<String?>? error,
    Value<String>? idempotencyKey,
    Value<String>? payload,
    Value<String>? stageLabel,
    Value<int>? rowid,
  }) {
    return JobsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      dreamId: dreamId ?? this.dreamId,
      volumeId: volumeId ?? this.volumeId,
      type: type ?? this.type,
      status: status ?? this.status,
      attempt: attempt ?? this.attempt,
      error: error ?? this.error,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payload: payload ?? this.payload,
      stageLabel: stageLabel ?? this.stageLabel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (stageLabel.present) {
      map['stage_label'] = Variable<String>(stageLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JobsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('dreamId: $dreamId, ')
          ..write('volumeId: $volumeId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('attempt: $attempt, ')
          ..write('error: $error, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payload: $payload, ')
          ..write('stageLabel: $stageLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LinkDecisionsTable extends LinkDecisions
    with TableInfo<$LinkDecisionsTable, LocalLinkDecisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinkDecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _dreamIdMeta = const VerificationMeta(
    'dreamId',
  );
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
    'dream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dreams (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    volumeId,
    dreamId,
    kind,
    payload,
    status,
    decidedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'link_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLinkDecisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('dream_id')) {
      context.handle(
        _dreamIdMeta,
        dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dreamIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalLinkDecisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLinkDecisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      dreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LinkDecisionsTable createAlias(String alias) {
    return $LinkDecisionsTable(attachedDatabase, alias);
  }
}

class LocalLinkDecisionRow extends DataClass
    implements Insertable<LocalLinkDecisionRow> {
  final String id;
  final String volumeId;
  final String dreamId;
  final String kind;
  final String payload;
  final String status;
  final DateTime? decidedAt;
  final DateTime createdAt;
  const LocalLinkDecisionRow({
    required this.id,
    required this.volumeId,
    required this.dreamId,
    required this.kind,
    required this.payload,
    required this.status,
    this.decidedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['volume_id'] = Variable<String>(volumeId);
    map['dream_id'] = Variable<String>(dreamId);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LinkDecisionsCompanion toCompanion(bool nullToAbsent) {
    return LinkDecisionsCompanion(
      id: Value(id),
      volumeId: Value(volumeId),
      dreamId: Value(dreamId),
      kind: Value(kind),
      payload: Value(payload),
      status: Value(status),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalLinkDecisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLinkDecisionRow(
      id: serializer.fromJson<String>(json['id']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      dreamId: serializer.fromJson<String>(json['dreamId']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'volumeId': serializer.toJson<String>(volumeId),
      'dreamId': serializer.toJson<String>(dreamId),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalLinkDecisionRow copyWith({
    String? id,
    String? volumeId,
    String? dreamId,
    String? kind,
    String? payload,
    String? status,
    Value<DateTime?> decidedAt = const Value.absent(),
    DateTime? createdAt,
  }) => LocalLinkDecisionRow(
    id: id ?? this.id,
    volumeId: volumeId ?? this.volumeId,
    dreamId: dreamId ?? this.dreamId,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalLinkDecisionRow copyWithCompanion(LinkDecisionsCompanion data) {
    return LocalLinkDecisionRow(
      id: data.id.present ? data.id.value : this.id,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLinkDecisionRow(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamId: $dreamId, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    volumeId,
    dreamId,
    kind,
    payload,
    status,
    decidedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLinkDecisionRow &&
          other.id == this.id &&
          other.volumeId == this.volumeId &&
          other.dreamId == this.dreamId &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.decidedAt == this.decidedAt &&
          other.createdAt == this.createdAt);
}

class LinkDecisionsCompanion extends UpdateCompanion<LocalLinkDecisionRow> {
  final Value<String> id;
  final Value<String> volumeId;
  final Value<String> dreamId;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String> status;
  final Value<DateTime?> decidedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LinkDecisionsCompanion({
    this.id = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.dreamId = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LinkDecisionsCompanion.insert({
    required String id,
    required String volumeId,
    required String dreamId,
    required String kind,
    this.payload = const Value.absent(),
    required String status,
    this.decidedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       volumeId = Value(volumeId),
       dreamId = Value(dreamId),
       kind = Value(kind),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<LocalLinkDecisionRow> custom({
    Expression<String>? id,
    Expression<String>? volumeId,
    Expression<String>? dreamId,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? decidedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (volumeId != null) 'volume_id': volumeId,
      if (dreamId != null) 'dream_id': dreamId,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LinkDecisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? volumeId,
    Value<String>? dreamId,
    Value<String>? kind,
    Value<String>? payload,
    Value<String>? status,
    Value<DateTime?>? decidedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LinkDecisionsCompanion(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      dreamId: dreamId ?? this.dreamId,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinkDecisionsCompanion(')
          ..write('id: $id, ')
          ..write('volumeId: $volumeId, ')
          ..write('dreamId: $dreamId, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DreamDraftsTable extends DreamDrafts
    with TableInfo<$DreamDraftsTable, LocalDreamDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputModeMeta = const VerificationMeta(
    'inputMode',
  );
  @override
  late final GeneratedColumn<String> inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dreamDateMeta = const VerificationMeta(
    'dreamDate',
  );
  @override
  late final GeneratedColumn<DateTime> dreamDate = GeneratedColumn<DateTime>(
    'dream_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBackfillMeta = const VerificationMeta(
    'isBackfill',
  );
  @override
  late final GeneratedColumn<bool> isBackfill = GeneratedColumn<bool>(
    'is_backfill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_backfill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    inputMode,
    dreamDate,
    isBackfill,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dream_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDreamDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('input_mode')) {
      context.handle(
        _inputModeMeta,
        inputMode.isAcceptableOrUnknown(data['input_mode']!, _inputModeMeta),
      );
    } else if (isInserting) {
      context.missing(_inputModeMeta);
    }
    if (data.containsKey('dream_date')) {
      context.handle(
        _dreamDateMeta,
        dreamDate.isAcceptableOrUnknown(data['dream_date']!, _dreamDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dreamDateMeta);
    }
    if (data.containsKey('is_backfill')) {
      context.handle(
        _isBackfillMeta,
        isBackfill.isAcceptableOrUnknown(data['is_backfill']!, _isBackfillMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDreamDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDreamDraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      inputMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_mode'],
      )!,
      dreamDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dream_date'],
      )!,
      isBackfill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_backfill'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DreamDraftsTable createAlias(String alias) {
    return $DreamDraftsTable(attachedDatabase, alias);
  }
}

class LocalDreamDraftRow extends DataClass
    implements Insertable<LocalDreamDraftRow> {
  final String id;
  final String content;
  final String inputMode;
  final DateTime dreamDate;
  final bool isBackfill;
  final DateTime updatedAt;
  const LocalDreamDraftRow({
    required this.id,
    required this.content,
    required this.inputMode,
    required this.dreamDate,
    required this.isBackfill,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text'] = Variable<String>(content);
    map['input_mode'] = Variable<String>(inputMode);
    map['dream_date'] = Variable<DateTime>(dreamDate);
    map['is_backfill'] = Variable<bool>(isBackfill);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DreamDraftsCompanion toCompanion(bool nullToAbsent) {
    return DreamDraftsCompanion(
      id: Value(id),
      content: Value(content),
      inputMode: Value(inputMode),
      dreamDate: Value(dreamDate),
      isBackfill: Value(isBackfill),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDreamDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDreamDraftRow(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      inputMode: serializer.fromJson<String>(json['inputMode']),
      dreamDate: serializer.fromJson<DateTime>(json['dreamDate']),
      isBackfill: serializer.fromJson<bool>(json['isBackfill']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'inputMode': serializer.toJson<String>(inputMode),
      'dreamDate': serializer.toJson<DateTime>(dreamDate),
      'isBackfill': serializer.toJson<bool>(isBackfill),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDreamDraftRow copyWith({
    String? id,
    String? content,
    String? inputMode,
    DateTime? dreamDate,
    bool? isBackfill,
    DateTime? updatedAt,
  }) => LocalDreamDraftRow(
    id: id ?? this.id,
    content: content ?? this.content,
    inputMode: inputMode ?? this.inputMode,
    dreamDate: dreamDate ?? this.dreamDate,
    isBackfill: isBackfill ?? this.isBackfill,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDreamDraftRow copyWithCompanion(DreamDraftsCompanion data) {
    return LocalDreamDraftRow(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      dreamDate: data.dreamDate.present ? data.dreamDate.value : this.dreamDate,
      isBackfill: data.isBackfill.present
          ? data.isBackfill.value
          : this.isBackfill,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDreamDraftRow(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('inputMode: $inputMode, ')
          ..write('dreamDate: $dreamDate, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, content, inputMode, dreamDate, isBackfill, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDreamDraftRow &&
          other.id == this.id &&
          other.content == this.content &&
          other.inputMode == this.inputMode &&
          other.dreamDate == this.dreamDate &&
          other.isBackfill == this.isBackfill &&
          other.updatedAt == this.updatedAt);
}

class DreamDraftsCompanion extends UpdateCompanion<LocalDreamDraftRow> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> inputMode;
  final Value<DateTime> dreamDate;
  final Value<bool> isBackfill;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DreamDraftsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.dreamDate = const Value.absent(),
    this.isBackfill = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamDraftsCompanion.insert({
    required String id,
    required String content,
    required String inputMode,
    required DateTime dreamDate,
    this.isBackfill = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       inputMode = Value(inputMode),
       dreamDate = Value(dreamDate),
       updatedAt = Value(updatedAt);
  static Insertable<LocalDreamDraftRow> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? inputMode,
    Expression<DateTime>? dreamDate,
    Expression<bool>? isBackfill,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'text': content,
      if (inputMode != null) 'input_mode': inputMode,
      if (dreamDate != null) 'dream_date': dreamDate,
      if (isBackfill != null) 'is_backfill': isBackfill,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? content,
    Value<String>? inputMode,
    Value<DateTime>? dreamDate,
    Value<bool>? isBackfill,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DreamDraftsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      inputMode: inputMode ?? this.inputMode,
      dreamDate: dreamDate ?? this.dreamDate,
      isBackfill: isBackfill ?? this.isBackfill,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(inputMode.value);
    }
    if (dreamDate.present) {
      map['dream_date'] = Variable<DateTime>(dreamDate.value);
    }
    if (isBackfill.present) {
      map['is_backfill'] = Variable<bool>(isBackfill.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamDraftsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('inputMode: $inputMode, ')
          ..write('dreamDate: $dreamDate, ')
          ..write('isBackfill: $isBackfill, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, LocalOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    op,
    payload,
    idempotencyKey,
    attempt,
    nextAttemptAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOutboxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class LocalOutboxRow extends DataClass implements Insertable<LocalOutboxRow> {
  final String id;
  final String op;
  final String payload;
  final String idempotencyKey;
  final int attempt;
  final DateTime nextAttemptAt;
  final String status;
  const LocalOutboxRow({
    required this.id,
    required this.op,
    required this.payload,
    required this.idempotencyKey,
    required this.attempt,
    required this.nextAttemptAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['attempt'] = Variable<int>(attempt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      op: Value(op),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      attempt: Value(attempt),
      nextAttemptAt: Value(nextAttemptAt),
      status: Value(status),
    );
  }

  factory LocalOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOutboxRow(
      id: serializer.fromJson<String>(json['id']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      attempt: serializer.fromJson<int>(json['attempt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'attempt': serializer.toJson<int>(attempt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalOutboxRow copyWith({
    String? id,
    String? op,
    String? payload,
    String? idempotencyKey,
    int? attempt,
    DateTime? nextAttemptAt,
    String? status,
  }) => LocalOutboxRow(
    id: id ?? this.id,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    attempt: attempt ?? this.attempt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    status: status ?? this.status,
  );
  LocalOutboxRow copyWithCompanion(OutboxCompanion data) {
    return LocalOutboxRow(
      id: data.id.present ? data.id.value : this.id,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxRow(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attempt: $attempt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    op,
    payload,
    idempotencyKey,
    attempt,
    nextAttemptAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOutboxRow &&
          other.id == this.id &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.attempt == this.attempt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.status == this.status);
}

class OutboxCompanion extends UpdateCompanion<LocalOutboxRow> {
  final Value<String> id;
  final Value<String> op;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<int> attempt;
  final Value<DateTime> nextAttemptAt;
  final Value<String> status;
  final Value<int> rowid;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.attempt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String id,
    required String op,
    required String payload,
    required String idempotencyKey,
    this.attempt = const Value.absent(),
    required DateTime nextAttemptAt,
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       op = Value(op),
       payload = Value(payload),
       idempotencyKey = Value(idempotencyKey),
       nextAttemptAt = Value(nextAttemptAt),
       status = Value(status);
  static Insertable<LocalOutboxRow> custom({
    Expression<String>? id,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<int>? attempt,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (attempt != null) 'attempt': attempt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? op,
    Value<String>? payload,
    Value<String>? idempotencyKey,
    Value<int>? attempt,
    Value<DateTime>? nextAttemptAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      attempt: attempt ?? this.attempt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attempt: $attempt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderPositionsTable extends ReaderPositions
    with TableInfo<$ReaderPositionsTable, LocalReaderPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id)',
    ),
  );
  static const VerificationMeta _offsetMeta = const VerificationMeta('offset');
  @override
  late final GeneratedColumn<double> offset = GeneratedColumn<double>(
    'offset',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [volumeId, offset, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReaderPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('offset')) {
      context.handle(
        _offsetMeta,
        offset.isAcceptableOrUnknown(data['offset']!, _offsetMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {volumeId};
  @override
  LocalReaderPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReaderPositionRow(
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      offset: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}offset'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReaderPositionsTable createAlias(String alias) {
    return $ReaderPositionsTable(attachedDatabase, alias);
  }
}

class LocalReaderPositionRow extends DataClass
    implements Insertable<LocalReaderPositionRow> {
  final String volumeId;
  final double offset;
  final DateTime updatedAt;
  const LocalReaderPositionRow({
    required this.volumeId,
    required this.offset,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['volume_id'] = Variable<String>(volumeId);
    map['offset'] = Variable<double>(offset);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReaderPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReaderPositionsCompanion(
      volumeId: Value(volumeId),
      offset: Value(offset),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalReaderPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReaderPositionRow(
      volumeId: serializer.fromJson<String>(json['volumeId']),
      offset: serializer.fromJson<double>(json['offset']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'volumeId': serializer.toJson<String>(volumeId),
      'offset': serializer.toJson<double>(offset),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalReaderPositionRow copyWith({
    String? volumeId,
    double? offset,
    DateTime? updatedAt,
  }) => LocalReaderPositionRow(
    volumeId: volumeId ?? this.volumeId,
    offset: offset ?? this.offset,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalReaderPositionRow copyWithCompanion(ReaderPositionsCompanion data) {
    return LocalReaderPositionRow(
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      offset: data.offset.present ? data.offset.value : this.offset,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReaderPositionRow(')
          ..write('volumeId: $volumeId, ')
          ..write('offset: $offset, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(volumeId, offset, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReaderPositionRow &&
          other.volumeId == this.volumeId &&
          other.offset == this.offset &&
          other.updatedAt == this.updatedAt);
}

class ReaderPositionsCompanion extends UpdateCompanion<LocalReaderPositionRow> {
  final Value<String> volumeId;
  final Value<double> offset;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReaderPositionsCompanion({
    this.volumeId = const Value.absent(),
    this.offset = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderPositionsCompanion.insert({
    required String volumeId,
    this.offset = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : volumeId = Value(volumeId),
       updatedAt = Value(updatedAt);
  static Insertable<LocalReaderPositionRow> custom({
    Expression<String>? volumeId,
    Expression<double>? offset,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (volumeId != null) 'volume_id': volumeId,
      if (offset != null) 'offset': offset,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderPositionsCompanion copyWith({
    Value<String>? volumeId,
    Value<double>? offset,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReaderPositionsCompanion(
      volumeId: volumeId ?? this.volumeId,
      offset: offset ?? this.offset,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (offset.present) {
      map['offset'] = Variable<double>(offset.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPositionsCompanion(')
          ..write('volumeId: $volumeId, ')
          ..write('offset: $offset, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, LocalSyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncTableNameMeta = const VerificationMeta(
    'syncTableName',
  );
  @override
  late final GeneratedColumn<String> syncTableName = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [syncTableName, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(
        _syncTableNameMeta,
        syncTableName.isAcceptableOrUnknown(
          data['table_name']!,
          _syncTableNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncTableNameMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncTableName};
  @override
  LocalSyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncStateRow(
      syncTableName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class LocalSyncStateRow extends DataClass
    implements Insertable<LocalSyncStateRow> {
  final String syncTableName;
  final DateTime? lastSyncedAt;
  const LocalSyncStateRow({required this.syncTableName, this.lastSyncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_name'] = Variable<String>(syncTableName);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      syncTableName: Value(syncTableName),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalSyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncStateRow(
      syncTableName: serializer.fromJson<String>(json['syncTableName']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'syncTableName': serializer.toJson<String>(syncTableName),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LocalSyncStateRow copyWith({
    String? syncTableName,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LocalSyncStateRow(
    syncTableName: syncTableName ?? this.syncTableName,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalSyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return LocalSyncStateRow(
      syncTableName: data.syncTableName.present
          ? data.syncTableName.value
          : this.syncTableName,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateRow(')
          ..write('syncTableName: $syncTableName, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(syncTableName, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncStateRow &&
          other.syncTableName == this.syncTableName &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncStateCompanion extends UpdateCompanion<LocalSyncStateRow> {
  final Value<String> syncTableName;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.syncTableName = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String syncTableName,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : syncTableName = Value(syncTableName);
  static Insertable<LocalSyncStateRow> custom({
    Expression<String>? syncTableName,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncTableName != null) 'table_name': syncTableName,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? syncTableName,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      syncTableName: syncTableName ?? this.syncTableName,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncTableName.present) {
      map['table_name'] = Variable<String>(syncTableName.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('syncTableName: $syncTableName, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VolumesTable volumes = $VolumesTable(this);
  late final $DreamsTable dreams = $DreamsTable(this);
  late final $DreamElementsTable dreamElements = $DreamElementsTable(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $ScenesTable scenes = $ScenesTable(this);
  late final $PassagesTable passages = $PassagesTable(this);
  late final $ProgressEventsTable progressEvents = $ProgressEventsTable(this);
  late final $JobsTable jobs = $JobsTable(this);
  late final $LinkDecisionsTable linkDecisions = $LinkDecisionsTable(this);
  late final $DreamDraftsTable dreamDrafts = $DreamDraftsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $ReaderPositionsTable readerPositions = $ReaderPositionsTable(
    this,
  );
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    volumes,
    dreams,
    dreamElements,
    entities,
    scenes,
    passages,
    progressEvents,
    jobs,
    linkDecisions,
    dreamDrafts,
    outbox,
    readerPositions,
    syncState,
  ];
}

typedef $$VolumesTableCreateCompanionBuilder =
    VolumesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> userId,
      required int volNo,
      Value<String?> title,
      required String format,
      required String adaptation,
      required String style,
      required String narrativeVoice,
      required String status,
      required double targetMu,
      required double progressMu,
      Value<String> genreProfile,
      Value<String> genreDirective,
      Value<String?> coverMotifId,
      Value<int?> coverSeed,
      Value<String?> authorNote,
      Value<String?> prologueSceneId,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$VolumesTableUpdateCompanionBuilder =
    VolumesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> userId,
      Value<int> volNo,
      Value<String?> title,
      Value<String> format,
      Value<String> adaptation,
      Value<String> style,
      Value<String> narrativeVoice,
      Value<String> status,
      Value<double> targetMu,
      Value<double> progressMu,
      Value<String> genreProfile,
      Value<String> genreDirective,
      Value<String?> coverMotifId,
      Value<int?> coverSeed,
      Value<String?> authorNote,
      Value<String?> prologueSceneId,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$VolumesTableReferences
    extends BaseReferences<_$AppDatabase, $VolumesTable, LocalVolumeRow> {
  $$VolumesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DreamsTable, List<LocalDreamRow>>
  _dreamsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dreams,
    aliasName: 'volumes__id__dreams__volume_id',
  );

  $$DreamsTableProcessedTableManager get dreamsRefs {
    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dreamsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntitiesTable, List<LocalEntityRow>>
  _entitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entities,
    aliasName: 'volumes__id__entities__volume_id',
  );

  $$EntitiesTableProcessedTableManager get entitiesRefs {
    final manager = $$EntitiesTableTableManager(
      $_db,
      $_db.entities,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScenesTable, List<LocalSceneRow>>
  _scenesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scenes,
    aliasName: 'volumes__id__scenes__volume_id',
  );

  $$ScenesTableProcessedTableManager get scenesRefs {
    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProgressEventsTable, List<LocalProgressEventRow>>
  _progressEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.progressEvents,
    aliasName: 'volumes__id__progress_events__volume_id',
  );

  $$ProgressEventsTableProcessedTableManager get progressEventsRefs {
    final manager = $$ProgressEventsTableTableManager(
      $_db,
      $_db.progressEvents,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JobsTable, List<LocalJobRow>> _jobsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.jobs,
    aliasName: 'volumes__id__jobs__volume_id',
  );

  $$JobsTableProcessedTableManager get jobsRefs {
    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LinkDecisionsTable, List<LocalLinkDecisionRow>>
  _linkDecisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.linkDecisions,
    aliasName: 'volumes__id__link_decisions__volume_id',
  );

  $$LinkDecisionsTableProcessedTableManager get linkDecisionsRefs {
    final manager = $$LinkDecisionsTableTableManager(
      $_db,
      $_db.linkDecisions,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_linkDecisionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ReaderPositionsTable,
    List<LocalReaderPositionRow>
  >
  _readerPositionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readerPositions,
    aliasName: 'volumes__id__reader_positions__volume_id',
  );

  $$ReaderPositionsTableProcessedTableManager get readerPositionsRefs {
    final manager = $$ReaderPositionsTableTableManager(
      $_db,
      $_db.readerPositions,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readerPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VolumesTableFilterComposer
    extends Composer<_$AppDatabase, $VolumesTable> {
  $$VolumesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volNo => $composableBuilder(
    column: $table.volNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adaptation => $composableBuilder(
    column: $table.adaptation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrativeVoice => $composableBuilder(
    column: $table.narrativeVoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetMu => $composableBuilder(
    column: $table.targetMu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressMu => $composableBuilder(
    column: $table.progressMu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreProfile => $composableBuilder(
    column: $table.genreProfile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreDirective => $composableBuilder(
    column: $table.genreDirective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverMotifId => $composableBuilder(
    column: $table.coverMotifId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverSeed => $composableBuilder(
    column: $table.coverSeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorNote => $composableBuilder(
    column: $table.authorNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prologueSceneId => $composableBuilder(
    column: $table.prologueSceneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dreamsRefs(
    Expression<bool> Function($$DreamsTableFilterComposer f) f,
  ) {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> entitiesRefs(
    Expression<bool> Function($$EntitiesTableFilterComposer f) f,
  ) {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scenesRefs(
    Expression<bool> Function($$ScenesTableFilterComposer f) f,
  ) {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> progressEventsRefs(
    Expression<bool> Function($$ProgressEventsTableFilterComposer f) f,
  ) {
    final $$ProgressEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressEvents,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressEventsTableFilterComposer(
            $db: $db,
            $table: $db.progressEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jobsRefs(
    Expression<bool> Function($$JobsTableFilterComposer f) f,
  ) {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> linkDecisionsRefs(
    Expression<bool> Function($$LinkDecisionsTableFilterComposer f) f,
  ) {
    final $$LinkDecisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.linkDecisions,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkDecisionsTableFilterComposer(
            $db: $db,
            $table: $db.linkDecisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readerPositionsRefs(
    Expression<bool> Function($$ReaderPositionsTableFilterComposer f) f,
  ) {
    final $$ReaderPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerPositions,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderPositionsTableFilterComposer(
            $db: $db,
            $table: $db.readerPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VolumesTableOrderingComposer
    extends Composer<_$AppDatabase, $VolumesTable> {
  $$VolumesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volNo => $composableBuilder(
    column: $table.volNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adaptation => $composableBuilder(
    column: $table.adaptation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrativeVoice => $composableBuilder(
    column: $table.narrativeVoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetMu => $composableBuilder(
    column: $table.targetMu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressMu => $composableBuilder(
    column: $table.progressMu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreProfile => $composableBuilder(
    column: $table.genreProfile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreDirective => $composableBuilder(
    column: $table.genreDirective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverMotifId => $composableBuilder(
    column: $table.coverMotifId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverSeed => $composableBuilder(
    column: $table.coverSeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorNote => $composableBuilder(
    column: $table.authorNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prologueSceneId => $composableBuilder(
    column: $table.prologueSceneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VolumesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VolumesTable> {
  $$VolumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get volNo =>
      $composableBuilder(column: $table.volNo, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get adaptation => $composableBuilder(
    column: $table.adaptation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get narrativeVoice => $composableBuilder(
    column: $table.narrativeVoice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get targetMu =>
      $composableBuilder(column: $table.targetMu, builder: (column) => column);

  GeneratedColumn<double> get progressMu => $composableBuilder(
    column: $table.progressMu,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genreProfile => $composableBuilder(
    column: $table.genreProfile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genreDirective => $composableBuilder(
    column: $table.genreDirective,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverMotifId => $composableBuilder(
    column: $table.coverMotifId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coverSeed =>
      $composableBuilder(column: $table.coverSeed, builder: (column) => column);

  GeneratedColumn<String> get authorNote => $composableBuilder(
    column: $table.authorNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prologueSceneId => $composableBuilder(
    column: $table.prologueSceneId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  Expression<T> dreamsRefs<T extends Object>(
    Expression<T> Function($$DreamsTableAnnotationComposer a) f,
  ) {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> entitiesRefs<T extends Object>(
    Expression<T> Function($$EntitiesTableAnnotationComposer a) f,
  ) {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scenesRefs<T extends Object>(
    Expression<T> Function($$ScenesTableAnnotationComposer a) f,
  ) {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> progressEventsRefs<T extends Object>(
    Expression<T> Function($$ProgressEventsTableAnnotationComposer a) f,
  ) {
    final $$ProgressEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressEvents,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.progressEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jobsRefs<T extends Object>(
    Expression<T> Function($$JobsTableAnnotationComposer a) f,
  ) {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> linkDecisionsRefs<T extends Object>(
    Expression<T> Function($$LinkDecisionsTableAnnotationComposer a) f,
  ) {
    final $$LinkDecisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.linkDecisions,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkDecisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.linkDecisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readerPositionsRefs<T extends Object>(
    Expression<T> Function($$ReaderPositionsTableAnnotationComposer a) f,
  ) {
    final $$ReaderPositionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerPositions,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderPositionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readerPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VolumesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VolumesTable,
          LocalVolumeRow,
          $$VolumesTableFilterComposer,
          $$VolumesTableOrderingComposer,
          $$VolumesTableAnnotationComposer,
          $$VolumesTableCreateCompanionBuilder,
          $$VolumesTableUpdateCompanionBuilder,
          (LocalVolumeRow, $$VolumesTableReferences),
          LocalVolumeRow,
          PrefetchHooks Function({
            bool dreamsRefs,
            bool entitiesRefs,
            bool scenesRefs,
            bool progressEventsRefs,
            bool jobsRefs,
            bool linkDecisionsRefs,
            bool readerPositionsRefs,
          })
        > {
  $$VolumesTableTableManager(_$AppDatabase db, $VolumesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VolumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VolumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VolumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> volNo = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> adaptation = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<String> narrativeVoice = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> targetMu = const Value.absent(),
                Value<double> progressMu = const Value.absent(),
                Value<String> genreProfile = const Value.absent(),
                Value<String> genreDirective = const Value.absent(),
                Value<String?> coverMotifId = const Value.absent(),
                Value<int?> coverSeed = const Value.absent(),
                Value<String?> authorNote = const Value.absent(),
                Value<String?> prologueSceneId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                volNo: volNo,
                title: title,
                format: format,
                adaptation: adaptation,
                style: style,
                narrativeVoice: narrativeVoice,
                status: status,
                targetMu: targetMu,
                progressMu: progressMu,
                genreProfile: genreProfile,
                genreDirective: genreDirective,
                coverMotifId: coverMotifId,
                coverSeed: coverSeed,
                authorNote: authorNote,
                prologueSceneId: prologueSceneId,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> userId = const Value.absent(),
                required int volNo,
                Value<String?> title = const Value.absent(),
                required String format,
                required String adaptation,
                required String style,
                required String narrativeVoice,
                required String status,
                required double targetMu,
                required double progressMu,
                Value<String> genreProfile = const Value.absent(),
                Value<String> genreDirective = const Value.absent(),
                Value<String?> coverMotifId = const Value.absent(),
                Value<int?> coverSeed = const Value.absent(),
                Value<String?> authorNote = const Value.absent(),
                Value<String?> prologueSceneId = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                volNo: volNo,
                title: title,
                format: format,
                adaptation: adaptation,
                style: style,
                narrativeVoice: narrativeVoice,
                status: status,
                targetMu: targetMu,
                progressMu: progressMu,
                genreProfile: genreProfile,
                genreDirective: genreDirective,
                coverMotifId: coverMotifId,
                coverSeed: coverSeed,
                authorNote: authorNote,
                prologueSceneId: prologueSceneId,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VolumesTable, LocalVolumeRow>(table),
                  $$VolumesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dreamsRefs = false,
                entitiesRefs = false,
                scenesRefs = false,
                progressEventsRefs = false,
                jobsRefs = false,
                linkDecisionsRefs = false,
                readerPositionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dreamsRefs) db.dreams,
                    if (entitiesRefs) db.entities,
                    if (scenesRefs) db.scenes,
                    if (progressEventsRefs) db.progressEvents,
                    if (jobsRefs) db.jobs,
                    if (linkDecisionsRefs) db.linkDecisions,
                    if (readerPositionsRefs) db.readerPositions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dreamsRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalDreamRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._dreamsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).dreamsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (entitiesRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalEntityRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._entitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).entitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scenesRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalSceneRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._scenesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).scenesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (progressEventsRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalProgressEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._progressEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).progressEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jobsRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalJobRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._jobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(db, table, p0).jobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (linkDecisionsRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalLinkDecisionRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._linkDecisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).linkDecisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readerPositionsRefs)
                        await $_getPrefetchedData<
                          LocalVolumeRow,
                          $VolumesTable,
                          LocalReaderPositionRow
                        >(
                          currentTable: table,
                          referencedTable: $$VolumesTableReferences
                              ._readerPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VolumesTableReferences(
                                db,
                                table,
                                p0,
                              ).readerPositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.volumeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VolumesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VolumesTable,
      LocalVolumeRow,
      $$VolumesTableFilterComposer,
      $$VolumesTableOrderingComposer,
      $$VolumesTableAnnotationComposer,
      $$VolumesTableCreateCompanionBuilder,
      $$VolumesTableUpdateCompanionBuilder,
      (LocalVolumeRow, $$VolumesTableReferences),
      LocalVolumeRow,
      PrefetchHooks Function({
        bool dreamsRefs,
        bool entitiesRefs,
        bool scenesRefs,
        bool progressEventsRefs,
        bool jobsRefs,
        bool linkDecisionsRefs,
        bool readerPositionsRefs,
      })
    >;
typedef $$DreamsTableCreateCompanionBuilder =
    DreamsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> userId,
      Value<String?> volumeId,
      required DateTime dreamDate,
      required DateTime recordedAt,
      required String inputMode,
      required String rawText,
      Value<DateTime?> rawTextEditedAt,
      Value<String> recallAnswers,
      Value<String?> clarity,
      required String status,
      Value<String> sensitiveFlags,
      Value<bool> isBackfill,
      Value<int> rowid,
    });
typedef $$DreamsTableUpdateCompanionBuilder =
    DreamsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> userId,
      Value<String?> volumeId,
      Value<DateTime> dreamDate,
      Value<DateTime> recordedAt,
      Value<String> inputMode,
      Value<String> rawText,
      Value<DateTime?> rawTextEditedAt,
      Value<String> recallAnswers,
      Value<String?> clarity,
      Value<String> status,
      Value<String> sensitiveFlags,
      Value<bool> isBackfill,
      Value<int> rowid,
    });

final class $$DreamsTableReferences
    extends BaseReferences<_$AppDatabase, $DreamsTable, LocalDreamRow> {
  $$DreamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('dreams__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager? get volumeId {
    final $_column = $_itemColumn<String>('volume_id');
    if ($_column == null) return null;
    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DreamElementsTable, List<LocalDreamElementRow>>
  _dreamElementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dreamElements,
    aliasName: 'dreams__id__dream_elements__dream_id',
  );

  $$DreamElementsTableProcessedTableManager get dreamElementsRefs {
    final manager = $$DreamElementsTableTableManager(
      $_db,
      $_db.dreamElements,
    ).filter((f) => f.dreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dreamElementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PassagesTable, List<LocalPassageRow>>
  _passagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.passages,
    aliasName: 'dreams__id__passages__source_dream_id',
  );

  $$PassagesTableProcessedTableManager get passagesRefs {
    final manager = $$PassagesTableTableManager(
      $_db,
      $_db.passages,
    ).filter((f) => f.sourceDreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_passagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProgressEventsTable, List<LocalProgressEventRow>>
  _progressEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.progressEvents,
    aliasName: 'dreams__id__progress_events__dream_id',
  );

  $$ProgressEventsTableProcessedTableManager get progressEventsRefs {
    final manager = $$ProgressEventsTableTableManager(
      $_db,
      $_db.progressEvents,
    ).filter((f) => f.dreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JobsTable, List<LocalJobRow>> _jobsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.jobs,
    aliasName: 'dreams__id__jobs__dream_id',
  );

  $$JobsTableProcessedTableManager get jobsRefs {
    final manager = $$JobsTableTableManager(
      $_db,
      $_db.jobs,
    ).filter((f) => f.dreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_jobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LinkDecisionsTable, List<LocalLinkDecisionRow>>
  _linkDecisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.linkDecisions,
    aliasName: 'dreams__id__link_decisions__dream_id',
  );

  $$LinkDecisionsTableProcessedTableManager get linkDecisionsRefs {
    final manager = $$LinkDecisionsTableTableManager(
      $_db,
      $_db.linkDecisions,
    ).filter((f) => f.dreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_linkDecisionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DreamsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dreamDate => $composableBuilder(
    column: $table.dreamDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get rawTextEditedAt => $composableBuilder(
    column: $table.rawTextEditedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recallAnswers => $composableBuilder(
    column: $table.recallAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clarity => $composableBuilder(
    column: $table.clarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensitiveFlags => $composableBuilder(
    column: $table.sensitiveFlags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> dreamElementsRefs(
    Expression<bool> Function($$DreamElementsTableFilterComposer f) f,
  ) {
    final $$DreamElementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamElements,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamElementsTableFilterComposer(
            $db: $db,
            $table: $db.dreamElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> passagesRefs(
    Expression<bool> Function($$PassagesTableFilterComposer f) f,
  ) {
    final $$PassagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.sourceDreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableFilterComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> progressEventsRefs(
    Expression<bool> Function($$ProgressEventsTableFilterComposer f) f,
  ) {
    final $$ProgressEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressEvents,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressEventsTableFilterComposer(
            $db: $db,
            $table: $db.progressEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> jobsRefs(
    Expression<bool> Function($$JobsTableFilterComposer f) f,
  ) {
    final $$JobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableFilterComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> linkDecisionsRefs(
    Expression<bool> Function($$LinkDecisionsTableFilterComposer f) f,
  ) {
    final $$LinkDecisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.linkDecisions,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkDecisionsTableFilterComposer(
            $db: $db,
            $table: $db.linkDecisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DreamsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dreamDate => $composableBuilder(
    column: $table.dreamDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get rawTextEditedAt => $composableBuilder(
    column: $table.rawTextEditedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recallAnswers => $composableBuilder(
    column: $table.recallAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clarity => $composableBuilder(
    column: $table.clarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensitiveFlags => $composableBuilder(
    column: $table.sensitiveFlags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamsTable> {
  $$DreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get dreamDate =>
      $composableBuilder(column: $table.dreamDate, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<DateTime> get rawTextEditedAt => $composableBuilder(
    column: $table.rawTextEditedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recallAnswers => $composableBuilder(
    column: $table.recallAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clarity =>
      $composableBuilder(column: $table.clarity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sensitiveFlags => $composableBuilder(
    column: $table.sensitiveFlags,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => column,
  );

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> dreamElementsRefs<T extends Object>(
    Expression<T> Function($$DreamElementsTableAnnotationComposer a) f,
  ) {
    final $$DreamElementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamElements,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamElementsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreamElements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> passagesRefs<T extends Object>(
    Expression<T> Function($$PassagesTableAnnotationComposer a) f,
  ) {
    final $$PassagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.sourceDreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableAnnotationComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> progressEventsRefs<T extends Object>(
    Expression<T> Function($$ProgressEventsTableAnnotationComposer a) f,
  ) {
    final $$ProgressEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressEvents,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.progressEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> jobsRefs<T extends Object>(
    Expression<T> Function($$JobsTableAnnotationComposer a) f,
  ) {
    final $$JobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.jobs,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JobsTableAnnotationComposer(
            $db: $db,
            $table: $db.jobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> linkDecisionsRefs<T extends Object>(
    Expression<T> Function($$LinkDecisionsTableAnnotationComposer a) f,
  ) {
    final $$LinkDecisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.linkDecisions,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinkDecisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.linkDecisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DreamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamsTable,
          LocalDreamRow,
          $$DreamsTableFilterComposer,
          $$DreamsTableOrderingComposer,
          $$DreamsTableAnnotationComposer,
          $$DreamsTableCreateCompanionBuilder,
          $$DreamsTableUpdateCompanionBuilder,
          (LocalDreamRow, $$DreamsTableReferences),
          LocalDreamRow,
          PrefetchHooks Function({
            bool volumeId,
            bool dreamElementsRefs,
            bool passagesRefs,
            bool progressEventsRefs,
            bool jobsRefs,
            bool linkDecisionsRefs,
          })
        > {
  $$DreamsTableTableManager(_$AppDatabase db, $DreamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> volumeId = const Value.absent(),
                Value<DateTime> dreamDate = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> inputMode = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<DateTime?> rawTextEditedAt = const Value.absent(),
                Value<String> recallAnswers = const Value.absent(),
                Value<String?> clarity = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> sensitiveFlags = const Value.absent(),
                Value<bool> isBackfill = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                volumeId: volumeId,
                dreamDate: dreamDate,
                recordedAt: recordedAt,
                inputMode: inputMode,
                rawText: rawText,
                rawTextEditedAt: rawTextEditedAt,
                recallAnswers: recallAnswers,
                clarity: clarity,
                status: status,
                sensitiveFlags: sensitiveFlags,
                isBackfill: isBackfill,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> userId = const Value.absent(),
                Value<String?> volumeId = const Value.absent(),
                required DateTime dreamDate,
                required DateTime recordedAt,
                required String inputMode,
                required String rawText,
                Value<DateTime?> rawTextEditedAt = const Value.absent(),
                Value<String> recallAnswers = const Value.absent(),
                Value<String?> clarity = const Value.absent(),
                required String status,
                Value<String> sensitiveFlags = const Value.absent(),
                Value<bool> isBackfill = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                volumeId: volumeId,
                dreamDate: dreamDate,
                recordedAt: recordedAt,
                inputMode: inputMode,
                rawText: rawText,
                rawTextEditedAt: rawTextEditedAt,
                recallAnswers: recallAnswers,
                clarity: clarity,
                status: status,
                sensitiveFlags: sensitiveFlags,
                isBackfill: isBackfill,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DreamsTable, LocalDreamRow>(table),
                  $$DreamsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                volumeId = false,
                dreamElementsRefs = false,
                passagesRefs = false,
                progressEventsRefs = false,
                jobsRefs = false,
                linkDecisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dreamElementsRefs) db.dreamElements,
                    if (passagesRefs) db.passages,
                    if (progressEventsRefs) db.progressEvents,
                    if (jobsRefs) db.jobs,
                    if (linkDecisionsRefs) db.linkDecisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (volumeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.volumeId,
                                    referencedTable: $$DreamsTableReferences
                                        ._volumeIdTable(db),
                                    referencedColumn: $$DreamsTableReferences
                                        ._volumeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dreamElementsRefs)
                        await $_getPrefetchedData<
                          LocalDreamRow,
                          $DreamsTable,
                          LocalDreamElementRow
                        >(
                          currentTable: table,
                          referencedTable: $$DreamsTableReferences
                              ._dreamElementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DreamsTableReferences(
                                db,
                                table,
                                p0,
                              ).dreamElementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dreamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (passagesRefs)
                        await $_getPrefetchedData<
                          LocalDreamRow,
                          $DreamsTable,
                          LocalPassageRow
                        >(
                          currentTable: table,
                          referencedTable: $$DreamsTableReferences
                              ._passagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DreamsTableReferences(
                                db,
                                table,
                                p0,
                              ).passagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceDreamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (progressEventsRefs)
                        await $_getPrefetchedData<
                          LocalDreamRow,
                          $DreamsTable,
                          LocalProgressEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$DreamsTableReferences
                              ._progressEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DreamsTableReferences(
                                db,
                                table,
                                p0,
                              ).progressEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dreamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (jobsRefs)
                        await $_getPrefetchedData<
                          LocalDreamRow,
                          $DreamsTable,
                          LocalJobRow
                        >(
                          currentTable: table,
                          referencedTable: $$DreamsTableReferences
                              ._jobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DreamsTableReferences(db, table, p0).jobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dreamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (linkDecisionsRefs)
                        await $_getPrefetchedData<
                          LocalDreamRow,
                          $DreamsTable,
                          LocalLinkDecisionRow
                        >(
                          currentTable: table,
                          referencedTable: $$DreamsTableReferences
                              ._linkDecisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DreamsTableReferences(
                                db,
                                table,
                                p0,
                              ).linkDecisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.dreamId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DreamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamsTable,
      LocalDreamRow,
      $$DreamsTableFilterComposer,
      $$DreamsTableOrderingComposer,
      $$DreamsTableAnnotationComposer,
      $$DreamsTableCreateCompanionBuilder,
      $$DreamsTableUpdateCompanionBuilder,
      (LocalDreamRow, $$DreamsTableReferences),
      LocalDreamRow,
      PrefetchHooks Function({
        bool volumeId,
        bool dreamElementsRefs,
        bool passagesRefs,
        bool progressEventsRefs,
        bool jobsRefs,
        bool linkDecisionsRefs,
      })
    >;
typedef $$DreamElementsTableCreateCompanionBuilder =
    DreamElementsCompanion Function({
      required String id,
      required String dreamId,
      required String type,
      required String label,
      Value<String?> detail,
      required String salience,
      required String source,
      Value<String?> span,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DreamElementsTableUpdateCompanionBuilder =
    DreamElementsCompanion Function({
      Value<String> id,
      Value<String> dreamId,
      Value<String> type,
      Value<String> label,
      Value<String?> detail,
      Value<String> salience,
      Value<String> source,
      Value<String?> span,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$DreamElementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DreamElementsTable,
          LocalDreamElementRow
        > {
  $$DreamElementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DreamsTable _dreamIdTable(_$AppDatabase db) =>
      db.dreams.createAlias('dream_elements__dream_id__dreams__id');

  $$DreamsTableProcessedTableManager get dreamId {
    final $_column = $_itemColumn<String>('dream_id')!;

    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DreamElementsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamElementsTable> {
  $$DreamElementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salience => $composableBuilder(
    column: $table.salience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get span => $composableBuilder(
    column: $table.span,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DreamsTableFilterComposer get dreamId {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamElementsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamElementsTable> {
  $$DreamElementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salience => $composableBuilder(
    column: $table.salience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get span => $composableBuilder(
    column: $table.span,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DreamsTableOrderingComposer get dreamId {
    final $$DreamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableOrderingComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamElementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamElementsTable> {
  $$DreamElementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<String> get salience =>
      $composableBuilder(column: $table.salience, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get span =>
      $composableBuilder(column: $table.span, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DreamsTableAnnotationComposer get dreamId {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamElementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamElementsTable,
          LocalDreamElementRow,
          $$DreamElementsTableFilterComposer,
          $$DreamElementsTableOrderingComposer,
          $$DreamElementsTableAnnotationComposer,
          $$DreamElementsTableCreateCompanionBuilder,
          $$DreamElementsTableUpdateCompanionBuilder,
          (LocalDreamElementRow, $$DreamElementsTableReferences),
          LocalDreamElementRow,
          PrefetchHooks Function({bool dreamId})
        > {
  $$DreamElementsTableTableManager(_$AppDatabase db, $DreamElementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamElementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamElementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamElementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dreamId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<String> salience = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> span = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamElementsCompanion(
                id: id,
                dreamId: dreamId,
                type: type,
                label: label,
                detail: detail,
                salience: salience,
                source: source,
                span: span,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dreamId,
                required String type,
                required String label,
                Value<String?> detail = const Value.absent(),
                required String salience,
                required String source,
                Value<String?> span = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DreamElementsCompanion.insert(
                id: id,
                dreamId: dreamId,
                type: type,
                label: label,
                detail: detail,
                salience: salience,
                source: source,
                span: span,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DreamElementsTable, LocalDreamElementRow>(table),
                  $$DreamElementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dreamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dreamId,
                                referencedTable: $$DreamElementsTableReferences
                                    ._dreamIdTable(db),
                                referencedColumn: $$DreamElementsTableReferences
                                    ._dreamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DreamElementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamElementsTable,
      LocalDreamElementRow,
      $$DreamElementsTableFilterComposer,
      $$DreamElementsTableOrderingComposer,
      $$DreamElementsTableAnnotationComposer,
      $$DreamElementsTableCreateCompanionBuilder,
      $$DreamElementsTableUpdateCompanionBuilder,
      (LocalDreamElementRow, $$DreamElementsTableReferences),
      LocalDreamElementRow,
      PrefetchHooks Function({bool dreamId})
    >;
typedef $$EntitiesTableCreateCompanionBuilder =
    EntitiesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String volumeId,
      required String type,
      required String roleName,
      Value<String?> description,
      Value<String> aliases,
      required String status,
      Value<String?> firstSceneId,
      Value<int> mentionCount,
      Value<int> rowid,
    });
typedef $$EntitiesTableUpdateCompanionBuilder =
    EntitiesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> volumeId,
      Value<String> type,
      Value<String> roleName,
      Value<String?> description,
      Value<String> aliases,
      Value<String> status,
      Value<String?> firstSceneId,
      Value<int> mentionCount,
      Value<int> rowid,
    });

final class $$EntitiesTableReferences
    extends BaseReferences<_$AppDatabase, $EntitiesTable, LocalEntityRow> {
  $$EntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('entities__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstSceneId => $composableBuilder(
    column: $table.firstSceneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstSceneId => $composableBuilder(
    column: $table.firstSceneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get firstSceneId => $composableBuilder(
    column: $table.firstSceneId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => column,
  );

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitiesTable,
          LocalEntityRow,
          $$EntitiesTableFilterComposer,
          $$EntitiesTableOrderingComposer,
          $$EntitiesTableAnnotationComposer,
          $$EntitiesTableCreateCompanionBuilder,
          $$EntitiesTableUpdateCompanionBuilder,
          (LocalEntityRow, $$EntitiesTableReferences),
          LocalEntityRow,
          PrefetchHooks Function({bool volumeId})
        > {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> roleName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> firstSceneId = const Value.absent(),
                Value<int> mentionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                volumeId: volumeId,
                type: type,
                roleName: roleName,
                description: description,
                aliases: aliases,
                status: status,
                firstSceneId: firstSceneId,
                mentionCount: mentionCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String volumeId,
                required String type,
                required String roleName,
                Value<String?> description = const Value.absent(),
                Value<String> aliases = const Value.absent(),
                required String status,
                Value<String?> firstSceneId = const Value.absent(),
                Value<int> mentionCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                volumeId: volumeId,
                type: type,
                roleName: roleName,
                description: description,
                aliases: aliases,
                status: status,
                firstSceneId: firstSceneId,
                mentionCount: mentionCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitiesTable, LocalEntityRow>(table),
                  $$EntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({volumeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable: $$EntitiesTableReferences
                                    ._volumeIdTable(db),
                                referencedColumn: $$EntitiesTableReferences
                                    ._volumeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitiesTable,
      LocalEntityRow,
      $$EntitiesTableFilterComposer,
      $$EntitiesTableOrderingComposer,
      $$EntitiesTableAnnotationComposer,
      $$EntitiesTableCreateCompanionBuilder,
      $$EntitiesTableUpdateCompanionBuilder,
      (LocalEntityRow, $$EntitiesTableReferences),
      LocalEntityRow,
      PrefetchHooks Function({bool volumeId})
    >;
typedef $$ScenesTableCreateCompanionBuilder =
    ScenesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String volumeId,
      required String orderKey,
      Value<int?> chapterNo,
      required String kind,
      required String placement,
      Value<String?> title,
      Value<String> sourceDreamIds,
      Value<int> version,
      Value<String?> openImage,
      Value<int> rowid,
    });
typedef $$ScenesTableUpdateCompanionBuilder =
    ScenesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> volumeId,
      Value<String> orderKey,
      Value<int?> chapterNo,
      Value<String> kind,
      Value<String> placement,
      Value<String?> title,
      Value<String> sourceDreamIds,
      Value<int> version,
      Value<String?> openImage,
      Value<int> rowid,
    });

final class $$ScenesTableReferences
    extends BaseReferences<_$AppDatabase, $ScenesTable, LocalSceneRow> {
  $$ScenesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('scenes__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PassagesTable, List<LocalPassageRow>>
  _passagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.passages,
    aliasName: 'scenes__id__passages__scene_id',
  );

  $$PassagesTableProcessedTableManager get passagesRefs {
    final manager = $$PassagesTableTableManager(
      $_db,
      $_db.passages,
    ).filter((f) => f.sceneId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_passagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScenesTableFilterComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDreamIds => $composableBuilder(
    column: $table.sourceDreamIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openImage => $composableBuilder(
    column: $table.openImage,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> passagesRefs(
    Expression<bool> Function($$PassagesTableFilterComposer f) f,
  ) {
    final $$PassagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.sceneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableFilterComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScenesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placement => $composableBuilder(
    column: $table.placement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDreamIds => $composableBuilder(
    column: $table.sourceDreamIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openImage => $composableBuilder(
    column: $table.openImage,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScenesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<int> get chapterNo =>
      $composableBuilder(column: $table.chapterNo, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get placement =>
      $composableBuilder(column: $table.placement, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceDreamIds => $composableBuilder(
    column: $table.sourceDreamIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get openImage =>
      $composableBuilder(column: $table.openImage, builder: (column) => column);

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> passagesRefs<T extends Object>(
    Expression<T> Function($$PassagesTableAnnotationComposer a) f,
  ) {
    final $$PassagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.passages,
      getReferencedColumn: (t) => t.sceneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PassagesTableAnnotationComposer(
            $db: $db,
            $table: $db.passages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScenesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScenesTable,
          LocalSceneRow,
          $$ScenesTableFilterComposer,
          $$ScenesTableOrderingComposer,
          $$ScenesTableAnnotationComposer,
          $$ScenesTableCreateCompanionBuilder,
          $$ScenesTableUpdateCompanionBuilder,
          (LocalSceneRow, $$ScenesTableReferences),
          LocalSceneRow,
          PrefetchHooks Function({bool volumeId, bool passagesRefs})
        > {
  $$ScenesTableTableManager(_$AppDatabase db, $ScenesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<int?> chapterNo = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> placement = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> sourceDreamIds = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> openImage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScenesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                volumeId: volumeId,
                orderKey: orderKey,
                chapterNo: chapterNo,
                kind: kind,
                placement: placement,
                title: title,
                sourceDreamIds: sourceDreamIds,
                version: version,
                openImage: openImage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String volumeId,
                required String orderKey,
                Value<int?> chapterNo = const Value.absent(),
                required String kind,
                required String placement,
                Value<String?> title = const Value.absent(),
                Value<String> sourceDreamIds = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> openImage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScenesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                volumeId: volumeId,
                orderKey: orderKey,
                chapterNo: chapterNo,
                kind: kind,
                placement: placement,
                title: title,
                sourceDreamIds: sourceDreamIds,
                version: version,
                openImage: openImage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScenesTable, LocalSceneRow>(table),
                  $$ScenesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({volumeId = false, passagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (passagesRefs) db.passages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable: $$ScenesTableReferences
                                    ._volumeIdTable(db),
                                referencedColumn: $$ScenesTableReferences
                                    ._volumeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (passagesRefs)
                    await $_getPrefetchedData<
                      LocalSceneRow,
                      $ScenesTable,
                      LocalPassageRow
                    >(
                      currentTable: table,
                      referencedTable: $$ScenesTableReferences
                          ._passagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScenesTableReferences(db, table, p0).passagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sceneId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ScenesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScenesTable,
      LocalSceneRow,
      $$ScenesTableFilterComposer,
      $$ScenesTableOrderingComposer,
      $$ScenesTableAnnotationComposer,
      $$ScenesTableCreateCompanionBuilder,
      $$ScenesTableUpdateCompanionBuilder,
      (LocalSceneRow, $$ScenesTableReferences),
      LocalSceneRow,
      PrefetchHooks Function({bool volumeId, bool passagesRefs})
    >;
typedef $$PassagesTableCreateCompanionBuilder =
    PassagesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> userId,
      required String sceneId,
      required String orderKey,
      required String content,
      required String origin,
      Value<String?> sourceDreamId,
      Value<String> sourceElementIds,
      Value<String?> cReason,
      Value<String?> originalText,
      Value<bool> locked,
      required String createdBy,
      Value<DateTime?> firstReadAt,
      Value<int> rowid,
    });
typedef $$PassagesTableUpdateCompanionBuilder =
    PassagesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> userId,
      Value<String> sceneId,
      Value<String> orderKey,
      Value<String> content,
      Value<String> origin,
      Value<String?> sourceDreamId,
      Value<String> sourceElementIds,
      Value<String?> cReason,
      Value<String?> originalText,
      Value<bool> locked,
      Value<String> createdBy,
      Value<DateTime?> firstReadAt,
      Value<int> rowid,
    });

final class $$PassagesTableReferences
    extends BaseReferences<_$AppDatabase, $PassagesTable, LocalPassageRow> {
  $$PassagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScenesTable _sceneIdTable(_$AppDatabase db) =>
      db.scenes.createAlias('passages__scene_id__scenes__id');

  $$ScenesTableProcessedTableManager get sceneId {
    final $_column = $_itemColumn<String>('scene_id')!;

    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sceneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DreamsTable _sourceDreamIdTable(_$AppDatabase db) =>
      db.dreams.createAlias('passages__source_dream_id__dreams__id');

  $$DreamsTableProcessedTableManager? get sourceDreamId {
    final $_column = $_itemColumn<String>('source_dream_id');
    if ($_column == null) return null;
    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceDreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PassagesTableFilterComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceElementIds => $composableBuilder(
    column: $table.sourceElementIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cReason => $composableBuilder(
    column: $table.cReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScenesTableFilterComposer get sceneId {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableFilterComposer get sourceDreamId {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceDreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderKey => $composableBuilder(
    column: $table.orderKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceElementIds => $composableBuilder(
    column: $table.sourceElementIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cReason => $composableBuilder(
    column: $table.cReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScenesTableOrderingComposer get sceneId {
    final $$ScenesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableOrderingComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableOrderingComposer get sourceDreamId {
    final $$DreamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceDreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableOrderingComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PassagesTable> {
  $$PassagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get orderKey =>
      $composableBuilder(column: $table.orderKey, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get sourceElementIds => $composableBuilder(
    column: $table.sourceElementIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cReason =>
      $composableBuilder(column: $table.cReason, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get firstReadAt => $composableBuilder(
    column: $table.firstReadAt,
    builder: (column) => column,
  );

  $$ScenesTableAnnotationComposer get sceneId {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableAnnotationComposer get sourceDreamId {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceDreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PassagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PassagesTable,
          LocalPassageRow,
          $$PassagesTableFilterComposer,
          $$PassagesTableOrderingComposer,
          $$PassagesTableAnnotationComposer,
          $$PassagesTableCreateCompanionBuilder,
          $$PassagesTableUpdateCompanionBuilder,
          (LocalPassageRow, $$PassagesTableReferences),
          LocalPassageRow,
          PrefetchHooks Function({bool sceneId, bool sourceDreamId})
        > {
  $$PassagesTableTableManager(_$AppDatabase db, $PassagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PassagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PassagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PassagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> sceneId = const Value.absent(),
                Value<String> orderKey = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> sourceDreamId = const Value.absent(),
                Value<String> sourceElementIds = const Value.absent(),
                Value<String?> cReason = const Value.absent(),
                Value<String?> originalText = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime?> firstReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassagesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                sceneId: sceneId,
                orderKey: orderKey,
                content: content,
                origin: origin,
                sourceDreamId: sourceDreamId,
                sourceElementIds: sourceElementIds,
                cReason: cReason,
                originalText: originalText,
                locked: locked,
                createdBy: createdBy,
                firstReadAt: firstReadAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> userId = const Value.absent(),
                required String sceneId,
                required String orderKey,
                required String content,
                required String origin,
                Value<String?> sourceDreamId = const Value.absent(),
                Value<String> sourceElementIds = const Value.absent(),
                Value<String?> cReason = const Value.absent(),
                Value<String?> originalText = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                required String createdBy,
                Value<DateTime?> firstReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PassagesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                sceneId: sceneId,
                orderKey: orderKey,
                content: content,
                origin: origin,
                sourceDreamId: sourceDreamId,
                sourceElementIds: sourceElementIds,
                cReason: cReason,
                originalText: originalText,
                locked: locked,
                createdBy: createdBy,
                firstReadAt: firstReadAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PassagesTable, LocalPassageRow>(table),
                  $$PassagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sceneId = false, sourceDreamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sceneId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sceneId,
                                referencedTable: $$PassagesTableReferences
                                    ._sceneIdTable(db),
                                referencedColumn: $$PassagesTableReferences
                                    ._sceneIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (sourceDreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceDreamId,
                                referencedTable: $$PassagesTableReferences
                                    ._sourceDreamIdTable(db),
                                referencedColumn: $$PassagesTableReferences
                                    ._sourceDreamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PassagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PassagesTable,
      LocalPassageRow,
      $$PassagesTableFilterComposer,
      $$PassagesTableOrderingComposer,
      $$PassagesTableAnnotationComposer,
      $$PassagesTableCreateCompanionBuilder,
      $$PassagesTableUpdateCompanionBuilder,
      (LocalPassageRow, $$PassagesTableReferences),
      LocalPassageRow,
      PrefetchHooks Function({bool sceneId, bool sourceDreamId})
    >;
typedef $$ProgressEventsTableCreateCompanionBuilder =
    ProgressEventsCompanion Function({
      required String id,
      Value<String> userId,
      required String volumeId,
      Value<String?> dreamId,
      required double deltaMu,
      Value<String> reasons,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProgressEventsTableUpdateCompanionBuilder =
    ProgressEventsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> volumeId,
      Value<String?> dreamId,
      Value<double> deltaMu,
      Value<String> reasons,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ProgressEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProgressEventsTable,
          LocalProgressEventRow
        > {
  $$ProgressEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('progress_events__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DreamsTable _dreamIdTable(_$AppDatabase db) =>
      db.dreams.createAlias('progress_events__dream_id__dreams__id');

  $$DreamsTableProcessedTableManager? get dreamId {
    final $_column = $_itemColumn<String>('dream_id');
    if ($_column == null) return null;
    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgressEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressEventsTable> {
  $$ProgressEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deltaMu => $composableBuilder(
    column: $table.deltaMu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableFilterComposer get dreamId {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressEventsTable> {
  $$ProgressEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deltaMu => $composableBuilder(
    column: $table.deltaMu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasons => $composableBuilder(
    column: $table.reasons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableOrderingComposer get dreamId {
    final $$DreamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableOrderingComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressEventsTable> {
  $$ProgressEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get deltaMu =>
      $composableBuilder(column: $table.deltaMu, builder: (column) => column);

  GeneratedColumn<String> get reasons =>
      $composableBuilder(column: $table.reasons, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableAnnotationComposer get dreamId {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressEventsTable,
          LocalProgressEventRow,
          $$ProgressEventsTableFilterComposer,
          $$ProgressEventsTableOrderingComposer,
          $$ProgressEventsTableAnnotationComposer,
          $$ProgressEventsTableCreateCompanionBuilder,
          $$ProgressEventsTableUpdateCompanionBuilder,
          (LocalProgressEventRow, $$ProgressEventsTableReferences),
          LocalProgressEventRow,
          PrefetchHooks Function({bool volumeId, bool dreamId})
        > {
  $$ProgressEventsTableTableManager(
    _$AppDatabase db,
    $ProgressEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String?> dreamId = const Value.absent(),
                Value<double> deltaMu = const Value.absent(),
                Value<String> reasons = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressEventsCompanion(
                id: id,
                userId: userId,
                volumeId: volumeId,
                dreamId: dreamId,
                deltaMu: deltaMu,
                reasons: reasons,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> userId = const Value.absent(),
                required String volumeId,
                Value<String?> dreamId = const Value.absent(),
                required double deltaMu,
                Value<String> reasons = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressEventsCompanion.insert(
                id: id,
                userId: userId,
                volumeId: volumeId,
                dreamId: dreamId,
                deltaMu: deltaMu,
                reasons: reasons,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressEventsTable, LocalProgressEventRow>(
                    table,
                  ),
                  $$ProgressEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({volumeId = false, dreamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable: $$ProgressEventsTableReferences
                                    ._volumeIdTable(db),
                                referencedColumn:
                                    $$ProgressEventsTableReferences
                                        ._volumeIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (dreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dreamId,
                                referencedTable: $$ProgressEventsTableReferences
                                    ._dreamIdTable(db),
                                referencedColumn:
                                    $$ProgressEventsTableReferences
                                        ._dreamIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgressEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressEventsTable,
      LocalProgressEventRow,
      $$ProgressEventsTableFilterComposer,
      $$ProgressEventsTableOrderingComposer,
      $$ProgressEventsTableAnnotationComposer,
      $$ProgressEventsTableCreateCompanionBuilder,
      $$ProgressEventsTableUpdateCompanionBuilder,
      (LocalProgressEventRow, $$ProgressEventsTableReferences),
      LocalProgressEventRow,
      PrefetchHooks Function({bool volumeId, bool dreamId})
    >;
typedef $$JobsTableCreateCompanionBuilder =
    JobsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String> userId,
      Value<String?> dreamId,
      required String volumeId,
      required String type,
      required String status,
      Value<int> attempt,
      Value<String?> error,
      required String idempotencyKey,
      Value<String> payload,
      required String stageLabel,
      Value<int> rowid,
    });
typedef $$JobsTableUpdateCompanionBuilder =
    JobsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> userId,
      Value<String?> dreamId,
      Value<String> volumeId,
      Value<String> type,
      Value<String> status,
      Value<int> attempt,
      Value<String?> error,
      Value<String> idempotencyKey,
      Value<String> payload,
      Value<String> stageLabel,
      Value<int> rowid,
    });

final class $$JobsTableReferences
    extends BaseReferences<_$AppDatabase, $JobsTable, LocalJobRow> {
  $$JobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DreamsTable _dreamIdTable(_$AppDatabase db) =>
      db.dreams.createAlias('jobs__dream_id__dreams__id');

  $$DreamsTableProcessedTableManager? get dreamId {
    final $_column = $_itemColumn<String>('dream_id');
    if ($_column == null) return null;
    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('jobs__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JobsTableFilterComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => ColumnFilters(column),
  );

  $$DreamsTableFilterComposer get dreamId {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableOrderingComposer extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => ColumnOrderings(column),
  );

  $$DreamsTableOrderingComposer get dreamId {
    final $$DreamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableOrderingComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JobsTable> {
  $$JobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get stageLabel => $composableBuilder(
    column: $table.stageLabel,
    builder: (column) => column,
  );

  $$DreamsTableAnnotationComposer get dreamId {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JobsTable,
          LocalJobRow,
          $$JobsTableFilterComposer,
          $$JobsTableOrderingComposer,
          $$JobsTableAnnotationComposer,
          $$JobsTableCreateCompanionBuilder,
          $$JobsTableUpdateCompanionBuilder,
          (LocalJobRow, $$JobsTableReferences),
          LocalJobRow,
          PrefetchHooks Function({bool dreamId, bool volumeId})
        > {
  $$JobsTableTableManager(_$AppDatabase db, $JobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> dreamId = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> stageLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                dreamId: dreamId,
                volumeId: volumeId,
                type: type,
                status: status,
                attempt: attempt,
                error: error,
                idempotencyKey: idempotencyKey,
                payload: payload,
                stageLabel: stageLabel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String> userId = const Value.absent(),
                Value<String?> dreamId = const Value.absent(),
                required String volumeId,
                required String type,
                required String status,
                Value<int> attempt = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required String idempotencyKey,
                Value<String> payload = const Value.absent(),
                required String stageLabel,
                Value<int> rowid = const Value.absent(),
              }) => JobsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                userId: userId,
                dreamId: dreamId,
                volumeId: volumeId,
                type: type,
                status: status,
                attempt: attempt,
                error: error,
                idempotencyKey: idempotencyKey,
                payload: payload,
                stageLabel: stageLabel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JobsTable, LocalJobRow>(table),
                  $$JobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dreamId = false, volumeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dreamId,
                                referencedTable: $$JobsTableReferences
                                    ._dreamIdTable(db),
                                referencedColumn: $$JobsTableReferences
                                    ._dreamIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable: $$JobsTableReferences
                                    ._volumeIdTable(db),
                                referencedColumn: $$JobsTableReferences
                                    ._volumeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JobsTable,
      LocalJobRow,
      $$JobsTableFilterComposer,
      $$JobsTableOrderingComposer,
      $$JobsTableAnnotationComposer,
      $$JobsTableCreateCompanionBuilder,
      $$JobsTableUpdateCompanionBuilder,
      (LocalJobRow, $$JobsTableReferences),
      LocalJobRow,
      PrefetchHooks Function({bool dreamId, bool volumeId})
    >;
typedef $$LinkDecisionsTableCreateCompanionBuilder =
    LinkDecisionsCompanion Function({
      required String id,
      required String volumeId,
      required String dreamId,
      required String kind,
      Value<String> payload,
      required String status,
      Value<DateTime?> decidedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LinkDecisionsTableUpdateCompanionBuilder =
    LinkDecisionsCompanion Function({
      Value<String> id,
      Value<String> volumeId,
      Value<String> dreamId,
      Value<String> kind,
      Value<String> payload,
      Value<String> status,
      Value<DateTime?> decidedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LinkDecisionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LinkDecisionsTable,
          LocalLinkDecisionRow
        > {
  $$LinkDecisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('link_decisions__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DreamsTable _dreamIdTable(_$AppDatabase db) =>
      db.dreams.createAlias('link_decisions__dream_id__dreams__id');

  $$DreamsTableProcessedTableManager get dreamId {
    final $_column = $_itemColumn<String>('dream_id')!;

    final manager = $$DreamsTableTableManager(
      $_db,
      $_db.dreams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LinkDecisionsTableFilterComposer
    extends Composer<_$AppDatabase, $LinkDecisionsTable> {
  $$LinkDecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableFilterComposer get dreamId {
    final $$DreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableFilterComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinkDecisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LinkDecisionsTable> {
  $$LinkDecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableOrderingComposer get dreamId {
    final $$DreamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableOrderingComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinkDecisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinkDecisionsTable> {
  $$LinkDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DreamsTableAnnotationComposer get dreamId {
    final $$DreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LinkDecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinkDecisionsTable,
          LocalLinkDecisionRow,
          $$LinkDecisionsTableFilterComposer,
          $$LinkDecisionsTableOrderingComposer,
          $$LinkDecisionsTableAnnotationComposer,
          $$LinkDecisionsTableCreateCompanionBuilder,
          $$LinkDecisionsTableUpdateCompanionBuilder,
          (LocalLinkDecisionRow, $$LinkDecisionsTableReferences),
          LocalLinkDecisionRow,
          PrefetchHooks Function({bool volumeId, bool dreamId})
        > {
  $$LinkDecisionsTableTableManager(_$AppDatabase db, $LinkDecisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinkDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinkDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinkDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> dreamId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LinkDecisionsCompanion(
                id: id,
                volumeId: volumeId,
                dreamId: dreamId,
                kind: kind,
                payload: payload,
                status: status,
                decidedAt: decidedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String volumeId,
                required String dreamId,
                required String kind,
                Value<String> payload = const Value.absent(),
                required String status,
                Value<DateTime?> decidedAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LinkDecisionsCompanion.insert(
                id: id,
                volumeId: volumeId,
                dreamId: dreamId,
                kind: kind,
                payload: payload,
                status: status,
                decidedAt: decidedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LinkDecisionsTable, LocalLinkDecisionRow>(table),
                  $$LinkDecisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({volumeId = false, dreamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable: $$LinkDecisionsTableReferences
                                    ._volumeIdTable(db),
                                referencedColumn: $$LinkDecisionsTableReferences
                                    ._volumeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (dreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dreamId,
                                referencedTable: $$LinkDecisionsTableReferences
                                    ._dreamIdTable(db),
                                referencedColumn: $$LinkDecisionsTableReferences
                                    ._dreamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LinkDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinkDecisionsTable,
      LocalLinkDecisionRow,
      $$LinkDecisionsTableFilterComposer,
      $$LinkDecisionsTableOrderingComposer,
      $$LinkDecisionsTableAnnotationComposer,
      $$LinkDecisionsTableCreateCompanionBuilder,
      $$LinkDecisionsTableUpdateCompanionBuilder,
      (LocalLinkDecisionRow, $$LinkDecisionsTableReferences),
      LocalLinkDecisionRow,
      PrefetchHooks Function({bool volumeId, bool dreamId})
    >;
typedef $$DreamDraftsTableCreateCompanionBuilder =
    DreamDraftsCompanion Function({
      required String id,
      required String content,
      required String inputMode,
      required DateTime dreamDate,
      Value<bool> isBackfill,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DreamDraftsTableUpdateCompanionBuilder =
    DreamDraftsCompanion Function({
      Value<String> id,
      Value<String> content,
      Value<String> inputMode,
      Value<DateTime> dreamDate,
      Value<bool> isBackfill,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DreamDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamDraftsTable> {
  $$DreamDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dreamDate => $composableBuilder(
    column: $table.dreamDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DreamDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamDraftsTable> {
  $$DreamDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dreamDate => $composableBuilder(
    column: $table.dreamDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DreamDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamDraftsTable> {
  $$DreamDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<DateTime> get dreamDate =>
      $composableBuilder(column: $table.dreamDate, builder: (column) => column);

  GeneratedColumn<bool> get isBackfill => $composableBuilder(
    column: $table.isBackfill,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DreamDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamDraftsTable,
          LocalDreamDraftRow,
          $$DreamDraftsTableFilterComposer,
          $$DreamDraftsTableOrderingComposer,
          $$DreamDraftsTableAnnotationComposer,
          $$DreamDraftsTableCreateCompanionBuilder,
          $$DreamDraftsTableUpdateCompanionBuilder,
          (
            LocalDreamDraftRow,
            BaseReferences<
              _$AppDatabase,
              $DreamDraftsTable,
              LocalDreamDraftRow
            >,
          ),
          LocalDreamDraftRow,
          PrefetchHooks Function()
        > {
  $$DreamDraftsTableTableManager(_$AppDatabase db, $DreamDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> inputMode = const Value.absent(),
                Value<DateTime> dreamDate = const Value.absent(),
                Value<bool> isBackfill = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamDraftsCompanion(
                id: id,
                content: content,
                inputMode: inputMode,
                dreamDate: dreamDate,
                isBackfill: isBackfill,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String content,
                required String inputMode,
                required DateTime dreamDate,
                Value<bool> isBackfill = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DreamDraftsCompanion.insert(
                id: id,
                content: content,
                inputMode: inputMode,
                dreamDate: dreamDate,
                isBackfill: isBackfill,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DreamDraftsTable, LocalDreamDraftRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DreamDraftsTable,
                    LocalDreamDraftRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DreamDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamDraftsTable,
      LocalDreamDraftRow,
      $$DreamDraftsTableFilterComposer,
      $$DreamDraftsTableOrderingComposer,
      $$DreamDraftsTableAnnotationComposer,
      $$DreamDraftsTableCreateCompanionBuilder,
      $$DreamDraftsTableUpdateCompanionBuilder,
      (
        LocalDreamDraftRow,
        BaseReferences<_$AppDatabase, $DreamDraftsTable, LocalDreamDraftRow>,
      ),
      LocalDreamDraftRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      required String id,
      required String op,
      required String payload,
      required String idempotencyKey,
      Value<int> attempt,
      required DateTime nextAttemptAt,
      required String status,
      Value<int> rowid,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<String> id,
      Value<String> op,
      Value<String> payload,
      Value<String> idempotencyKey,
      Value<int> attempt,
      Value<DateTime> nextAttemptAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          LocalOutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            LocalOutboxRow,
            BaseReferences<_$AppDatabase, $OutboxTable, LocalOutboxRow>,
          ),
          LocalOutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                op: op,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attempt: attempt,
                nextAttemptAt: nextAttemptAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String op,
                required String payload,
                required String idempotencyKey,
                Value<int> attempt = const Value.absent(),
                required DateTime nextAttemptAt,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                op: op,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attempt: attempt,
                nextAttemptAt: nextAttemptAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, LocalOutboxRow>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, LocalOutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      LocalOutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (
        LocalOutboxRow,
        BaseReferences<_$AppDatabase, $OutboxTable, LocalOutboxRow>,
      ),
      LocalOutboxRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderPositionsTableCreateCompanionBuilder =
    ReaderPositionsCompanion Function({
      required String volumeId,
      Value<double> offset,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReaderPositionsTableUpdateCompanionBuilder =
    ReaderPositionsCompanion Function({
      Value<String> volumeId,
      Value<double> offset,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReaderPositionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReaderPositionsTable,
          LocalReaderPositionRow
        > {
  $$ReaderPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $VolumesTable _volumeIdTable(_$AppDatabase db) =>
      db.volumes.createAlias('reader_positions__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReaderPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get offset => $composableBuilder(
    column: $table.offset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get offset => $composableBuilder(
    column: $table.offset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get offset =>
      $composableBuilder(column: $table.offset, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderPositionsTable,
          LocalReaderPositionRow,
          $$ReaderPositionsTableFilterComposer,
          $$ReaderPositionsTableOrderingComposer,
          $$ReaderPositionsTableAnnotationComposer,
          $$ReaderPositionsTableCreateCompanionBuilder,
          $$ReaderPositionsTableUpdateCompanionBuilder,
          (LocalReaderPositionRow, $$ReaderPositionsTableReferences),
          LocalReaderPositionRow,
          PrefetchHooks Function({bool volumeId})
        > {
  $$ReaderPositionsTableTableManager(
    _$AppDatabase db,
    $ReaderPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> volumeId = const Value.absent(),
                Value<double> offset = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderPositionsCompanion(
                volumeId: volumeId,
                offset: offset,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String volumeId,
                Value<double> offset = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReaderPositionsCompanion.insert(
                volumeId: volumeId,
                offset: offset,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReaderPositionsTable, LocalReaderPositionRow>(
                    table,
                  ),
                  $$ReaderPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({volumeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (volumeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.volumeId,
                                referencedTable:
                                    $$ReaderPositionsTableReferences
                                        ._volumeIdTable(db),
                                referencedColumn:
                                    $$ReaderPositionsTableReferences
                                        ._volumeIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReaderPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderPositionsTable,
      LocalReaderPositionRow,
      $$ReaderPositionsTableFilterComposer,
      $$ReaderPositionsTableOrderingComposer,
      $$ReaderPositionsTableAnnotationComposer,
      $$ReaderPositionsTableCreateCompanionBuilder,
      $$ReaderPositionsTableUpdateCompanionBuilder,
      (LocalReaderPositionRow, $$ReaderPositionsTableReferences),
      LocalReaderPositionRow,
      PrefetchHooks Function({bool volumeId})
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String syncTableName,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> syncTableName,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncTableName => $composableBuilder(
    column: $table.syncTableName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncTableName => $composableBuilder(
    column: $table.syncTableName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncTableName => $composableBuilder(
    column: $table.syncTableName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          LocalSyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            LocalSyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, LocalSyncStateRow>,
          ),
          LocalSyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> syncTableName = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                syncTableName: syncTableName,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String syncTableName,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                syncTableName: syncTableName,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, LocalSyncStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncStateTable,
                    LocalSyncStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      LocalSyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        LocalSyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, LocalSyncStateRow>,
      ),
      LocalSyncStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VolumesTableTableManager get volumes =>
      $$VolumesTableTableManager(_db, _db.volumes);
  $$DreamsTableTableManager get dreams =>
      $$DreamsTableTableManager(_db, _db.dreams);
  $$DreamElementsTableTableManager get dreamElements =>
      $$DreamElementsTableTableManager(_db, _db.dreamElements);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db, _db.scenes);
  $$PassagesTableTableManager get passages =>
      $$PassagesTableTableManager(_db, _db.passages);
  $$ProgressEventsTableTableManager get progressEvents =>
      $$ProgressEventsTableTableManager(_db, _db.progressEvents);
  $$JobsTableTableManager get jobs => $$JobsTableTableManager(_db, _db.jobs);
  $$LinkDecisionsTableTableManager get linkDecisions =>
      $$LinkDecisionsTableTableManager(_db, _db.linkDecisions);
  $$DreamDraftsTableTableManager get dreamDrafts =>
      $$DreamDraftsTableTableManager(_db, _db.dreamDrafts);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$ReaderPositionsTableTableManager get readerPositions =>
      $$ReaderPositionsTableTableManager(_db, _db.readerPositions);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
