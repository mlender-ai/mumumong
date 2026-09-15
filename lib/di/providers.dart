import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory/memory_repository.dart';
import '../domain/model/models.dart';
import '../domain/repository/mumumong_repository.dart';

final repositoryProvider = Provider<MumumongRepository>((ref) {
  final repository = MemoryRepository();
  ref.onDispose(repository.dispose);
  return repository;
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

final jobProgressProvider = StreamProvider.family<JobProgress?, String>((
  ref,
  dreamId,
) {
  return ref.watch(repositoryProvider).watchJob(dreamId);
});
