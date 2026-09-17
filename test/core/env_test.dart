import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('기본 실행 환경은 로컬 dev와 mock 엔진이다', () {
    expect(AppEnv.environment, AppEnvironment.dev);
    expect(AppEnv.engine, EngineMode.mock);
    expect(AppEnv.authentication, AppAuthenticationMode.local);
    expect(AppEnv.mockCase, 'success');
    expect(AppEnv.supabaseUrl, 'http://127.0.0.1:54321');
  });

  test('dev 환경은 공개 publishable 키를 제공한다', () {
    expect(AppEnv.supabasePublishableKey, startsWith('sb_publishable_'));
    expect(AppEnv.supabasePublishableKey, isNot(contains('secret')));
  });

  test('Supabase 클라이언트가 로컬 REST 엔드포인트에 연결된다', () {
    final client = SupabaseClient(
      AppEnv.supabaseUrl,
      AppEnv.supabasePublishableKey,
    );
    addTearDown(client.dispose);

    expect(client.rest.url, '${AppEnv.supabaseUrl}/rest/v1');
    expect(client.auth.headers['apikey'], AppEnv.supabasePublishableKey);
  });
}
