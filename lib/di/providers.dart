import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/env/env.dart';
import '../core/design/ui_preferences.dart';
import '../data/auth/apple_authentication.dart';
import '../data/auth/auth_controller.dart';
import '../data/auth/secure_session_storage.dart';
import '../data/engine/engine_client.dart';
import '../data/engine/mock_engine_client.dart';
import '../data/local/database.dart';
import '../data/export/book_store.dart';
import '../domain/model/frozen_book.dart';
import '../data/local/drift_repository.dart';
import '../data/privacy/app_lock.dart';
import '../data/speech/speech_input.dart';
import '../data/sync/cloud_sync_service.dart';
import '../data/sync/outbox_worker.dart';
import '../domain/model/models.dart';
import '../domain/repository/mumumong_repository.dart';

final uiPreferenceStoreProvider = Provider<UiPreferenceStore>(
  (ref) => DeviceUiPreferenceStore(),
);
final uiPreferencesProvider = ChangeNotifierProvider<UiPreferences>(
  (ref) => UiPreferences(ref.watch(uiPreferenceStoreProvider)),
);

// A scene becomes an opened result when its first passage is read in Reader.
// No local timer or progress counter invents new results.
final newSceneProvider = Provider.autoDispose.family<Scene?, String>((
  ref,
  volumeId,
) {
  final scenes = ref.watch(scenesProvider(volumeId)).value ?? const <Scene>[];
  for (final scene in scenes.reversed) {
    final passages = ref.watch(passagesProvider(scene.id)).value;
    if (passages != null &&
        passages.isNotEmpty &&
        passages.first.firstReadAt == null) {
      return scene;
    }
  }
  return null;
});

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
  final remote = AppEnv.engine == EngineMode.remote;
  return DriftRepository(
    ref.watch(databaseProvider),
    seedPrototype: !remote,
    queueCloudMutations: remote,
  );
});

final remoteEngineGatewayProvider = Provider<RemoteEngineGateway>((ref) {
  return SupabaseRemoteEngineGateway(Supabase.instance.client);
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(
    ref.watch(databaseProvider),
    SupabaseCloudSyncGateway(Supabase.instance.client),
  );
});

final bookStoreProvider = Provider<BookStore>(
  (ref) => BookStore(
    ref.watch(databaseProvider),
    gateway: AppEnv.engine == EngineMode.remote
        ? SupabaseBookGateway(Supabase.instance.client)
        : null,
    pullVolume: AppEnv.engine == EngineMode.remote
        ? () async {
            await ref.read(cloudSyncServiceProvider).bootstrapCurrentAccount();
          }
        : null,
  ),
);
final libraryReturnHomeProvider = StateProvider<int>((ref) => 0);
final completedBooksProvider = StreamProvider.autoDispose<List<FrozenBook>>(
  (ref) => ref.watch(bookStoreProvider).watchBooks(),
);
final completionRequestProvider = StreamProvider.autoDispose
    .family<LocalCompletionRequestRow?, String>(
      (ref, id) => ref.watch(bookStoreProvider).watchRequest(id),
    );

final outboxWorkerProvider = Provider.autoDispose<OutboxWorker?>((ref) {
  if (AppEnv.engine != EngineMode.remote) return null;
  final sync = ref.watch(cloudSyncServiceProvider);
  final gateway = ref.watch(remoteEngineGatewayProvider);
  final engine = RemoteEngineClient(gateway, sync: sync);
  final worker = OutboxWorker(ref.watch(databaseProvider), (
    operation,
    payload,
    idempotencyKey,
  ) async {
    switch (operation) {
      case 'create_dream':
        final dreamId = payload['dream_id'] as String;
        await sync.pushDream(dreamId);
      case 'process_dream':
        final dreamId = payload['dream_id'] as String;
        await engine.enqueue(dreamId, idempotencyKey);
      case 'complete_volume':
        await ref.read(bookStoreProvider).deliver(payload);
      case 'decide_link' ||
          'update_generation_settings' ||
          'change_placement' ||
          'edit_passage' ||
          'revert_passage' ||
          'mark_passage_read' ||
          'edit_dream' ||
          'remove_dream' ||
          'delete_dream':
        await sync.deliverInteraction(operation, payload);
      default:
        throw StateError('unsupported_outbox_operation');
    }
    return DeliveryReceipt.applied;
  });
  unawaited(worker.start());
  ref.onDispose(worker.dispose);
  return worker;
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
      ref.watch(remoteEngineGatewayProvider),
      sync: ref.watch(cloudSyncServiceProvider),
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

final generationSettingsProvider = StreamProvider.autoDispose
    .family<GenerationSettingsState?, String>(
      (ref, volumeId) =>
          ref.watch(repositoryProvider).watchGenerationSettings(volumeId),
    );

final readerPositionProvider = FutureProvider.autoDispose
    .family<ReaderPosition?, String>(
      (ref, volumeId) =>
          ref.watch(repositoryProvider).loadReaderPosition(volumeId),
    );

// Connectivity describes the device link, not server availability.
final networkConnectedProvider = StreamProvider.autoDispose<bool?>((
  ref,
) async* {
  if (AppEnv.engine == EngineMode.mock) {
    yield true;
    return;
  }
  final connectivity = Connectivity();
  try {
    yield !(await connectivity.checkConnectivity()).contains(
      ConnectivityResult.none,
    );
    yield* connectivity.onConnectivityChanged.map(
      (states) => !states.contains(ConnectivityResult.none),
    );
  } on Object {
    yield null;
  }
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

// Kept alive by the consent-approved shell, not by a disposable capture route.
// Restoring a subscription must never enqueue or regenerate anything.
final generationRecoveryProvider = Provider.autoDispose<void>((ref) {
  final dreams = ref.watch(dreamsProvider(DreamStatusFilter.all)).value;
  for (final dream in dreams ?? const <Dream>[]) {
    if (dream.status == DreamStatus.processing) {
      ref.watch(jobProgressProvider(dream.id));
    }
  }
});

final jobProgressProvider = StreamProvider.autoDispose
    .family<JobProgress?, String>((ref, dreamId) {
      final repository = ref.watch(repositoryProvider);
      final engine = ref.watch(engineClientProvider);
      return Stream<JobProgress?>.multi((controller) {
        var receivedRemote = false;
        var cancelled = false;
        // Attach immediately; loading a cache must not lose a hot job event.
        final subscription = engine
            .watch(dreamId)
            .asyncMap((progress) async {
              await repository.recordJobProgress(progress);
              return progress;
            })
            .listen(
              (progress) {
                receivedRemote = true;
                controller.add(progress);
              },
              onError: (Object error, StackTrace stack) {
                receivedRemote = true;
                controller.addError(error, stack);
              },
              onDone: controller.close,
            );
        unawaited(
          repository
              .watchJob(dreamId)
              .first
              .then(
                (cached) {
                  if (!cancelled && !receivedRemote && cached != null) {
                    controller.add(cached);
                  }
                },
                onError: (Object error, StackTrace stack) {
                  if (!cancelled && !receivedRemote) {
                    controller.addError(error, stack);
                  }
                },
              ),
        );
        controller.onCancel = () async {
          cancelled = true;
          await subscription.cancel();
        };
      });
    });
