enum AppEnvironment { dev, staging, prod }

enum EngineMode { mock, remote }

abstract final class AppEnv {
  static const _environmentName = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static const _engineName = String.fromEnvironment(
    'ENGINE',
    defaultValue: 'mock',
  );
  static const _configuredSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _configuredSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const _localSupabaseUrl = 'http://127.0.0.1:54321';
  static const _localSupabasePublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  static AppEnvironment get environment => switch (_environmentName) {
    'dev' => AppEnvironment.dev,
    'staging' => AppEnvironment.staging,
    'prod' => AppEnvironment.prod,
    _ => throw StateError('Unsupported ENV: $_environmentName'),
  };

  static EngineMode get engine => switch (_engineName) {
    'mock' => EngineMode.mock,
    'remote' => EngineMode.remote,
    _ => throw StateError('Unsupported ENGINE: $_engineName'),
  };

  static String get supabaseUrl {
    if (_configuredSupabaseUrl.isNotEmpty) return _configuredSupabaseUrl;
    if (environment == AppEnvironment.dev) return _localSupabaseUrl;
    throw StateError('SUPABASE_URL is required for $_environmentName');
  }

  static String get supabasePublishableKey {
    if (_configuredSupabasePublishableKey.isNotEmpty) {
      return _configuredSupabasePublishableKey;
    }
    if (environment == AppEnvironment.dev) {
      return _localSupabasePublishableKey;
    }
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY is required for $_environmentName',
    );
  }
}
