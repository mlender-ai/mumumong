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
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'mumumong'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
