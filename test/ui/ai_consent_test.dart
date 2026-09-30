import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';

void main() {
  test(
    'current provider names and legal URLs come from versioned policy data',
    () {
      final policy = AiConsentPolicy.fromJson({
        'version': 2,
        'message': '꿈 내용은 원고 생성을 위해 AI 모델 제공사로 전송됩니다.',
        'providers': [
          {
            'id': 'groq',
            'name': 'Groq',
            'terms_url':
                'https://console.groq.com/docs/legal/services-agreement',
            'data_url': 'https://console.groq.com/docs/your-data',
          },
          {
            'id': 'example',
            'name': '다른 공급사',
            'terms_url': 'https://example.com/terms',
          },
        ],
      });
      expect(policy.version, 2);
      expect(policy.providers.map((provider) => provider.name), [
        'Groq',
        '다른 공급사',
      ]);
      expect(policy.providers.first.dataUrl?.host, 'console.groq.com');
    },
  );

  test(
    'missing provider or insecure legal URL cannot be presented for consent',
    () {
      expect(
        () => AiConsentPolicy.fromJson({
          'version': 1,
          'message': 'AI 처리 고지',
          'providers': <Object>[],
        }),
        throwsFormatException,
      );
      expect(
        () => AiConsentPolicy.fromJson({
          'version': 1,
          'message': 'AI 처리 고지',
          'providers': [
            {
              'id': 'groq',
              'name': 'Groq',
              'terms_url': 'http://example.com/terms',
            },
          ],
        }),
        throwsFormatException,
      );
    },
  );

  test('consent requires same policy version, timestamp and age assertion', () {
    const policy = AiConsentPolicy(
      version: 2,
      message: 'AI 처리 고지',
      providers: [],
    );
    final current = AiConsentRecord(
      version: 2,
      consentedAt: DateTime.utc(2026, 9, 30),
      ageConfirmed: true,
    );
    expect(current.isCurrentFor(policy), isTrue);
    expect(
      AiConsentRecord.fromJson({
        'consent_version': 1,
        'consented_at': '2026-09-30T00:00:00Z',
        'age_confirmed': true,
      }).isCurrentFor(policy),
      isFalse,
    );
    expect(AiConsentRecord.fromJson(null).isCurrentFor(policy), isFalse);
  });
}
