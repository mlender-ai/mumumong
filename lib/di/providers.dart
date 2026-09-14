import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory/memory_repository.dart';
import '../domain/repository/mumumong_repository.dart';

final repositoryProvider = Provider<MumumongRepository>((ref) {
  final repository = MemoryRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
