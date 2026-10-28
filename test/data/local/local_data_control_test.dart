import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/data/local/local_data_control.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/domain/model/models.dart';

void main() {
  test('clearLocalData removes all manuscript and local-only rows', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftRepository(database, queueCloudMutations: true);
    final volume = (await repository.watchActiveVolume().first)!;
    final event = (await repository.watchRecentProgress(volume.id).first).first;
    await repository.saveGenerationSettings(
      volume.id,
      const GenerationSettings(
        adaptation: AdaptationLevel.faithful,
        style: WritingStyle.lyrical,
        narrativeVoice: NarrativeVoice.firstPersonPast,
      ),
    );
    await repository.consumePresentation(
      volumeId: volume.id,
      kind: PresentationKind.growth,
      sourceId: event.id,
    );
    await database.customStatement(
      "INSERT INTO outbox(id, op, payload, idempotency_key, attempt, next_attempt_at, status) "
      "VALUES ('o', 'x', '{}', 'k', 0, 0, 'pending')",
    );
    await clearLocalData(database);
    for (final table in const [
      'volumes',
      'presentation_receipts',
      'generation_settings_changes',
      'dreams',
      'dream_elements',
      'scenes',
      'passages',
      'progress_events',
      'link_decisions',
      'jobs',
      'outbox',
    ]) {
      final count = await database
          .customSelect('SELECT COUNT(*) AS n FROM $table')
          .getSingle();
      expect(count.read<int>('n'), 0, reason: table);
    }
  });

  // Found on the simulator and the public web app: after delete-everything
  // the screens kept showing the deleted manuscript until relaunch, because
  // the raw deletes never reached Drift's watched queries.
  test('clearLocalData tells open queries that the rows are gone', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftRepository(database);
    await repository.ready;
    final volumes = <Volume?>[];
    final dreams = <List<Dream>>[];
    final volumeSub = repository.watchActiveVolume().listen(volumes.add);
    final dreamSub = repository
        .watchDreams(DreamStatusFilter.all)
        .listen(dreams.add);
    addTearDown(volumeSub.cancel);
    addTearDown(dreamSub.cancel);
    await pumpEventQueue();
    expect(volumes.last, isNotNull);
    expect(dreams.last, isNotEmpty);

    await clearLocalData(database);
    await pumpEventQueue();
    expect(volumes.last, isNull);
    expect(dreams.last, isEmpty);
  });
}
