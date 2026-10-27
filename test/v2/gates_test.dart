// V2 drawing of the shared authentication, consent and app-lock gates. The
// rules are lib/ui/auth's; these tests prove the V2 presentation keeps them.
// Invented fixtures only: no account, network or AI.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/auth/auth_controller.dart';
import 'package:mumumong/data/privacy/app_lock.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/ui/settings/app_lock_gate.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/preview/preview_root.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/gates.dart';
import 'package:mumumong/v2/screens/onboarding.dart';
import 'package:mumumong/v2/screens/volume_setup.dart';

import 'support.dart';

const _manuscript = Text('원고 화면');

Future<void> _mount(
  WidgetTester tester, {
  required AuthenticationController controller,
  required AiConsentRepository consent,
  double scale = 1,
}) async {
  setV2View(tester, scale: scale, reduceMotion: true);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => controller,
          disposeNotifier: false,
        ),
        aiConsentRepositoryProvider.overrideWithValue(consent),
      ],
      child: const MumumongV2App(
        home: AuthGate(
          presentation: V2AuthPresentation(),
          manuscript: _manuscript,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<AuthenticationController> _signedIn({bool volume = true}) async {
  final controller = AuthenticationController(
    const _Identity(),
    _Backend(hasSession: true, remoteVolume: volume),
  );
  await controller.restore();
  return controller;
}

Future<void> _check(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(v2Text(text).first);
  await tester.tap(v2Text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('signed out: no sign-in before both checks, then consent is '
      'recorded once and a new account goes to V2 volume setup', (
    tester,
  ) async {
    final backend = _Backend();
    final consent = _Consent(recordVersion: null);
    final controller = AuthenticationController(const _Identity(), backend);
    await controller.restore();
    await _mount(tester, controller: controller, consent: consent);

    expect(find.byType(V2OnboardingScreen), findsOneWidget);
    await _tapText(tester, 'Apple로 시작하기');
    expect(v2Text('Apple로 계속하기'), findsOneWidget);
    expect(v2Text('체험 계정으로 시작'), findsOneWidget);

    await _tapText(tester, 'Apple로 계속하기');
    expect(backend.hasSession, isFalse);
    await _check(tester, 'v2-age-confirmation');
    await _tapText(tester, 'Apple로 계속하기');
    expect(backend.hasSession, isFalse);
    await _check(tester, 'v2-ai-consent');
    await _tapText(tester, 'Apple로 계속하기');

    expect(backend.hasSession, isTrue);
    expect(consent.acceptCalls, 1);
    expect(find.byType(V2VolumeSetupScreen), findsOneWidget);
    expect(find.text('원고 화면'), findsNothing);
  });

  testWidgets('a current consent record opens the manuscript', (tester) async {
    await _mount(tester, controller: await _signedIn(), consent: _Consent());
    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('no consent keeps the manuscript closed', (tester) async {
    await _mount(
      tester,
      controller: await _signedIn(),
      consent: _Consent(recordVersion: null),
    );
    expect(find.text('원고 화면'), findsNothing);
    expect(v2Text('동의하고 계속'), findsOneWidget);
  });

  testWidgets('a newer notice needs a new explicit consent', (tester) async {
    final consent = _Consent(policyVersion: 2, recordVersion: 1);
    await _mount(tester, controller: await _signedIn(), consent: consent);
    expect(find.text('원고 화면'), findsNothing);
    await _check(tester, 'v2-consent-details-toggle');
    expect(v2Text('고지 버전 2'), findsOneWidget);
    await _check(tester, 'v2-age-confirmation');
    await _check(tester, 'v2-ai-consent');
    await _tapText(tester, '동의하고 계속');
    expect(consent.acceptCalls, 1);
    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('a refused acceptance stays closed and says so', (tester) async {
    final consent = _Consent(recordVersion: null, reject: true);
    await _mount(tester, controller: await _signedIn(), consent: consent);
    await _check(tester, 'v2-age-confirmation');
    await _check(tester, 'v2-ai-consent');
    await _tapText(tester, '동의하고 계속');
    expect(consent.acceptCalls, 1);
    expect(find.text('원고 화면'), findsNothing);
    expect(find.byKey(const Key('v2-consent-error')), findsOneWidget);
  });

  testWidgets('an unreadable notice blocks access until a retry succeeds', (
    tester,
  ) async {
    final consent = _Consent(failLoads: 1);
    await _mount(tester, controller: await _signedIn(), consent: consent);
    expect(find.byType(V2GatePage), findsOneWidget);
    expect(v2Text('AI 처리 고지를 확인하지 못했어요.'), findsOneWidget);
    expect(find.text('원고 화면'), findsNothing);
    await _tapText(tester, '다시 시도');
    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('a sign-in network failure shows the V2 retry page', (
    tester,
  ) async {
    final controller = AuthenticationController(
      const _Identity(),
      _Backend(
        signInError: const AuthenticationException(
          AuthenticationFailure.network,
        ),
      ),
    );
    await controller.signInWithApple();
    await _mount(tester, controller: controller, consent: _Consent());
    expect(find.byType(V2GatePage), findsOneWidget);
    expect(v2Text('연결을 확인해 주세요.'), findsOneWidget);
    expect(v2Text('다시 시도'), findsOneWidget);
  });

  testWidgets('waiting for the notice shows the V2 wait page', (tester) async {
    final pending = Completer<AiConsentPolicy>();
    await _mount(
      tester,
      controller: await _signedIn(),
      consent: _Consent(policy: pending.future),
    );
    expect(find.byType(V2WaitPage), findsOneWidget);
    expect(find.text('원고 화면'), findsNothing);
  });

  testWidgets('the app lock draws V2 and opens only after device auth', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final store = MemorySecureValueStore();
    await store.write(AppLockController.storageKey, 'true');
    final authenticator = _Authenticator();
    final lock = AppLockController(store, authenticator);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith((ref) => lock)],
        child: MumumongV2App(
          home: AppLockGate(
            lockedBuilder: (context, lock) => V2LockedPage(lock: lock),
            child: _manuscript,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(V2LockedPage), findsOneWidget);
    expect(find.text('원고 화면'), findsNothing);
    await expectGuidelines(tester, 'app lock');

    authenticator.result = true;
    await _tapText(tester, '잠금 해제');
    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('MumumongV2 (UI=v2) puts the shared gates under V2 drawing', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final controller = AuthenticationController(const _Identity(), _Backend());
    await controller.restore();
    final store = MemorySecureValueStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => controller,
            disposeNotifier: false,
          ),
          aiConsentRepositoryProvider.overrideWithValue(_Consent()),
          appLockProvider.overrideWith(
            (ref) => AppLockController(store, _Authenticator()),
          ),
        ],
        child: const MumumongV2(requireAuthentication: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppLockGate), findsOneWidget);
    expect(find.byType(AuthGate), findsOneWidget);
    expect(find.byType(V2OnboardingScreen), findsOneWidget);
    expect(find.byType(V2Shell), findsNothing);
  });

  testWidgets('MumumongV2 without sign-in opens the V2 shell directly', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final repository = MemoryRepository(seedPrototype: true);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: previewOverrides(
          const PreviewConfig(start: PreviewStart.continued),
          repository,
        ),
        child: const MumumongV2(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppLockGate), findsOneWidget);
    expect(find.byType(AuthGate), findsNothing);
    expect(find.byType(V2Shell), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('gate pages meet the guidelines at text scale $scale', (
      tester,
    ) async {
      await _mount(
        tester,
        controller: await _signedIn(),
        consent: _Consent(failLoads: 1),
        scale: scale,
      );
      await expectGuidelines(tester, 'blocked x$scale');

      await _mount(
        tester,
        controller: await _signedIn(),
        consent: _Consent(recordVersion: null),
        scale: scale,
      );
      await expectGuidelines(tester, 'consent x$scale');
    });
  }
}

class _Consent implements AiConsentRepository {
  _Consent({
    this.policyVersion = 1,
    this.recordVersion = 1,
    this.reject = false,
    this.failLoads = 0,
    this.policy,
  });

  final int policyVersion;
  int? recordVersion;
  final bool reject;
  int failLoads;
  final Future<AiConsentPolicy>? policy;
  int acceptCalls = 0;

  @override
  Future<AiConsentPolicy> loadPolicy() async {
    if (policy case final pending?) return pending;
    if (failLoads > 0) {
      failLoads--;
      throw StateError('synthetic_policy_unavailable');
    }
    return AiConsentPolicy(
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
  }

  @override
  Future<AiConsentRecord> loadCurrentUserRecord() async => AiConsentRecord(
    version: recordVersion,
    consentedAt: recordVersion == null ? null : DateTime.utc(2026, 10, 1),
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

class _Identity implements AppleIdentityProvider {
  const _Identity();

  @override
  Future<AppleSignInResult> authorize() async => const AppleSignInResult(
    identityToken: 'identity-token',
    rawNonce: 'raw-nonce',
  );
}

class _Backend implements AuthenticationBackend {
  _Backend({
    this.hasSession = false,
    this.remoteVolume = false,
    this.signInError,
  });

  @override
  bool hasSession;

  final bool remoteVolume;
  final Object? signInError;

  @override
  bool get sessionIsExpired => false;

  @override
  Future<bool> hasRemoteVolume() async => remoteVolume;

  @override
  Future<void> refreshSession() async => throw UnimplementedError();

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

class _Authenticator implements DeviceAuthenticator {
  bool result = false;

  @override
  Future<bool> authenticate() async => result;
}
