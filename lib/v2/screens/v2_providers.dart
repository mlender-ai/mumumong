import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/models.dart';

typedef V2CreateVolume =
    Future<void> Function({
      required AdaptationLevel adaptation,
      required WritingStyle style,
      required NarrativeVoice narrativeVoice,
    });

/// How the first manuscript is created. Null uses the authenticated
/// CloudSyncService exactly as V1 does; the preview injects the in-memory
/// walkthrough adapter.
final v2CreateVolumeProvider = Provider<V2CreateVolume?>((ref) => null);

/// Shown while recording when the voice is a design mock (preview only).
final v2VoiceNoteProvider = Provider<String?>((ref) => null);

/// True only inside the V2 preview build; screens use it to label mocks.
final v2PreviewProvider = Provider<bool>((ref) => false);
