import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller.dart';

class NativeAppleIdentityProvider implements AppleIdentityProvider {
  const NativeAppleIdentityProvider();

  @override
  Future<AppleSignInResult> authorize() async {
    if (!await SignInWithApple.isAvailable()) {
      throw const AuthenticationException(AuthenticationFailure.unavailable);
    }

    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
        nonce: hashedNonce,
      );
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const AuthenticationException(
          AuthenticationFailure.invalidCredential,
        );
      }
      return AppleSignInResult(
        identityToken: identityToken,
        rawNonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthenticationCancelled();
      }
      throw const AuthenticationException(AuthenticationFailure.unknown);
    } on SignInWithAppleException {
      throw const AuthenticationException(AuthenticationFailure.unavailable);
    }
  }
}

class SupabaseAuthenticationBackend implements AuthenticationBackend {
  const SupabaseAuthenticationBackend(this._client);

  final SupabaseClient _client;

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  bool get sessionIsExpired => _client.auth.currentSession?.isExpired ?? false;

  @override
  Future<void> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      if (response.session == null) {
        throw const AuthenticationException(
          AuthenticationFailure.expiredSession,
        );
      }
    } on AuthenticationException {
      rethrow;
    } on AuthException {
      throw const AuthenticationException(AuthenticationFailure.expiredSession);
    } catch (_) {
      throw const AuthenticationException(AuthenticationFailure.network);
    }
  }

  @override
  Future<void> signInWithApple(AppleSignInResult credential) async {
    try {
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken,
        nonce: credential.rawNonce,
      );
      if (response.session == null) {
        throw const AuthenticationException(
          AuthenticationFailure.invalidCredential,
        );
      }
    } on AuthenticationException {
      rethrow;
    } on AuthRetryableFetchException {
      throw const AuthenticationException(AuthenticationFailure.network);
    } on AuthException {
      throw const AuthenticationException(
        AuthenticationFailure.invalidCredential,
      );
    } catch (_) {
      throw const AuthenticationException(AuthenticationFailure.network);
    }
  }

  @override
  Future<bool> hasRemoteVolume() async {
    try {
      final rows = await _client.from('volumes').select('id').limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      throw const AuthenticationException(AuthenticationFailure.network);
    }
  }
}
