import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/log/app_log.dart';

void main() {
  late String capturedName;
  late Map<String, Object?> capturedFields;

  setUp(() {
    capturedName = '';
    capturedFields = const {};
    AppLog.setSinkForTesting((name, fields) {
      capturedName = name;
      capturedFields = fields;
    });
  });

  tearDown(AppLog.resetSinkForTesting);

  test(
    'nested objects cannot smuggle manuscript text through allowed keys',
    () {
      AppLog.event('processing_failed', {
        'code': {'text': 'private'},
        'count': ['private'],
        'stage': 'write',
      });
      expect(capturedFields, {'stage': 'write'});
    },
  );

  test('비허용 키를 제거한다', () {
    AppLog.event('processing_started', {
      'dream_id': 'dream-1',
      'raw_text': '기록하면 안 되는 원문',
    });

    expect(capturedName, 'processing_started');
    expect(capturedFields, {'dream_id': 'dream-1'});
  });

  test('64자를 초과하는 문자열을 제거한다', () {
    AppLog.event('processing_failed', {'code': 'x' * 65, 'stage': 'write'});

    expect(capturedFields, {'stage': 'write'});
  });

  test('허용 키와 64자 문자열을 보존한다', () {
    AppLog.event('processing_completed', {
      'status': 'x' * 64,
      'ms': 1200,
      'count': 3,
    });

    expect(capturedFields, {'status': 'x' * 64, 'ms': 1200, 'count': 3});
  });
}
