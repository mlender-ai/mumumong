import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/auth/auth_controller.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';

void main() {
  testWidgets('로그아웃 화면은 Apple 로그인과 최소 정보 안내만 보인다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(),
    );
    await controller.restore();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('Apple로 계속하기'), findsOneWidget);
    expect(find.text('이름과 이메일은 저장하지 않습니다.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('원격 볼륨이 있는 세션은 원고를 연다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(hasSession: true, hasRemoteVolume: true),
    );
    await controller.restore();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('원고 화면'), findsOneWidget);
  });

  testWidgets('신규 계정은 S02 볼륨 설정 경계로 보낸다', (tester) async {
    final controller = AuthenticationController(
      const _FakeIdentity(),
      _FakeBackend(),
    );
    await controller.signInWithApple();

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('VOL. 01'), findsOneWidget);
    expect(find.text('VOLUME SETUP · S02'), findsOneWidget);
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

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.text('연결을 확인해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller});

  final AuthenticationController controller;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => controller,
          disposeNotifier: false,
        ),
      ],
      child: MaterialApp(
        theme: mumumongTheme(),
        home: const AuthGate(manuscript: Text('원고 화면')),
      ),
    );
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
}
