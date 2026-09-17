import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/auth/auth_controller.dart';

void main() {
  const credential = AppleSignInResult(
    identityToken: 'identity-token',
    rawNonce: 'raw-nonce',
  );

  group('AuthenticationController', () {
    test('신규 로그인은 원격 볼륨이 없으면 S02로 보낸다', () async {
      final identity = _FakeAppleIdentityProvider(result: credential);
      final backend = _FakeAuthenticationBackend(hasRemoteVolume: false);
      final controller = AuthenticationController(identity, backend);

      await controller.signInWithApple();

      expect(controller.state.phase, AuthenticationPhase.signedIn);
      expect(
        controller.state.destination,
        AuthenticationDestination.volumeSetup,
      );
      expect(identity.authorizeCalls, 1);
      expect(backend.receivedCredential, same(credential));
    });

    test('기존 세션과 볼륨이 있으면 S03을 연다', () async {
      final identity = _FakeAppleIdentityProvider(result: credential);
      final backend = _FakeAuthenticationBackend(
        hasSession: true,
        hasRemoteVolume: true,
      );
      final controller = AuthenticationController(identity, backend);

      await controller.restore();

      expect(controller.state.phase, AuthenticationPhase.signedIn);
      expect(
        controller.state.destination,
        AuthenticationDestination.manuscript,
      );
      expect(identity.authorizeCalls, 0);
    });

    test('Apple 인증 취소는 실패로 보이지 않는다', () async {
      final identity = _FakeAppleIdentityProvider(
        error: const AuthenticationCancelled(),
      );
      final controller = AuthenticationController(
        identity,
        _FakeAuthenticationBackend(),
      );

      await controller.signInWithApple();

      expect(controller.state.phase, AuthenticationPhase.signedOut);
      expect(controller.state.failure, isNull);
    });

    test('오프라인 로그인은 재시도 가능한 네트워크 실패다', () async {
      final backend = _FakeAuthenticationBackend(
        signInError: const AuthenticationException(
          AuthenticationFailure.network,
        ),
      );
      final controller = AuthenticationController(
        _FakeAppleIdentityProvider(result: credential),
        backend,
      );

      await controller.signInWithApple();

      expect(controller.state.phase, AuthenticationPhase.failure);
      expect(controller.state.failure, AuthenticationFailure.network);
    });

    test('만료된 세션은 자동 갱신한 뒤 S03을 연다', () async {
      final backend = _FakeAuthenticationBackend(
        hasSession: true,
        sessionIsExpired: true,
        hasRemoteVolume: true,
      );
      final controller = AuthenticationController(
        _FakeAppleIdentityProvider(result: credential),
        backend,
      );

      await controller.restore();

      expect(backend.refreshCalls, 1);
      expect(controller.state.phase, AuthenticationPhase.signedIn);
      expect(
        controller.state.destination,
        AuthenticationDestination.manuscript,
      );
    });

    test('만료 세션 갱신 실패 시 재로그인을 요청한다', () async {
      final backend = _FakeAuthenticationBackend(
        hasSession: true,
        sessionIsExpired: true,
        refreshError: const AuthenticationException(
          AuthenticationFailure.expiredSession,
        ),
      );
      final controller = AuthenticationController(
        _FakeAppleIdentityProvider(result: credential),
        backend,
      );

      await controller.restore();

      expect(controller.state.phase, AuthenticationPhase.failure);
      expect(controller.state.failure, AuthenticationFailure.expiredSession);
    });

    test('볼륨 조회 재시도는 Apple 팝업을 다시 열지 않는다', () async {
      final identity = _FakeAppleIdentityProvider(result: credential);
      final backend = _FakeAuthenticationBackend(
        hasRemoteVolume: true,
        volumeError: const AuthenticationException(
          AuthenticationFailure.network,
        ),
      );
      final controller = AuthenticationController(identity, backend);

      await controller.signInWithApple();
      backend.volumeError = null;
      await controller.retry();

      expect(controller.state.phase, AuthenticationPhase.signedIn);
      expect(identity.authorizeCalls, 1);
      expect(backend.volumeCalls, 2);
    });
  });
}

class _FakeAppleIdentityProvider implements AppleIdentityProvider {
  _FakeAppleIdentityProvider({this.result, this.error});

  final AppleSignInResult? result;
  final Object? error;
  int authorizeCalls = 0;

  @override
  Future<AppleSignInResult> authorize() async {
    authorizeCalls += 1;
    if (error case final error?) throw error;
    return result!;
  }
}

class _FakeAuthenticationBackend implements AuthenticationBackend {
  _FakeAuthenticationBackend({
    this.hasSession = false,
    this.sessionIsExpired = false,
    bool hasRemoteVolume = false,
    this.signInError,
    this.refreshError,
    this.volumeError,
  }) : remoteVolumeExists = hasRemoteVolume;

  @override
  bool hasSession;

  @override
  bool sessionIsExpired;

  bool remoteVolumeExists;
  Object? signInError;
  Object? refreshError;
  Object? volumeError;
  int refreshCalls = 0;
  int volumeCalls = 0;
  AppleSignInResult? receivedCredential;

  @override
  Future<void> refreshSession() async {
    refreshCalls += 1;
    if (refreshError case final error?) throw error;
    sessionIsExpired = false;
  }

  @override
  Future<void> signInWithApple(AppleSignInResult credential) async {
    if (signInError case final error?) throw error;
    receivedCredential = credential;
    hasSession = true;
  }

  @override
  Future<bool> hasRemoteVolume() async {
    volumeCalls += 1;
    if (volumeError case final error?) throw error;
    return remoteVolumeExists;
  }
}
