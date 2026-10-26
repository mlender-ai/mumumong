import 'database.dart';

Future<void> clearLocalData(
  AppDatabase database,
) => database.transaction(() async {
  // Delete children before parents so the same code works with FK enforcement.
  for (final table in const [
    'completed_books',
    'completion_requests',
    'presentation_receipts',
    'generation_settings_changes',
    'reader_positions',
    'sync_state',
    'outbox',
    'dream_drafts',
    'progress_events',
    'link_decisions',
    'jobs',
    'passages',
    'scenes',
    'entities',
    'dream_elements',
    'dreams',
    'volumes',
  ]) {
    await database.customStatement('DELETE FROM $table');
  }
});
