import '../../ui/auth/ai_consent.dart';

/// DESIGN MOCK: a local policy for the preview. Accepting it is never sent
/// anywhere; the preview has no account.
class PreviewAiConsentRepository implements AiConsentRepository {
  const PreviewAiConsentRepository();

  static final policy = AiConsentPolicy(
    version: 1,
    message:
        '미리보기 안내입니다. 실제 앱에서는 꿈을 소설로 만들기 위해 기록한 내용을 AI 처리 업체로 보내며, '
        '현재 서버가 게시한 고지만 동의할 수 있어요. 이 미리보기는 아무것도 보내지 않아요.',
    providers: [
      AiProviderDisclosure(
        id: 'preview',
        name: '미리보기 AI',
        termsUrl: Uri.parse('https://example.com/preview-terms'),
      ),
    ],
  );

  @override
  Future<AiConsentPolicy> loadPolicy() async => policy;

  @override
  Future<AiConsentRecord> loadCurrentUserRecord() async =>
      const AiConsentRecord(
        version: null,
        consentedAt: null,
        ageConfirmed: false,
      );

  @override
  Future<bool> accept({
    required int version,
    required bool ageConfirmed,
  }) async => ageConfirmed;
}
