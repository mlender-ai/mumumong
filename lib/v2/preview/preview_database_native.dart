import 'package:drift/native.dart';

import '../../data/local/database.dart';

/// In-memory database: the preview never opens the app's on-device store.
AppDatabase previewDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());
