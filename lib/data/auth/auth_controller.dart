import 'package:flutter/foundation.dart';

enum AuthenticationPhase { restoring, signedOut, signingIn, signedIn, failure }

enum AuthenticationFailure {
  network,
  expiredSession,
  unavailable,
  invalidCredential,
  unknown,
}

enum AuthenticationDestination { volumeSetup, manuscript }

class AuthenticationState {
  const AuthenticationState({
    required this.phase,
    this.failure,
    this.destination,
  });

  const AuthenticationState.restoring()
    : this(phase: AuthenticationPhase.restoring);

  const AuthenticationState.signedOut()
    : this(phase: AuthenticationPhase.signedOut);

  final AuthenticationPhase phase;
  final AuthenticationFailure? failure;
  final AuthenticationDestination? destination;
}

class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    required this.rawNonce,
  });

  final String identityToken;
  final String rawNonce;
}

abstract interface class AppleIdentityProvider {
  Future<AppleSignInResult> authorize();
}

abstract interface class AuthenticationBackend {
  bool get hasSession;
  bool get sessionIsExpired;

  Future<void> refreshSession();
  Future<void> signInWithApple(AppleSignInResult credential);
  Future<bool> hasRemoteVolume();
}

class AuthenticationCancelled implements Exception {
  const AuthenticationCancelled();
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.failure);

  final AuthenticationFailure failure;
}

class AuthenticationController extends ChangeNotifier {
  AuthenticationController(this._appleIdentityProvider, this._backend);

  final AppleIdentityProvider _appleIdentityProvider;
  final AuthenticationBackend _backend;

  AuthenticationState _state = const AuthenticationState.restoring();
  AuthenticationState get state => _state;

  Future<void> restore() async {
    if (!_backend.hasSession) {
      _setState(const AuthenticationState.signedOut());
      return;
    }

    if (_backend.sessionIsExpired) {
      try {
        await _backend.refreshSession();
      } on AuthenticationException {
        _setState(
          const AuthenticationState(
            phase: AuthenticationPhase.failure,
            failure: AuthenticationFailure.expiredSession,
          ),
        );
        return;
      }
    }

    await _completeAuthentication();
  }

  Future<void> signInWithApple() async {
    if (_state.phase == AuthenticationPhase.signingIn) return;
    _setState(const AuthenticationState(phase: AuthenticationPhase.signingIn));

    try {
      final credential = await _appleIdentityProvider.authorize();
      await _backend.signInWithApple(credential);
      await _completeAuthentication();
    } on AuthenticationCancelled {
      _setState(const AuthenticationState.signedOut());
    } on AuthenticationException catch (error) {
      _setState(
        AuthenticationState(
          phase: AuthenticationPhase.failure,
          failure: error.failure,
        ),
      );
    } catch (_) {
      _setState(
        const AuthenticationState(
          phase: AuthenticationPhase.failure,
          failure: AuthenticationFailure.unknown,
        ),
      );
    }
  }

  Future<void> retry() {
    if (_state.failure == AuthenticationFailure.network &&
        _backend.hasSession) {
      _setState(const AuthenticationState.restoring());
      return _completeAuthentication();
    }
    return signInWithApple();
  }

  void completeVolumeSetup() {
    if (_state.phase != AuthenticationPhase.signedIn) return;
    _setState(
      const AuthenticationState(
        phase: AuthenticationPhase.signedIn,
        destination: AuthenticationDestination.manuscript,
      ),
    );
  }

  Future<void> _completeAuthentication() async {
    try {
      final hasVolume = await _backend.hasRemoteVolume();
      _setState(
        AuthenticationState(
          phase: AuthenticationPhase.signedIn,
          destination: hasVolume
              ? AuthenticationDestination.manuscript
              : AuthenticationDestination.volumeSetup,
        ),
      );
    } on AuthenticationException catch (error) {
      _setState(
        AuthenticationState(
          phase: AuthenticationPhase.failure,
          failure: error.failure,
        ),
      );
    } catch (_) {
      _setState(
        const AuthenticationState(
          phase: AuthenticationPhase.failure,
          failure: AuthenticationFailure.network,
        ),
      );
    }
  }

  void _setState(AuthenticationState value) {
    _state = value;
    notifyListeners();
  }
}
