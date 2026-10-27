// V2 settings: the same settings V1 offers, drawn with V2 rows and pages, on
// the shared providers. Invented fixtures only: memory repository, memory
// stores, a fake consent notice and fake record actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/privacy/app_lock.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/auth/ai_consent.dart';
import 'package:mumumong/ui/settings/record_actions.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/components/inputs.dart';
import 'package:mumumong/v2/design/theme.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/library.dart';
import 'package:mumumong/v2/screens/settings.dart';
import 'package:mumumong/v2/screens/v2_providers.dart';

import 'support.dart';

class _Book extends MemoryRepository {
  bool fail = false;
  int saves = 0;
  int retries = 0;
  bool? keptLocal;

  @override
  Future<void> saveGenerationSettings(
    String volumeId,
    GenerationSettings settings,
  ) async {
    saves++;
    if (fail) throw StateError('synthetic_save_failure');
    await super.saveGenerationSettings(volumeId, settings);
  }

  @override
  Future<void> retryGenerationSettings(String volumeId) async => retries++;

  @override
  Future<void> resolveGenerationSettingsConflict(
    String volumeId, {
    required bool keepLocal,
  }) async => keptLocal = keepLocal;
}

class _Records implements RecordActions {
  int exports = 0;
  int deletes = 0;
  bool fail = false;

  @override
  Future<void> shareExport({Rect? origin}) async {
    exports++;
    if (fail) throw StateError('synthetic_export_failure');
  }

  @override
  Future<void> deleteEverything() async {
    deletes++;
    if (fail) throw StateError('synthetic_delete_failure');
  }
}

class _Consent implements AiConsentRepository {
  int failLoads = 0;

