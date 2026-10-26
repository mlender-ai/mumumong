import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

const localUserId = '00000000-0000-4000-8000-000000000000';

abstract class SyncTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalVolumeRow')
class Volumes extends SyncTable {
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  IntColumn get volNo => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get format => text()();
  TextColumn get adaptation => text()();
  TextColumn get style => text()();
  TextColumn get narrativeVoice => text()();
  IntColumn get settingsVersion => integer().withDefault(const Constant(1))();
  TextColumn get status => text()();
  RealColumn get targetMu => real()();
  RealColumn get progressMu => real()();
  TextColumn get genreProfile => text().withDefault(const Constant('{}'))();
  TextColumn get genreDirective =>
      text().withDefault(const Constant('{"mode":"keep"}'))();
  TextColumn get coverMotifId => text().nullable()();
  IntColumn get coverSeed => integer().nullable()();
  TextColumn get authorNote => text().nullable()();
  TextColumn get prologueSceneId => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('LocalDreamRow')
class Dreams extends SyncTable {
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get volumeId => text().nullable().references(Volumes, #id)();
  DateTimeColumn get dreamDate => dateTime()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get inputMode => text()();
  TextColumn get rawText => text()();
  DateTimeColumn get rawTextEditedAt => dateTime().nullable()();
  TextColumn get recallAnswers => text().withDefault(const Constant('{}'))();
  TextColumn get clarity => text().nullable()();
  TextColumn get status => text()();
  TextColumn get sensitiveFlags => text().withDefault(const Constant('[]'))();
  BoolColumn get isBackfill => boolean().withDefault(const Constant(false))();
}

@DataClassName('LocalDreamElementRow')
class DreamElements extends Table {
  TextColumn get id => text()();
  TextColumn get dreamId => text().references(Dreams, #id)();
  TextColumn get type => text()();
  TextColumn get label => text()();
  TextColumn get detail => text().nullable()();
  TextColumn get salience => text()();
  TextColumn get source => text()();
  TextColumn get span => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalEntityRow')
class Entities extends SyncTable {
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get type => text()();
  TextColumn get roleName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get aliases => text().withDefault(const Constant('[]'))();
  TextColumn get status => text()();
  TextColumn get firstSceneId => text().nullable()();
  IntColumn get mentionCount => integer().withDefault(const Constant(0))();
}

@DataClassName('LocalSceneRow')
class Scenes extends SyncTable {
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get orderKey => text()();
  IntColumn get chapterNo => integer().nullable()();
  TextColumn get kind => text()();
  TextColumn get placement => text()();
  TextColumn get title => text().nullable()();
  TextColumn get sourceDreamIds => text().withDefault(const Constant('[]'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get openImage => text().nullable()();
}

@DataClassName('LocalPassageRow')
class Passages extends SyncTable {
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get sceneId => text().references(Scenes, #id)();
  TextColumn get orderKey => text()();
  TextColumn get content => text().named('text')();
  TextColumn get origin => text()();
  TextColumn get sourceDreamId => text().nullable().references(Dreams, #id)();
  TextColumn get sourceElementIds => text().withDefault(const Constant('[]'))();
  TextColumn get cReason => text().nullable()();
  TextColumn get originalText => text().nullable()();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  TextColumn get createdBy => text()();
  DateTimeColumn get firstReadAt => dateTime().nullable()();
}

@DataClassName('LocalProgressEventRow')
class ProgressEvents extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get dreamId => text().nullable().references(Dreams, #id)();
  RealColumn get deltaMu => real()();
  TextColumn get reasons => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalJobRow')
class Jobs extends SyncTable {
  TextColumn get userId => text().withDefault(const Constant(localUserId))();
  TextColumn get dreamId => text().nullable().references(Dreams, #id)();
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get type => text()();
  TextColumn get status => text()();
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  TextColumn get error => text().nullable()();
  TextColumn get idempotencyKey => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get stageLabel => text()();
}

@DataClassName('LocalLinkDecisionRow')
class LinkDecisions extends Table {
  TextColumn get id => text()();
  TextColumn get volumeId => text().references(Volumes, #id)();
  TextColumn get dreamId => text().references(Dreams, #id)();
  TextColumn get kind => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get status => text()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalDreamDraftRow')
class DreamDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get content => text().named('text')();
  TextColumn get inputMode => text()();
  DateTimeColumn get dreamDate => dateTime()();
  BoolColumn get isBackfill => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalOutboxRow')
class Outbox extends Table {
  TextColumn get id => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  TextColumn get idempotencyKey => text()();
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('LocalReaderPositionRow')
class ReaderPositions extends Table {
  TextColumn get volumeId => text().references(Volumes, #id)();
  // Keep soft anchors after passage/scene deletion, so Reader can find a neighbor.
  TextColumn get sceneId => text().nullable()();
  TextColumn get sceneOrderKey => text().nullable()();
  TextColumn get passageId => text().nullable()();
  TextColumn get passageOrderKey => text().nullable()();
  RealColumn get passageFraction => real().withDefault(const Constant(0))();
  RealColumn get offset => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {volumeId};
}

@DataClassName('LocalSyncStateRow')
class SyncState extends Table {
  TextColumn get syncTableName => text().named('table_name')();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {syncTableName};
}

@DataClassName('LocalPresentationReceiptRow')
class PresentationReceipts extends Table {
  TextColumn get volumeId =>
      text().references(Volumes, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get sourceId => text()();
  DateTimeColumn get consumedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {volumeId, kind, sourceId};
}

@DataClassName('LocalGenerationSettingsChangeRow')
class GenerationSettingsChanges extends Table {
  TextColumn get volumeId =>
      text().references(Volumes, #id, onDelete: KeyAction.cascade)();
  TextColumn get mutationId => text()();
  IntColumn get baseVersion => integer()();
  TextColumn get adaptation => text()();
  TextColumn get style => text()();
  TextColumn get narrativeVoice => text()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {volumeId};
}

@DataClassName('LocalCompletedBookRow')
class CompletedBooks extends Table {
  // Historical books can be cached without downloading every source volume.
  TextColumn get volumeId => text()();
  TextColumn get userId => text()();
  TextColumn get snapshot => text()();
  DateTimeColumn get completedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {volumeId};
}

@DataClassName('LocalCompletionRequestRow')
class CompletionRequests extends Table {
  TextColumn get volumeId =>
      text().references(Volumes, #id, onDelete: KeyAction.cascade)();
  TextColumn get requestId => text()();
  TextColumn get revision => text()();
  TextColumn get title => text()();
  TextColumn get authorNote => text().nullable()();
  TextColumn get previousStatus => text()();
  TextColumn get status => text()();
  @override
  Set<Column<Object>> get primaryKey => {volumeId};
}

@DriftDatabase(
  tables: [
    Volumes,
    Dreams,
    DreamElements,
    Entities,
    Scenes,
    Passages,
    ProgressEvents,
    Jobs,
    LinkDecisions,
    DreamDrafts,
    Outbox,
    ReaderPositions,
    PresentationReceipts,
    GenerationSettingsChanges,
    CompletedBooks,
    CompletionRequests,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'mumumong',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(readerPositions, readerPositions.sceneId);
        await migrator.addColumn(
          readerPositions,
          readerPositions.sceneOrderKey,
        );
        await migrator.addColumn(readerPositions, readerPositions.passageId);
        await migrator.addColumn(
          readerPositions,
          readerPositions.passageOrderKey,
        );
        await migrator.addColumn(
          readerPositions,
          readerPositions.passageFraction,
        );
      }
      if (from < 3) {
        await migrator.createTable(presentationReceipts);
        // Historical growth must not be celebrated again after this upgrade.
        // Unopened results remain available; this does not infer reading.
        await customStatement(
          "INSERT INTO presentation_receipts (volume_id, kind, source_id, consumed_at) "
          "SELECT volume_id, 'growth', id, created_at FROM progress_events WHERE delta_mu > 0",
        );
      }
      if (from < 4) {
        await migrator.addColumn(volumes, volumes.settingsVersion);
        await migrator.createTable(generationSettingsChanges);
        await customStatement(
          "UPDATE jobs SET payload = json_set(payload, '\$.generation_settings_version', 1) WHERE attempt > 0 AND json_extract(payload, '\$.generation_settings_version') IS NULL",
        );
      }
      if (from < 5) {
        await migrator.createTable(completedBooks);
        await migrator.createTable(completionRequests);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
