import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only the published, current server policy can be accepted. Candidate models
/// used by offline evaluation are not part of this disclosure.
class AiConsentPolicy {
  const AiConsentPolicy({
    required this.version,
    required this.message,
    required this.providers,
  });

  final int version;
  final String message;
  final List<AiProviderDisclosure> providers;

  factory AiConsentPolicy.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final message = json['message'];
    final rawProviders = json['providers'];
    if (version is! int ||
        version < 1 ||
        message is! String ||
        message.trim().isEmpty ||
        rawProviders is! List ||
        rawProviders.isEmpty) {
      throw const FormatException('invalid_ai_consent_policy');
    }
    return AiConsentPolicy(
      version: version,
      message: message.trim(),
      providers: rawProviders
          .map(
            (entry) => AiProviderDisclosure.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class AiProviderDisclosure {
  const AiProviderDisclosure({
    required this.id,
    required this.name,
    required this.termsUrl,
    this.dataUrl,
  });

  final String id;
  final String name;
  final Uri termsUrl;
  final Uri? dataUrl;

  factory AiProviderDisclosure.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final rawTermsUrl = json['terms_url'];
    final termsUrl = rawTermsUrl is String ? Uri.tryParse(rawTermsUrl) : null;
    final rawDataUrl = json['data_url'];
    final dataUrl = rawDataUrl is String ? Uri.tryParse(rawDataUrl) : null;
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        termsUrl == null ||
        termsUrl.scheme != 'https' ||
        termsUrl.host.isEmpty ||
        (rawDataUrl != null &&
            (dataUrl == null ||
                dataUrl.scheme != 'https' ||
                dataUrl.host.isEmpty))) {
      throw const FormatException('invalid_ai_provider_disclosure');
    }
    return AiProviderDisclosure(
      id: id.trim(),
      name: name.trim(),
      termsUrl: termsUrl,
      dataUrl: dataUrl,
    );
  }
}

class AiConsentRecord {
  const AiConsentRecord({
    required this.version,
    required this.consentedAt,
    required this.ageConfirmed,
  });

  final int? version;
  final DateTime? consentedAt;
  final bool ageConfirmed;

  bool isCurrentFor(AiConsentPolicy policy) =>
      ageConfirmed && consentedAt != null && version == policy.version;

  factory AiConsentRecord.fromJson(Map<String, dynamic>? json) {
    final version = json?['consent_version'];
    final rawConsentedAt = json?['consented_at'];
    return AiConsentRecord(
      version: version is int ? version : null,
      consentedAt: rawConsentedAt is String
          ? DateTime.tryParse(rawConsentedAt)
          : null,
      ageConfirmed: json?['age_confirmed'] == true,
    );
  }
}

abstract interface class AiConsentRepository {
  Future<AiConsentPolicy> loadPolicy();
  Future<AiConsentRecord> loadCurrentUserRecord();
  Future<bool> accept({required int version, required bool ageConfirmed});
}

class SupabaseAiConsentRepository implements AiConsentRepository {
  const SupabaseAiConsentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AiConsentPolicy> loadPolicy() async {
    final row = await _client
        .from('ai_consent_policy')
        .select('version, message, providers')
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) throw StateError('ai_consent_policy_unavailable');
    return AiConsentPolicy.fromJson(row);
  }

  @override
  Future<AiConsentRecord> loadCurrentUserRecord() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('ai_consent_requires_authentication');
    final row = await _client
        .from('profiles')
        .select('consent_version, consented_at, age_confirmed')
        .eq('user_id', user.id)
        .maybeSingle();
    return AiConsentRecord.fromJson(row);
  }

  @override
  Future<bool> accept({
    required int version,
    required bool ageConfirmed,
  }) async {
    if (_client.auth.currentUser == null || !ageConfirmed) return false;
    final result = await _client.rpc(
      'accept_ai_consent',
      params: {'p_version': version, 'p_age_confirmed': ageConfirmed},
    );
    return result == true;
  }
}

final aiConsentRepositoryProvider = Provider<AiConsentRepository>(
  (ref) => SupabaseAiConsentRepository(Supabase.instance.client),
);
