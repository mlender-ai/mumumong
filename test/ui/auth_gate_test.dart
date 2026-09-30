import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/auth/auth_controller.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';

void main() {
  testWidgets('S01은 세 장이고 동의와 연령 확인 전에는 가입할 수 없다', (tester) async {
    final backend = _FakeBackend();
    final controller = AuthenticationController(const _FakeIdentity(), backend);
    await controller.restore();

    await tester.pumpWidget(
      _TestApp(controller: controller, consent: _FakeConsentRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('MUMUMONG · 01 / 03'), findsOneWidget);
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    expect(find.text('MUMUMONG · 02 / 03'), findsOneWidget);
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    expect(find.text('MUMUMONG · 03 / 03'), findsOneWidget);
    expect(find.text('Groq'), findsOneWidget);
    expect(find.text('Apple로 계속하기'), findsOneWidget);
    expect(find.text('체험 계정으로 시작'), findsOneWidget);
    await tester.tap(find.text('Apple로 계속하기'));
    await tester.pump();
    expect(backend.hasSession, isFalse);

    await tester.ensureVisible(find.byKey(const Key('age-confirmation')));
    await tester.tap(find.byKey(const Key('age-confirmation')));
    await tester.pump();
    await tester.tap(find.text('Apple로 계속하기'));
    await tester.pump();
    expect(backend.hasSession, isFalse);
    await tester.ensureVisible(find.byKey(const Key('ai-consent')));
    await tester.tap(find.byKey(const Key('ai-consent')));
    await tester.pump();
    await tester.tap(find.text('Apple로 계속하기'));
    await tester.pumpAndSettle();
    expect(backend.hasSession, isTrue);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('기록된 현재 버전 동의가 있으면 원고를 연다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true, hasRemoteVolume: true),
    );
    await controller.restore();

    await tester.pumpWidget(
      _TestApp(controller: controller, consent: _FakeConsentRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('신규 계정은 동의 후 기본값이 선택된 S02 볼륨 설정으로 보낸다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true),
    );
    await controller.restore();

    await tester.pumpWidget(
      _TestApp(controller: controller, consent: _FakeConsentRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('VOL. 01 · SHORT'), findsOneWidget);
    expect(find.text('균형 있게'), findsOneWidget);
    expect(find.text('담백하게'), findsOneWidget);
    expect(find.text('나의 시점'), findsOneWidget);
    expect(find.text('소설 속 인물 시점'), findsOneWidget);
    expect(find.text('이 설정으로 시작'), findsOneWidget);
  });

  testWidgets('동의가 없으면 인증된 원고도 열리지 않는다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true, hasRemoteVolume: true),
    );
    await controller.restore();
    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        consent: _FakeConsentRepository(recordVersion: null),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('원고 화면'), findsNothing);
    expect(find.text('동의하고 계속'), findsOneWidget);
  });

  testWidgets('고지 버전이 올라가면 다시 명시적으로 동의해야 한다', (tester) async {
    final consent = _FakeConsentRepository(policyVersion: 2, recordVersion: 1);
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true, hasRemoteVolume: true),
    );
    await controller.restore();
    await tester.pumpWidget(_TestApp(controller: controller, consent: consent));
    await tester.pumpAndSettle();
    expect(find.text('원고 화면'), findsNothing);
    expect(find.text('고지 버전 2'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('age-confirmation')));
    await tester.tap(find.byKey(const Key('age-confirmation')));
    await tester.ensureVisible(find.byKey(const Key('ai-consent')));
    await tester.tap(find.byKey(const Key('ai-consent')));
    await tester.pump();
    await tester.tap(find.text('동의하고 계속'));
    await tester.pumpAndSettle();
    expect(consent.acceptCalls, 1);
    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('서버가 동의를 거절하면 인증된 원고가 계속 차단된다', (tester) async {
    final consent = _FakeConsentRepository(recordVersion: null, reject: true);
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true, hasRemoteVolume: true),
    );
    await controller.restore();
    await tester.pumpWidget(_TestApp(controller: controller, consent: consent));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('age-confirmation')));
    await tester.tap(find.byKey(const Key('age-confirmation')));
    await tester.ensureVisible(find.byKey(const Key('ai-consent')));
    await tester.tap(find.byKey(const Key('ai-consent')));
    await tester.pump();
    await tester.tap(find.text('동의하고 계속'));
    await tester.pumpAndSettle();
    expect(find.text('원고 화면'), findsNothing);
    expect(consent.acceptCalls, 1);
  });

  testWidgets('네트워크 실패는 재시도 화면을 보인다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(
        signInError: const AuthenticationException(
          AuthenticationFailure.network,
        ),
      ),
    );
    await controller.signInWithApple();

    await tester.pumpWidget(
      _TestApp(controller: controller, consent: _FakeConsentRepository()),
    );

    expect(find.text('연결을 확인해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller, required this.consent});

  final AuthenticationController controller;
  final AiConsentRepository consent;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => controller,
          disposeNotifier: false,
        ),
        aiConsentRepositoryProvider.overrideWithValue(consent),
      ],
      child: MaterialApp(
        theme: mumumongTheme(),
        home: const AuthGate(manuscript: Text('원고 화면')),
      ),
    );
  }
}

class _FakeConsentRepository implements AiConsentRepository {
  _FakeConsentRepository({
    this.policyVersion = 1,
    this.recordVersion = 1,
    this.reject = false,
  });

  final int policyVersion;
  int? recordVersion;
  final bool reject;
  int acceptCalls = 0;

  @override
  Future<AiConsentPolicy> loadPolicy() async => AiConsentPolicy(
    version: policyVersion,
    message: '꿈 내용은 원고 생성을 위해 AI 모델 제공사로 전송됩니다.',
    providers: [
      AiProviderDisclosure(
        id: 'groq',
        name: 'Groq',
        termsUrl: Uri.parse(
          'https://console.groq.com/docs/legal/services-agreement',
        ),
      ),
    ],
  );

  @override
  Future<AiConsentRecord> loadCurrentUserRecord() async => AiConsentRecord(
    version: recordVersion,
    consentedAt: recordVersion == null ? null : DateTime.utc(2026, 9, 30),
    ageConfirmed: recordVersion != null,
  );

  @override
  Future<bool> accept({
    required int version,
    required bool ageConfirmed,
  }) async {
    acceptCalls++;
    if (reject || !ageConfirmed || version != policyVersion) return false;
    recordVersion = version;
    return true;
  }
}

class _FakeIdentity implements AppleIdentityProvider {
  const _FakeIdentity();

  @override
  Future<AppleSignInResult> authorize() async {
    return const AppleSignInResult(
      identityToken: 'identity-token',
      rawNonce: 'raw-nonce',
    );
  }
}

class _FakeBackend implements AuthenticationBackend {
  _FakeBackend({
    this.hasSession = false,
    bool hasRemoteVolume = false,
    this.signInError,
  }) : remoteVolumeExists = hasRemoteVolume;

  @override
  bool hasSession;

  @override
  bool get sessionIsExpired => false;

  final bool remoteVolumeExists;
  final Object? signInError;

  @override
  Future<bool> hasRemoteVolume() async => remoteVolumeExists;

  @override
  Future<void> refreshSession() async {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithApple(AppleSignInResult credential) async {
    if (signInError case final error?) throw error;
    hasSession = true;
  }

  @override
  Future<void> signInAnonymously() async {
    if (signInError case final error?) throw error;
    hasSession = true;
  }
}
