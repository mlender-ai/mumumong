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
}
