import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env/env.dart';
import '../data/auth/apple_authentication.dart';
import '../data/auth/auth_controller.dart';
import '../data/auth/secure_session_storage.dart';
import '../data/engine/engine_client.dart';
import '../data/engine/mock_engine_client.dart';
import '../data/local/database.dart';
import '../data/local/drift_repository.dart';
import '../data/privacy/app_lock.dart';
import '../data/speech/speech_input.dart';
import '../domain/model/models.dart';
import '../domain/repository/mumumong_repository.dart';

final authControllerProvider = ChangeNotifierProvider<AuthenticationController>(
  (ref) {
    final controller = AuthenticationController(
      const NativeAppleIdentityProvider(),
      SupabaseAuthenticationBackend(Supabase.instance.client),
    );
    unawaited(controller.restore());
    return controller;
  },
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<MumumongRepository>((ref) {
  return DriftRepository(ref.watch(databaseProvider));
});

final speechInputProvider = Provider<SpeechInput>(
  (ref) => OnDeviceSpeechInput(),
);

final appLockProvider = ChangeNotifierProvider<AppLockController>((ref) {
  return AppLockController(KeychainValueStore(), LocalDeviceAuthenticator());
});

final engineClientProvider = Provider<EngineClient>((ref) {
  if (AppEnv.engine == EngineMode.remote) {
    return RemoteEngineClient(
      SupabaseRemoteEngineGateway(Supabase.instance.client),
    );
  }
  final repository = ref.watch(repositoryProvider);
  if (repository is! MockEngineStore) {
    throw StateError('The mock engine requires a MockEngineStore');
  }
  final store = repository as MockEngineStore;
  final client = MockEngineClient(
    store: store,
    scenario: MockEngineCaseParsing.fromName(AppEnv.mockCase),
  );
  ref.onDispose(client.dispose);
  return client;
});

final activeVolumeProvider = StreamProvider<Volume?>((ref) {
  return ref.watch(repositoryProvider).watchActiveVolume();
});

final dreamsProvider = StreamProvider.family<List<Dream>, DreamStatusFilter>((
  ref,
  filter,
) {
  return ref.watch(repositoryProvider).watchDreams(filter);
});

final dreamElementsProvider = StreamProvider.family<List<DreamElement>, String>(
  (ref, dreamId) {
    return ref.watch(repositoryProvider).watchDreamElements(dreamId);
  },
);

final scenesProvider = StreamProvider.family<List<Scene>, String>((
  ref,
  volumeId,
) {
  return ref.watch(repositoryProvider).watchScenes(volumeId);
});

final passagesProvider = StreamProvider.family<List<Passage>, String>((
  ref,
  sceneId,
) {
  return ref.watch(repositoryProvider).watchPassages(sceneId);
});

final recentProgressProvider =
    StreamProvider.family<List<ProgressEvent>, String>((ref, volumeId) {
      return ref.watch(repositoryProvider).watchRecentProgress(volumeId);
    });

final linkDecisionsProvider = StreamProvider.family<List<LinkDecision>, String>(
  (ref, dreamId) {
    return ref.watch(repositoryProvider).watchLinkDecisions(dreamId);
  },
);

final jobProgressProvider = StreamProvider.family<JobProgress?, String>((
  ref,
  dreamId,
) {
  return ref.watch(engineClientProvider).watch(dreamId);
});
