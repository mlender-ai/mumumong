import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../domain/repository/mumumong_repository.dart';
import '../memory/memory_repository.dart';
import 'database.dart';

class DriftRepository implements MumumongRepository {
  DriftRepository(this._database, {DateTime Function()? now, Uuid? uuid})
    : _now = now ?? DateTime.now,
      _uuid = uuid ?? const Uuid() {
    _ready = _seedIfEmpty();
  }

  final AppDatabase _database;
  final DateTime Function() _now;
  final Uuid _uuid;
  late final Future<void> _ready;

  @override
  Stream<Volume?> watchActiveVolume() => _afterReady(
    (_database.select(_database.volumes)
          ..where(
            (row) =>
                row.status.isNotValue(VolumeStatus.completed.databaseValue),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.volNo)])
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _volumeFromRow(row)),
  );

  @override
  Stream<List<Dream>> watchDreams(DreamStatusFilter filter) {
    final query = _database.select(_database.dreams);
    switch (filter) {
      case DreamStatusFilter.all:
        break;
      case DreamStatusFilter.inManuscript:
        query.where(
          (row) => row.status.equals(DreamStatus.inManuscript.databaseValue),
        );
      case DreamStatusFilter.archivedOnly:
        query.where(
          (row) => row.status.equals(DreamStatus.archivedOnly.databaseValue),
        );
    }
    query.orderBy([
      (row) => OrderingTerm.desc(row.dreamDate),
      (row) => OrderingTerm.desc(row.recordedAt),
    ]);
    return _afterReady(query.watch().map(_dreamsFromRows));
  }

  @override
  Stream<List<DreamElement>> watchDreamElements(String dreamId) {
    final query = _database.select(_database.dreamElements)
      ..where((row) => row.dreamId.equals(dreamId))
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]);
    return _afterReady(
      query.watch().map(
        (rows) => List.unmodifiable(rows.map(_dreamElementFromRow)),
      ),
    );
  }

  @override
  Stream<List<Scene>> watchScenes(String volumeId) {
    final query = _database.select(_database.scenes)
      ..where((row) => row.volumeId.equals(volumeId))
      ..orderBy([(row) => OrderingTerm.asc(row.orderKey)]);
    return _afterReady(
      query.watch().map((rows) => List.unmodifiable(rows.map(_sceneFromRow))),
    );
  }

  @override
  Stream<List<Passage>> watchPassages(String sceneId) {
    final query = _database.select(_database.passages)
      ..where((row) => row.sceneId.equals(sceneId))
      ..orderBy([(row) => OrderingTerm.asc(row.orderKey)]);
    return _afterReady(
      query.watch().map((rows) => List.unmodifiable(rows.map(_passageFromRow))),
    );
  }

  @override
  Stream<List<ProgressEvent>> watchRecentProgress(String volumeId) {
    final query = _database.select(_database.progressEvents)
      ..where((row) => row.volumeId.equals(volumeId))
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return _afterReady(
      query.watch().map(
        (rows) => List.unmodifiable(rows.map(_progressEventFromRow)),
      ),
    );
  }

  @override
  Stream<JobProgress?> watchJob(String dreamId) {
    final query = _database.select(_database.jobs)
      ..where((row) => row.dreamId.equals(dreamId))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return _afterReady(
      query.watchSingleOrNull().map(
        (row) => row == null ? null : _jobFromRow(row),
      ),
    );
  }

  @override
  Future<void> saveDraft(DreamDraft draft) async {
    await _ready;
    await _database.transaction(() async {
      await _database.delete(_database.dreamDrafts).go();
      await _database
          .into(_database.dreamDrafts)
          .insert(
            LocalDreamDraftRow(
              id: draft.id,
              content: draft.rawText,
              inputMode: draft.inputMode.databaseValue,
              dreamDate: draft.dreamDate,
              isBackfill: draft.isBackfill,
              updatedAt: draft.updatedAt,
            ),
          );
    });
  }

  @override
  Future<DreamDraft?> loadDraft() async {
    await _ready;
    final row =
        await (_database.select(_database.dreamDrafts)
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _draftFromRow(row);
  }

  @override
  Future<void> clearDraft() async {
    await _ready;
    await _database.delete(_database.dreamDrafts).go();
  }

  @override
  Future<String> submitDream(DreamDraft draft) async {
    await _ready;
    if (draft.rawText.trim().isEmpty) {
      throw ArgumentError.value(
        draft.rawText,
        'draft.rawText',
        'a dream cannot be empty',
      );
    }
    final dreamId = draft.id.isEmpty ? _uuid.v4() : draft.id;
    final existing = await (_database.select(
      _database.dreams,
    )..where((row) => row.id.equals(dreamId))).getSingleOrNull();
    if (existing != null) {
      await clearDraft();
      return dreamId;
    }
    final volume = await _activeVolumeRow();
    if (volume == null) {
      throw StateError('An active volume is required to submit a dream');
    }
    final timestamp = _now().toUtc();
    await _database.transaction(() async {
      await _database
          .into(_database.dreams)
          .insert(
            LocalDreamRow(
              id: dreamId,
              createdAt: timestamp,
              updatedAt: timestamp,
              userId: localUserId,
              volumeId: volume.id,
              dreamDate: draft.dreamDate,
              recordedAt: timestamp,
              inputMode: draft.inputMode.databaseValue,
              rawText: draft.rawText,
              recallAnswers: '{}',
              clarity: null,
              status: DreamStatus.queued.databaseValue,
              sensitiveFlags: '[]',
              isBackfill: draft.isBackfill,
            ),
          );
      await _database
          .into(_database.jobs)
          .insert(
            LocalJobRow(
              id: _uuid.v4(),
              createdAt: timestamp,
              updatedAt: timestamp,
              userId: localUserId,
              dreamId: dreamId,
              volumeId: volume.id,
              type: JobType.extract.databaseValue,
              status: JobStatus.queued.databaseValue,
              attempt: 0,
              idempotencyKey: 'extract:$dreamId',
              payload: '{}',
              stageLabel: '꿈을 읽을 준비 중',
            ),
          );
      await _database.delete(_database.dreamDrafts).go();
    });
    return dreamId;
  }

  @override
  Future<void> answerRecall(String dreamId, Map<String, String> answers) async {
    await _ready;
    final dream = await _dreamRow(dreamId);
    final timestamp = _now().toUtc();
    await _database.transaction(() async {
      await (_database.update(
        _database.dreams,
      )..where((row) => row.id.equals(dreamId))).write(
        DreamsCompanion(
          recallAnswers: Value(jsonEncode(answers)),
          status: Value(DreamStatus.processing.databaseValue),
          updatedAt: Value(timestamp),
        ),
      );
      final existingJob =
          await (_database.select(_database.jobs)
                ..where((row) => row.dreamId.equals(dreamId))
                ..limit(1))
              .getSingleOrNull();
      if (existingJob == null) {
        await _database
            .into(_database.jobs)
            .insert(
              LocalJobRow(
                id: _uuid.v4(),
                createdAt: timestamp,
                updatedAt: timestamp,
                userId: localUserId,
                dreamId: dreamId,
                volumeId: dream.volumeId!,
                type: JobType.extract.databaseValue,
                status: JobStatus.running.databaseValue,
                attempt: 1,
                idempotencyKey: 'extract:$dreamId',
                payload: '{}',
                stageLabel: '꿈을 읽는 중',
              ),
            );
      } else {
        await (_database.update(
          _database.jobs,
        )..where((row) => row.id.equals(existingJob.id))).write(
          JobsCompanion(
            status: Value(JobStatus.running.databaseValue),
            attempt: Value(existingJob.attempt + 1),
            stageLabel: const Value('꿈을 읽는 중'),
            updatedAt: Value(timestamp),
          ),
        );
      }
    });
  }

  @override
  Future<void> decideLink(String decisionId, LinkChoice choice) async {
    await _ready;
    final decision = await (_database.select(
      _database.linkDecisions,
    )..where((row) => row.id.equals(decisionId))).getSingleOrNull();
    if (decision == null) {
      throw StateError('Link decision not found: $decisionId');
    }
    final pending = LinkDecisionStatus.pending.databaseValue;
    final automatic = LinkDecisionStatus.auto.databaseValue;
    if (decision.status != pending && decision.status != automatic) {
      throw StateError('Link decision was already answered: $decisionId');
    }
    final status = switch (choice) {
      LinkChoice.same => LinkDecisionStatus.same,
      LinkChoice.different => LinkDecisionStatus.different,
      LinkChoice.unsure => LinkDecisionStatus.unsure,
    };
    final volume = await (_database.select(
      _database.volumes,
    )..where((row) => row.id.equals(decision.volumeId))).getSingle();
    final timestamp = _now().toUtc();
    await _database.transaction(() async {
      await (_database.update(
        _database.linkDecisions,
      )..where((row) => row.id.equals(decisionId))).write(
        LinkDecisionsCompanion(
          status: Value(status.databaseValue),
          decidedAt: Value(timestamp),
        ),
      );
      await (_database.update(
        _database.volumes,
      )..where((row) => row.id.equals(volume.id))).write(
        VolumesCompanion(
          progressMu: Value(volume.progressMu + 0.5),
          updatedAt: Value(timestamp),
        ),
      );
      await _database
          .into(_database.progressEvents)
          .insert(
            LocalProgressEventRow(
              id: _uuid.v4(),
              userId: localUserId,
              volumeId: volume.id,
              dreamId: decision.dreamId,
              deltaMu: 0.5,
              reasons: jsonEncode(const [
                {'type': 'link_decision', 'n': 1},
              ]),
              createdAt: timestamp,
            ),
          );
    });
  }

  @override
  Future<void> changePlacement(String sceneId, PlacementKind kind) async {
    await _ready;
    final changed =
        await (_database.update(
          _database.scenes,
        )..where((row) => row.id.equals(sceneId))).write(
          ScenesCompanion(
            placement: Value(kind.databaseValue),
            updatedAt: Value(_now().toUtc()),
          ),
        );
    if (changed == 0) {
      throw StateError('Scene not found: $sceneId');
    }
  }

  @override
  Future<void> editPassage(String passageId, String text) async {
    await _ready;
    final passage = await _passageRow(passageId);
    await (_database.update(
      _database.passages,
    )..where((row) => row.id.equals(passageId))).write(
      PassagesCompanion(
        content: Value(text),
        origin: Value(PassageOrigin.user.databaseValue),
        originalText: Value(passage.originalText ?? passage.content),
        locked: const Value(true),
        updatedAt: Value(_now().toUtc()),
      ),
    );
  }

  @override
  Future<void> revertPassage(String passageId) async {
    await _ready;
    final passage = await _passageRow(passageId);
    if (passage.originalText == null) {
      throw StateError('Passage has no edit to revert: $passageId');
    }
    final originalOrigin = _originalOrigin(passage);
    await (_database.update(
      _database.passages,
    )..where((row) => row.id.equals(passageId))).write(
      PassagesCompanion(
        content: Value(passage.originalText!),
        origin: Value(originalOrigin.databaseValue),
        originalText: const Value(null),
        locked: Value(originalOrigin == PassageOrigin.user),
        updatedAt: Value(_now().toUtc()),
      ),
    );
  }

  @override
  Future<void> markPassageRead(String passageId) async {
    await _ready;
    final passage = await _passageRow(passageId);
    if (passage.firstReadAt != null) return;
    await (_database.update(
      _database.passages,
    )..where((row) => row.id.equals(passageId))).write(
      PassagesCompanion(
        firstReadAt: Value(_now().toUtc()),
        updatedAt: Value(_now().toUtc()),
      ),
    );
  }

  @override
  Future<void> removeDreamFromManuscript(String dreamId) async {
    await _ready;
    final dream = await _dreamRow(dreamId);
    if (dream.status == DreamStatus.archivedOnly.databaseValue) return;
    await _database.transaction(() async {
      await _removeDerivedContent(dreamId);
      await (_database.update(
        _database.dreams,
      )..where((row) => row.id.equals(dreamId))).write(
        DreamsCompanion(
          status: Value(DreamStatus.archivedOnly.databaseValue),
          updatedAt: Value(_now().toUtc()),
        ),
      );
      await _cancelDreamProgress(dream, keepDreamReference: true);
    });
  }

  @override
  Future<void> deleteDream(String dreamId, DeleteMode mode) async {
    await _ready;
    final dream = await _dreamRow(dreamId);
    await _database.transaction(() async {
      switch (mode) {
        case DeleteMode.deleteDerivedContent:
          await _removeDerivedContent(dreamId);
        case DeleteMode.keepDerivedContent:
          await _detachDreamSources(dreamId);
      }
      await (_database.delete(
        _database.dreamElements,
      )..where((row) => row.dreamId.equals(dreamId))).go();
      await (_database.delete(
        _database.jobs,
      )..where((row) => row.dreamId.equals(dreamId))).go();
      await (_database.delete(
        _database.linkDecisions,
      )..where((row) => row.dreamId.equals(dreamId))).go();
      await _cancelDreamProgress(dream, keepDreamReference: false);
      await (_database.update(_database.progressEvents)
            ..where((row) => row.dreamId.equals(dreamId)))
          .write(const ProgressEventsCompanion(dreamId: Value(null)));
      await (_database.delete(
        _database.dreams,
      )..where((row) => row.id.equals(dreamId))).go();
    });
  }

  Stream<T> _afterReady<T>(Stream<T> stream) {
    return Stream.fromFuture(_ready).asyncExpand((_) => stream);
  }

  Future<LocalVolumeRow?> _activeVolumeRow() {
    return (_database.select(_database.volumes)
          ..where(
            (row) =>
                row.status.isNotValue(VolumeStatus.completed.databaseValue),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.volNo)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<LocalDreamRow> _dreamRow(String dreamId) async {
    final row = await (_database.select(
      _database.dreams,
    )..where((row) => row.id.equals(dreamId))).getSingleOrNull();
    if (row == null) throw StateError('Dream not found: $dreamId');
    return row;
  }

  Future<LocalPassageRow> _passageRow(String passageId) async {
    final row = await (_database.select(
      _database.passages,
    )..where((row) => row.id.equals(passageId))).getSingleOrNull();
    if (row == null) throw StateError('Passage not found: $passageId');
    return row;
  }

  Future<void> _removeDerivedContent(String dreamId) async {
    final sceneRows = await _database.select(_database.scenes).get();
    final sceneIds = sceneRows
        .where((row) => _decodeStringList(row.sourceDreamIds).contains(dreamId))
        .map((row) => row.id)
        .toSet();
    if (sceneIds.isNotEmpty) {
      await (_database.delete(
        _database.passages,
      )..where((row) => row.sceneId.isIn(sceneIds))).go();
      await (_database.delete(
        _database.scenes,
      )..where((row) => row.id.isIn(sceneIds))).go();
    }
    await (_database.delete(
      _database.dreamElements,
    )..where((row) => row.dreamId.equals(dreamId))).go();
  }

  Future<void> _detachDreamSources(String dreamId) async {
    final sceneRows = await _database.select(_database.scenes).get();
    for (final row in sceneRows) {
      final sourceIds = _decodeStringList(row.sourceDreamIds);
      if (!sourceIds.contains(dreamId)) continue;
      await (_database.update(
        _database.scenes,
      )..where((scene) => scene.id.equals(row.id))).write(
        ScenesCompanion(
          sourceDreamIds: Value(
            jsonEncode(sourceIds.where((id) => id != dreamId).toList()),
          ),
          updatedAt: Value(_now().toUtc()),
        ),
      );
    }
    final passageRows = await (_database.select(
      _database.passages,
    )..where((row) => row.sourceDreamId.equals(dreamId))).get();
    for (final row in passageRows) {
      final isDream = row.origin == PassageOrigin.dream.databaseValue;
      await (_database.update(
        _database.passages,
      )..where((passage) => passage.id.equals(row.id))).write(
        PassagesCompanion(
          origin: isDream
              ? Value(PassageOrigin.connection.databaseValue)
              : const Value.absent(),
          sourceDreamId: const Value(null),
          sourceElementIds: isDream ? const Value('[]') : const Value.absent(),
          cReason: isDream
              ? const Value('출처 꿈이 삭제되었습니다')
              : const Value.absent(),
          updatedAt: Value(_now().toUtc()),
        ),
      );
    }
  }

  Future<void> _cancelDreamProgress(
    LocalDreamRow dream, {
    required bool keepDreamReference,
  }) async {
    if (dream.volumeId == null) return;
    final volume = await (_database.select(
      _database.volumes,
    )..where((row) => row.id.equals(dream.volumeId!))).getSingleOrNull();
    if (volume == null) return;
    final answers = _decodeStringMap(dream.recallAnswers);
    final validAnswers = answers.values
        .where((answer) => answer.trim().isNotEmpty && answer != '모름')
        .length;
    final clarity = dream.clarity == null
        ? DreamClarity.fragment
        : enumFromDatabase(dream.clarity, DreamClarity.values);
    final delta = materialUnits(
      clarity: clarity,
      recallAnswers: validAnswers,
      userPassages: 0,
    );
    final timestamp = _now().toUtc();
    await (_database.update(
      _database.volumes,
    )..where((row) => row.id.equals(volume.id))).write(
      VolumesCompanion(
        progressMu: Value(math.max(0, volume.progressMu - delta)),
        updatedAt: Value(timestamp),
      ),
    );
    await _database
        .into(_database.progressEvents)
        .insert(
          LocalProgressEventRow(
            id: _uuid.v4(),
            userId: localUserId,
            volumeId: volume.id,
            dreamId: keepDreamReference ? dream.id : null,
            deltaMu: -delta,
            reasons: jsonEncode(const [
              {'type': 'dream_removed', 'n': 1},
            ]),
            createdAt: timestamp,
          ),
        );
  }

  PassageOrigin _originalOrigin(LocalPassageRow row) {
    if (_decodeStringList(row.sourceElementIds).isNotEmpty) {
      return PassageOrigin.dream;
    }
    if (row.cReason != null) return PassageOrigin.connection;
    return PassageOrigin.user;
  }

  Future<void> _seedIfEmpty() async {
    if (await _database.select(_database.volumes).getSingleOrNull() != null) {
      return;
    }
    final memory = MemoryRepository();
    try {
      final volume = await memory.watchActiveVolume().first;
      if (volume == null) return;
      final dreams = await memory.watchDreams(DreamStatusFilter.all).first;
      final scenes = await memory.watchScenes(volume.id).first;
      final passages = <Passage>[];
      for (final scene in scenes) {
        passages.addAll(await memory.watchPassages(scene.id).first);
      }
      final events = await memory.watchRecentProgress(volume.id).first;
      final timestamp = DateTime.utc(2026, 9, 13, 7);
      await _database.transaction(() async {
        await _database
            .into(_database.volumes)
            .insert(_volumeToRow(volume, timestamp));
        await _database.batch((batch) {
          batch.insertAll(
            _database.dreams,
            dreams.map((dream) => _dreamToRow(dream, timestamp)).toList(),
          );
          batch.insertAll(_database.dreamElements, _seedElementRows(timestamp));
          batch.insertAll(
            _database.scenes,
            scenes.map((scene) => _sceneToRow(scene, timestamp)).toList(),
          );
          batch.insertAll(
            _database.passages,
            passages
                .map((passage) => _passageToRow(passage, timestamp))
                .toList(),
          );
          batch.insertAll(
            _database.progressEvents,
            events.map(_progressEventToRow).toList(),
          );
        });
        await _database
            .into(_database.linkDecisions)
            .insert(
              LocalLinkDecisionRow(
                id: MemorySeedIds.linkDecision,
                volumeId: volume.id,
                dreamId: MemorySeedIds.latestDream,
                kind: LinkDecisionKind.entityMerge.databaseValue,
                payload: jsonEncode(const {
                  'element_id': '00000000-0000-4000-8000-000000000402',
                  'candidate_entity_id': '00000000-0000-4000-8000-000000000701',
                }),
                status: LinkDecisionStatus.pending.databaseValue,
                createdAt: timestamp,
              ),
            );
      });
    } finally {
      memory.dispose();
    }
  }

  LocalVolumeRow _volumeToRow(Volume value, DateTime timestamp) {
    return LocalVolumeRow(
      id: value.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      userId: localUserId,
      volNo: value.volNo,
      title: value.title,
      format: value.format.databaseValue,
      adaptation: value.adaptation.databaseValue,
      style: value.style.databaseValue,
      narrativeVoice: value.narrativeVoice.databaseValue,
      status: value.status.databaseValue,
      targetMu: value.targetMu,
      progressMu: value.progressMu,
      genreProfile: jsonEncode(value.genreProfile),
      genreDirective: '{"mode":"keep"}',
      coverMotifId: value.coverMotifId,
      prologueSceneId: value.prologueSceneId,
    );
  }

  LocalDreamRow _dreamToRow(Dream value, DateTime timestamp) {
    return LocalDreamRow(
      id: value.id,
      createdAt: value.recordedAt,
      updatedAt: timestamp,
      userId: localUserId,
      volumeId: value.volumeId,
      dreamDate: value.dreamDate,
      recordedAt: value.recordedAt,
      inputMode: value.inputMode.databaseValue,
      rawText: value.rawText,
      recallAnswers: jsonEncode(value.recallAnswers),
      clarity: value.clarity?.databaseValue,
      status: value.status.databaseValue,
      sensitiveFlags: '[]',
      isBackfill: value.isBackfill,
    );
  }

  LocalSceneRow _sceneToRow(Scene value, DateTime timestamp) {
    return LocalSceneRow(
      id: value.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      volumeId: value.volumeId,
      orderKey: value.orderKey,
      chapterNo: value.chapterNo,
      kind: value.kind.databaseValue,
      placement: value.placement.databaseValue,
      title: value.title,
      sourceDreamIds: jsonEncode(value.sourceDreamIds),
      version: 1,
      openImage: value.openImage,
    );
  }

  LocalPassageRow _passageToRow(Passage value, DateTime timestamp) {
    return LocalPassageRow(
      id: value.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      userId: localUserId,
      sceneId: value.sceneId,
      orderKey: value.orderKey,
      content: value.text,
      origin: value.origin.databaseValue,
      sourceDreamId: value.sourceDreamId,
      sourceElementIds: jsonEncode(value.sourceElementIds),
      cReason: value.cReason,
      originalText: value.originalText,
      locked: value.locked,
      createdBy: 'engine',
      firstReadAt: value.firstReadAt,
    );
  }

  LocalProgressEventRow _progressEventToRow(ProgressEvent value) {
    return LocalProgressEventRow(
      id: value.id,
      userId: localUserId,
      volumeId: value.volumeId,
      dreamId: value.dreamId,
      deltaMu: value.deltaMu,
      reasons: jsonEncode(value.reasons),
      createdAt: value.createdAt,
    );
  }

  List<LocalDreamElementRow> _seedElementRows(DateTime timestamp) {
    const labels = ['물이 찬 복도', '우산을 든 여자', '붉은 문'];
    return [
      for (var index = 0; index < labels.length; index++)
        LocalDreamElementRow(
          id: '00000000-0000-4000-8000-000000000${401 + index}',
          dreamId: MemorySeedIds.latestDream,
          type: DreamElementType.object.databaseValue,
          label: labels[index],
          salience: DreamElementSalience.high.databaseValue,
          source: DreamElementSource.raw.databaseValue,
          createdAt: timestamp,
        ),
    ];
  }
}

Volume _volumeFromRow(LocalVolumeRow row) => Volume(
  id: row.id,
  volNo: row.volNo,
  title: row.title,
  format: enumFromDatabase(row.format, VolumeFormat.values),
  adaptation: enumFromDatabase(row.adaptation, AdaptationLevel.values),
  style: enumFromDatabase(row.style, WritingStyle.values),
  narrativeVoice: enumFromDatabase(row.narrativeVoice, NarrativeVoice.values),
  status: enumFromDatabase(row.status, VolumeStatus.values),
  progressMu: row.progressMu,
  targetMu: row.targetMu,
  genreProfile: _decodeDoubleMap(row.genreProfile),
  coverMotifId: row.coverMotifId,
  prologueSceneId: row.prologueSceneId,
);

List<Dream> _dreamsFromRows(List<LocalDreamRow> rows) =>
    List.unmodifiable(rows.map(_dreamFromRow));

Dream _dreamFromRow(LocalDreamRow row) => Dream(
  id: row.id,
  volumeId: row.volumeId,
  dreamDate: row.dreamDate,
  recordedAt: row.recordedAt,
  inputMode: enumFromDatabase(row.inputMode, DreamInputMode.values),
  rawText: row.rawText,
  recallAnswers: _decodeStringMap(row.recallAnswers),
  clarity: row.clarity == null
      ? null
      : enumFromDatabase(row.clarity, DreamClarity.values),
  status: enumFromDatabase(row.status, DreamStatus.values),
  isBackfill: row.isBackfill,
);

DreamElement _dreamElementFromRow(LocalDreamElementRow row) => DreamElement(
  id: row.id,
  dreamId: row.dreamId,
  type: enumFromDatabase(row.type, DreamElementType.values),
  label: row.label,
  detail: row.detail,
  salience: enumFromDatabase(row.salience, DreamElementSalience.values),
  source: enumFromDatabase(row.source, DreamElementSource.values),
  span: _decodeSpan(row.span),
);

Scene _sceneFromRow(LocalSceneRow row) => Scene(
  id: row.id,
  volumeId: row.volumeId,
  orderKey: row.orderKey,
  chapterNo: row.chapterNo,
  kind: enumFromDatabase(row.kind, SceneKind.values),
  placement: enumFromDatabase(row.placement, PlacementKind.values),
  title: row.title,
  sourceDreamIds: _decodeStringList(row.sourceDreamIds),
  openImage: row.openImage,
);

Passage _passageFromRow(LocalPassageRow row) => Passage(
  id: row.id,
  sceneId: row.sceneId,
  orderKey: row.orderKey,
  text: row.content,
  origin: enumFromDatabase(row.origin, PassageOrigin.values),
  sourceDreamId: row.sourceDreamId,
  sourceElementIds: _decodeStringList(row.sourceElementIds),
  cReason: row.cReason,
  originalText: row.originalText,
  locked: row.locked,
  firstReadAt: row.firstReadAt,
);

ProgressEvent _progressEventFromRow(LocalProgressEventRow row) => ProgressEvent(
  id: row.id,
  volumeId: row.volumeId,
  dreamId: row.dreamId,
  deltaMu: row.deltaMu,
  reasons: _decodeObjectList(row.reasons),
  createdAt: row.createdAt,
);

JobProgress _jobFromRow(LocalJobRow row) => JobProgress(
  dreamId: row.dreamId!,
  type: enumFromDatabase(row.type, JobType.values),
  status: enumFromDatabase(row.status, JobStatus.values),
  attempt: row.attempt,
  stageLabel: row.stageLabel,
);

DreamDraft _draftFromRow(LocalDreamDraftRow row) => DreamDraft(
  id: row.id,
  rawText: row.content,
  inputMode: enumFromDatabase(row.inputMode, DreamInputMode.values),
  dreamDate: row.dreamDate,
  isBackfill: row.isBackfill,
  updatedAt: row.updatedAt,
);

List<String> _decodeStringList(String value) =>
    (jsonDecode(value) as List<dynamic>).cast<String>();

Map<String, String> _decodeStringMap(String value) =>
    (jsonDecode(value) as Map<String, dynamic>).cast<String, String>();

Map<String, double> _decodeDoubleMap(String value) =>
    (jsonDecode(value) as Map<String, dynamic>).map(
      (key, nested) => MapEntry(key, (nested as num).toDouble()),
    );

List<Map<String, dynamic>> _decodeObjectList(String value) =>
    (jsonDecode(value) as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>))
        .toList(growable: false);

(int, int)? _decodeSpan(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^\[(-?\d+),(-?\d+)\)$').firstMatch(value);
  if (match == null) throw FormatException('Invalid span: $value');
  return (int.parse(match.group(1)!), int.parse(match.group(2)!));
}
