final class DreamProcessingException implements Exception {
  const DreamProcessingException(this.dreamId, this.stage, this.code);

  final String dreamId;
  final String stage;
  final String code;

  @override
  String toString() {
    return 'DreamProcessingException('
        'dreamId: $dreamId, stage: $stage, code: $code)';
  }
}
