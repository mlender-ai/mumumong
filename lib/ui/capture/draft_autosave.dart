import 'dart:async';

import '../../domain/repository/mumumong_repository.dart';

/// Serializes autosaves, discard and submission so a late save cannot restore
/// a draft that has already been submitted or discarded.
class DraftAutosave {
  DraftAutosave(this.repository);

  final MumumongRepository repository;
  Timer? _timer;
  Future<void> _tail = Future.value();
  DreamDraft? _pending;
  bool _disposed = false;
  bool _submitting = false;

  void changed(DreamDraft draft, {bool immediate = false}) {
    if (_disposed || _submitting) return;
    _pending = draft;
    _timer?.cancel();
    if (immediate) {
      unawaited(flush());
    } else {
      _timer = Timer(const Duration(milliseconds: 500), flush);
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> flush() {
    _timer?.cancel();
    return _serialize(() async {
      final draft = _pending;
      if (draft == null || _submitting) return;
      try {
        await repository.saveDraft(draft);
        if (identical(_pending, draft)) _pending = null;
      } on Object {
        if (!_disposed) {
          _timer = Timer(const Duration(seconds: 1), flush);
        }
      }
    });
  }

  Future<void> discard() {
    _timer?.cancel();
    _pending = null;
    return _serialize(repository.clearDraft);
  }

  Future<String> submit(DreamDraft draft) async {
    _submitting = true;
    _timer?.cancel();
    try {
      final id = await _serialize(() => repository.submitDream(draft));
      _pending = null;
      return id;
    } on Object {
      _pending = draft;
      rethrow;
    } finally {
      _submitting = false;
      if (_pending != null && !_disposed) {
        _timer = Timer(const Duration(seconds: 1), flush);
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(flush());
  }
}
