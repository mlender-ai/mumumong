// Hosted V2 account path against the staging Supabase project with one
// disposable anonymous account: the trial start, the hosted AI notice and
// consent, a first scene from the local mock engine (no AI call), and
// delete-everything removing the account on the server. Runs only with
// --dart-define=HOSTED_QA=true plus ENV=staging ENGINE=mock AUTH=apple UI=v2
// and the project's SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY. Invented text
// only; no token or key is printed.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mumumong/core/env/env.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/screens/gates.dart';
import 'package:mumumong/v2/screens/volume_setup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'harness.dart';

const _hosted = bool.fromEnvironment('HOSTED_QA');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'V2 hosted trial account: notice, consent, mock scene and server deletion',
    skip: !_hosted,
    (tester) async {
      expect(AppEnv.environment, AppEnvironment.staging);
      expect(AppEnv.engine, EngineMode.mock, reason: 'never a real AI call');
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabasePublishableKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
        ),
      );
      final client = Supabase.instance.client;
      final dir = await Directory.systemTemp.createTemp('mumumong-v2-hosted-');
      final db = AppDatabase.forTesting(
        NativeDatabase(File('${dir.path}/synthetic.sqlite')),
      );
      String? token;
      var deleted = false;
      try {
        await mountV2Native(
          tester,
          const AuthGate(
            presentation: V2AuthPresentation(),
            manuscript: V2Shell(),
          ),
          overrides: [
            databaseProvider.overrideWithValue(db),
            repositoryProvider.overrideWithValue(DriftRepository(db)),
            outboxWorkerProvider.overrideWithValue(null),
          ],
        );
        await waitFor(tester, v2Text('Apple로 시작하기'));
        await tapNative(tester, v2Text('Apple로 시작하기'));
        // The hosted notice arrives over the network.
        await waitFor(tester, find.byKey(const Key('v2-age-confirmation')));
        expect(v2TextContaining('Groq'), findsWidgets);
        await tapNative(tester, find.byKey(const Key('v2-age-confirmation')));
        await tapNative(tester, find.byKey(const Key('v2-ai-consent')));
        await tapNative(tester, v2Text('체험 계정으로 시작'));
        await waitFor(tester, find.byType(V2VolumeSetupScreen), attempts: 300);
        token = client.auth.currentSession?.accessToken;
        expect(token, isNotNull);
        expect(client.auth.currentUser?.isAnonymous, isTrue);

        await tapNative(tester, v2Text('시작하기'));
        await waitFor(tester, find.text('꿈 기록'), attempts: 300);
        await tapNative(tester, find.text('꿈 기록'));
        await waitFor(tester, find.byType(TextField));
        await tester.enterText(
          find.byType(TextField),
          '가상 호스팅 검증: 종이 등대가 안개 낀 정류장에서 깜박였다.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tapNative(tester, v2Text('꿈 저장하기'));
        await waitFor(tester, v2Text('장면 만들기'));
        await tapNative(tester, v2Text('장면 만들기'));
        await waitFor(tester, v2Text('새 장면 읽기'), attempts: 300);
        expect(v2Text('문 밖의 여자'), findsOneWidget, reason: 'mock scene');
        await tapNative(tester, find.bySemanticsLabel('닫기').first);

        await waitFor(tester, find.bySemanticsLabel('설정'));
        await tapNative(tester, find.bySemanticsLabel('설정'));
        await tapNative(tester, v2Text('기록 관리'));
        await tapNative(tester, v2Text('모든 기록 삭제'));
        await tester.enterText(
          find.byKey(const Key('v2-delete-confirmation')),
          '삭제',
        );
        await tester.pump();
        await tapNative(tester, v2Text('영구 삭제'));
        await waitFor(tester, v2Text('모든 기록을 삭제했어요.'), attempts: 300);

        expect(client.auth.currentSession, isNull);
        expect(await db.select(db.volumes).get(), isEmpty);
        expect(await db.select(db.dreams).get(), isEmpty);
        // The server no longer knows the account behind the old token.
        await expectLater(
          client.auth.getUser(token),
          throwsA(isA<AuthException>()),
        );
        deleted = true;
      } finally {
        await unmount(tester);
        if (token != null && !deleted) {
          // Never leave a disposable account behind, even after a failure.
          await client.functions.invoke(
            'delete-account',
            headers: {'Authorization': 'Bearer $token'},
          );
        }
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