  @override
  Future<AiConsentPolicy> loadPolicy() async {
    if (failLoads > 0) {
      failLoads--;
      throw StateError('synthetic_policy_unavailable');
    }
    return AiConsentPolicy(
      version: 3,
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
  Future<AiConsentRecord> loadCurrentUserRecord() async =>
      throw UnimplementedError();

  @override
  Future<bool> accept({required int version, required bool ageConfirmed}) =>
      throw UnimplementedError();
}

class _Authenticator implements DeviceAuthenticator {
  bool result = true;

  @override
  Future<bool> authenticate() async => result;
}

class _Harness {
  _Harness() : book = _Book();

  final _Book book;
  final records = _Records();
  final consent = _Consent();
  final authenticator = _Authenticator();
  final preferences = MemoryUiPreferenceStore();
  late final lock = AppLockController(MemorySecureValueStore(), authenticator);

  List<Override> overrides({
    bool preview = false,
    GenerationSettingsState? generation,
  }) => [
    repositoryProvider.overrideWithValue(book),
    uiPreferenceStoreProvider.overrideWithValue(preferences),
    appLockProvider.overrideWith((ref) => lock),
    aiConsentRepositoryProvider.overrideWithValue(consent),
    recordActionsProvider.overrideWithValue(records),
    if (preview) v2PreviewProvider.overrideWithValue(true),
    if (generation != null)
      generationSettingsProvider.overrideWith(
        (ref, id) => Stream.value(generation),
      ),
    completedBooksProvider.overrideWith((ref) => Stream.value(const [])),
    bookStoreProvider.overrideWith(
      (ref) => throw StateError('no_book_store_in_tests'),
    ),
  ];
}

Future<_Harness> _mount(
  WidgetTester tester, {
  Widget home = const V2SettingsScreen(),
  bool preview = false,
  GenerationSettingsState? generation,
  double scale = 1,
}) async {
  setV2View(tester, scale: scale, reduceMotion: true);
  final harness = _Harness();
  addTearDown(harness.book.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: harness.overrides(preview: preview, generation: generation),
      child: MumumongV2App(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('설정으로 돌아가기').last);
  await tester.pumpAndSettle();
}

Future<T> _read<T>(WidgetTester tester, Stream<T> stream) async =>
    (await tester.runAsync(() => stream.first)) as T;

const _initial = GenerationSettings(
  adaptation: AdaptationLevel.balanced,
  style: WritingStyle.plain,
  narrativeVoice: NarrativeVoice.firstPersonPast,
);
const _pending = GenerationSettings(
  adaptation: AdaptationLevel.faithful,
  style: WritingStyle.lyrical,
  narrativeVoice: NarrativeVoice.firstPersonPast,
);

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('every V1 setting has a V2 row and each page opens and closes', (
    tester,
  ) async {
    await _mount(tester);
    for (final (row, page) in [
      ('읽기와 종이', V2ReadingSettingsPage),
      ('이후 장면 설정', V2GenerationSettingsPage),
      ('기록 관리', V2RecordsPage),
      ('앱 잠금', V2AppLockPage),
      ('AI 처리 고지', V2AiNoticePage),
      ('음성 기록', V2VoicePage),
    ]) {
      await _tap(tester, v2Text(row));
      expect(find.byType(page), findsOneWidget, reason: row);
      await _back(tester);
      expect(find.byType(page), findsNothing, reason: row);
    }
    expect(v2Text('내가 완성한 책'), findsOneWidget);
  });

  testWidgets('reading settings save the shared device preferences', (
    tester,
  ) async {
    final harness = await _mount(tester, home: const V2ReadingSettingsPage());
    await _tap(tester, find.text('밤의 종이'));
    await _tap(tester, find.text('크게'));
    await _tap(tester, find.text('여백에 표시'));
    final saved = await harness.preferences.read();
    expect(saved, contains('"theme":"dark"'));
    expect(saved, contains('1.15'));
    expect(saved, contains('"show_origins":true'));
  });

  testWidgets('app lock changes only after device authentication', (
    tester,
  ) async {
    final harness = await _mount(tester, home: const V2AppLockPage());
    harness.authenticator.result = false;
    await _tap(tester, find.bySemanticsLabel(RegExp('^앱 잠금 사용')));
    expect(harness.lock.enabled, isFalse);
    expect(v2Text('기기 인증을 완료해야 설정을 바꿀 수 있어요.'), findsOneWidget);

    harness.authenticator.result = true;
    await _tap(tester, find.bySemanticsLabel(RegExp('^앱 잠금 사용')));
    expect(harness.lock.enabled, isTrue);
  });

  testWidgets('the AI notice shows the server policy and retries', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final harness = _Harness()..consent.failLoads = 1;
    addTearDown(harness.book.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MumumongV2App(home: V2AiNoticePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(v2Text('현재 고지를 불러오지 못했어요.'), findsOneWidget);
    await _tap(tester, v2Text('다시 시도'));
    expect(v2Text('꿈 내용은 원고 생성을 위해 AI 모델 제공사로 전송됩니다.'), findsOneWidget);
    expect(find.text('Groq'), findsOneWidget);
    expect(v2Text('고지 버전 3'), findsOneWidget);
  });

  testWidgets('generation settings: a failed save keeps the choice, a retry '
      'saves preferences only', (tester) async {
    final harness = await _mount(
      tester,
      home: const V2GenerationSettingsPage(),
    );
    final book = harness.book..fail = true;
    final volume = (await _read(tester, book.watchActiveVolume()))!;
    final scenesBefore = (await _read(
      tester,
      book.watchScenes(volume.id),
    )).map((s) => s.toJson()).toList();

    await _tap(tester, find.text('서정적으로'));
    await _tap(tester, v2Text('설정 저장'));
    expect(v2TextContaining('선택은 유지했어요'), findsOneWidget);
    expect(
      tester
          .widget<V2ChoiceChip>(find.widgetWithText(V2ChoiceChip, '서정적으로'))
          .selected,
      isTrue,
    );

    book.fail = false;
    await tester.runAsync(() async {
      await tester.tap(v2Text('설정 저장'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    final after = (await _read(tester, book.watchActiveVolume()))!;
    expect(after.style, WritingStyle.lyrical);
    expect(after.settingsVersion, 2);
    expect(
      (await _read(tester, book.watchScenes(volume.id))).map((s) => s.toJson()),
      scenesBefore,
    );
    expect(book.saves, 2);
  });

  testWidgets('generation settings: pending choices stay fixed and retry', (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      home: const V2GenerationSettingsPage(),
      generation: const GenerationSettingsState(
        confirmed: _initial,
        version: 1,
        pending: _pending,
        status: SettingsSyncStatus.pending,
      ),
    );
    await tester.ensureVisible(find.text('영화적으로'));
    await tester.tap(find.text('영화적으로'), warnIfMissed: false);
    await tester.pump();
    expect(
      tester
          .widget<V2ChoiceChip>(find.widgetWithText(V2ChoiceChip, '서정적으로'))
          .selected,
      isTrue,
    );
    await _tap(tester, v2Text('동기화 다시 시도'));
    expect(harness.book.retries, 1);
    expect(harness.book.saves, 0);
    expect(v2TextContaining('새 생성을 시작하지 않아요'), findsOneWidget);
  });

  for (final keep in [false, true]) {
    testWidgets('generation settings: conflict resolves keepLocal=$keep', (
      tester,
    ) async {
      final harness = await _mount(
        tester,
        home: const V2GenerationSettingsPage(),
        generation: const GenerationSettingsState(
          confirmed: _initial,
          version: 2,
          pending: _pending,
          status: SettingsSyncStatus.conflict,
        ),
      );
      expect(v2TextContaining('어느 설정을 사용할지'), findsOneWidget);
      expect(find.textContaining('이 기기의 선택:'), findsOneWidget);
      expect(find.textContaining('서버의 설정:'), findsOneWidget);
      await _tap(tester, v2Text(keep ? '이 기기의 선택 적용' : '서버 설정 사용'));
      expect(harness.book.keptLocal, keep);
      expect(harness.book.saves, 0);
    });
  }

  testWidgets('export asks first and uses the shared record action', (
    tester,
  ) async {
    final harness = await _mount(tester, home: const V2RecordsPage());
    await _tap(tester, v2Text('내 기록 내보내기'));
    await _tap(tester, v2Text('취소'));
    expect(harness.records.exports, 0);

    await _tap(tester, v2Text('내 기록 내보내기'));
    await _tap(tester, v2Text('내보내기'));
    expect(harness.records.exports, 1);

    harness.records.fail = true;
    await _tap(tester, v2Text('내 기록 내보내기'));
    await _tap(tester, v2Text('내보내기'));
    expect(v2Text('내보내지 못했어요. 기록은 그대로 보관되어 있어요.'), findsOneWidget);
  });

  testWidgets('delete needs the typed word, then leaves settings', (
    tester,
  ) async {
    final harness = await _mount(
      tester,
      home: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                Navigator.of(context).push(v2Route(const V2RecordsPage())),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await _tap(tester, find.text('열기'));
    await _tap(tester, v2Text('모든 기록 삭제'));
    await _tap(tester, v2Text('영구 삭제'));
    expect(harness.records.deletes, 0, reason: 'disabled until typed');

    await tester.enterText(
      find.byKey(const Key('v2-delete-confirmation')),
      '삭제',
    );
    await tester.pump();
    await _tap(tester, v2Text('영구 삭제'));
    expect(harness.records.deletes, 1);
    expect(find.byType(V2RecordsPage), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });

  testWidgets('a failed delete stays and says what to check', (tester) async {
    final harness = await _mount(tester, home: const V2RecordsPage());
    harness.records.fail = true;
    await _tap(tester, v2Text('모든 기록 삭제'));
    await tester.enterText(
      find.byKey(const Key('v2-delete-confirmation')),
      ' 삭제 ',
    );
    await tester.pump();
    await _tap(tester, v2Text('영구 삭제'));
    expect(harness.records.deletes, 1);
    expect(find.byType(V2RecordsPage), findsOneWidget);
    expect(v2TextContaining('삭제 상태를 확인하지 못했어요'), findsOneWidget);
  });

  testWidgets('the preview never exports or deletes', (tester) async {
    final harness = await _mount(
      tester,
      home: const V2RecordsPage(),
      preview: true,
    );
    expect(v2Text('미리보기에서는 실제 기록을 내보내거나 지우지 않아요.'), findsOneWidget);
    await _tap(tester, v2Text('내 기록 내보내기'));
    await _tap(tester, v2Text('모든 기록 삭제'));
    expect(harness.records.exports + harness.records.deletes, 0);
    expect(find.byType(V2TextField), findsNothing);
  });

  testWidgets('completed books open the V2 shelf and back returns', (
    tester,
  ) async {
    await _mount(tester);
    await _tap(tester, v2Text('내가 완성한 책'));
    expect(find.byType(V2LibraryScreen), findsOneWidget);
    expect(v2TextContaining('아직 완성한 책이 없어요'), findsOneWidget);
    expect(v2Text('원고 완성 준비'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('설정으로 돌아가기').last);
    await tester.pumpAndSettle();
    expect(find.byType(V2LibraryScreen), findsNothing);
    expect(find.byType(V2SettingsScreen), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('settings pages meet the guidelines at text scale $scale', (
      tester,
    ) async {
      await _mount(tester, scale: scale);
      await expectGuidelines(tester, 'settings x$scale');
      for (final row in [
        '읽기와 종이',
        '이후 장면 설정',
        '기록 관리',
        '앱 잠금',
        'AI 처리 고지',
        '음성 기록',
      ]) {
        await _tap(tester, v2Text(row));
        await expectGuidelines(tester, '$row x$scale');
        await _back(tester);
      }
    });
  }
}
