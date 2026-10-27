import 'package:drift_flutter/drift_flutter.dart';

import '../../data/local/database.dart';

/// A separately named browser database so the preview never opens the
/// app's own store, even on the same origin.
AppDatabase previewDatabase() => AppDatabase.forTesting(
  driftDatabase(
    name: 'mumumong_v2_preview',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ),
);
