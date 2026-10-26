// Invented fixtures only. This checks local UX, not hosted literary quality.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/speech/speech_input.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';
import '../support/ui_preference_store.dart';

const _dream = '가상 테스트: 작은 종이배가 유리 숲 위로 날아갔다. 나는 길가에서 바라봤다.';
const _goldens = '../../docs/ux-review/2026-10-23-spacing';

void main() {
  Future<T> snapshot<T extends Object>(
    WidgetTester tester,
    Stream<T> stream,
  ) async => (await tester.runAsync(() => stream.first))!;

  setUpAll(() async {
    for (final (family, path) in [
      ('Pretendard', 'assets/fonts/Pretendard-Regular.otf'),
      ('MaruBuri', 'assets/fonts/MaruBuri-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });

  Future<(MemoryRepository, _ObservedEngine)> mount(
    WidgetTester tester, {
    bool seeded = false,
    bool night = false,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository(seedPrototype: seeded);
    if (!seeded) {
      await repo.createPreviewVolume(
        adaptation: AdaptationLevel.balanced,
        style: WritingStyle.plain,
        narrativeVoice: NarrativeVoice.firstPersonPast,
      );
    }
    final engine = _ObservedEngine(repo);
    addTearDown(() {
      engine.delegate.dispose();
      repo.dispose();
    });
    final preferences = MemoryUiStore()
      ..value = night ? '{"theme":"dark","reader_scale":1}' : null;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          engineClientProvider.overrideWithValue(engine),
          speechInputProvider.overrideWithValue(_SilentSpeech()),
          uiPreferenceStoreProvider.overrideWithValue(preferences),
          outboxWorkerProvider.overrideWithValue(null),
          networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: const RepaintBoundary(
            key: Key('first-dream-screen'),
            child: MumumongApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, engine);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('꿈 기록하기'));
    await tester.tap(find.text('꿈 기록하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _dream);
    await tester.tap(find.text('꿈 저장하기'));
    await tester.pumpAndSettle();
  }

  Future<void> generate(WidgetTester tester) async {
    await tester.ensureVisible(find.text('장면 만들기'));
    await tester.tap(find.text('장면 만들기'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.text('새 장면 읽기').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(find.text('새 장면 읽기'), findsOneWidget);
  }

  testWidgets('first saved dream can stay a record without generation', (
    tester,
  ) async {
    final (repo, engine) = await mount(tester);
    await save(tester);
    expect(find.textContaining('떠오른 만큼 남겼다면 충분해요.'), findsOneWidget);
    await tester.tap(find.text('나중에 만들기'));
    await tester.pumpAndSettle();
    expect(engine.enqueues, 0);
    final dreams = await snapshot(
      tester,
      repo.watchDreams(DreamStatusFilter.all),
    );
    expect(dreams.single.rawText, _dream);
    expect(dreams.single.status, DreamStatus.queued);
    expect(
      await snapshot(tester, repo.watchScenes(MemorySeedIds.volume)),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'read first result, inspect its source, return and save next dream',
    (tester) async {
      final (repo, engine) = await mount(tester);
      await save(tester);
      await generate(tester);
      expect(find.text('내 꿈에서 시작한 첫 장면이에요.'), findsOneWidget);
      expect(find.text('+15%'), findsNothing);
      expect(find.textContaining('꿈 원문은 보관함에 따로'), findsOneWidget);
      final firstScene = (await snapshot(
        tester,
        repo.watchScenes(MemorySeedIds.volume),
      )).single;
      final before = await snapshot(tester, repo.watchPassages(firstScene.id));
      await tester.ensureVisible(find.text('새 장면 읽기'));
      await tester.tap(find.text('새 장면 읽기'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      await tester.ensureVisible(find.text('꿈 원문 다시 보기'));
      await tester.runAsync(() async {
        await tester.tap(find.text('꿈 원문 다시 보기'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(find.text('원문'), findsOneWidget);
      // The existing provenance sheet reads the saved source, never infers emotion.
      expect(find.byType(SelectableText), findsOneWidget);
      final text = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(text.textSpan!.toPlainText(), _dream);
      Navigator.of(tester.element(find.text('원문'))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('읽기 마치기'));
      await tester.tap(find.text('읽기 마치기'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsNothing);
      expect(engine.enqueues, 1);
      expect(
        (await snapshot(tester, repo.watchScenes(MemorySeedIds.volume))).length,
        1,
      );
      final after = await snapshot(tester, repo.watchPassages(firstScene.id));
      expect(
        after.map((p) => (p.id, p.text, p.origin, p.locked)),
        before.map((p) => (p.id, p.text, p.origin, p.locked)),
      );
      await save(tester);
      expect(engine.enqueues, 1);
      expect(
        (await snapshot(
          tester,
          repo.watchDreams(DreamStatusFilter.all),
        )).length,
        2,
      );
      await generate(tester);
      expect(find.text('내 꿈에서 시작한 첫 장면이에요.'), findsNothing);
      expect(find.text('꿈이 한 장면이 되었어요.'), findsOneWidget);
      expect(engine.enqueues, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'existing multi-scene reader does not show a first-result afterword',
    (tester) async {
      await mount(tester, seeded: true);
      await tester.tap(find.text('새 장면 읽기'));
      await tester.pumpAndSettle();
      expect(find.byType(ReaderScreen), findsOneWidget);
      expect(find.byKey(const Key('first-scene-afterword')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final night in [false, true]) {
    for (final (size, scale) in [
      (const Size(375, 667), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(430, 932), 1.0),
      (const Size(1200, 800), 1.0),
      (const Size(375, 667), 1.6),
    ]) {
      final tag =
          '${night ? 'night' : 'day'}-${size.width.toInt()}-${size.height.toInt()}-${scale == 1 ? 'normal' : 'large'}';
      testWidgets('first result and reading end stay accessible $tag', (
        tester,
      ) async {
        await mount(tester, night: night, size: size, scale: scale);
        await save(tester);
        await generate(tester);
        await expectLater(
          find.byKey(const Key('first-dream-screen')),
          matchesGoldenFile('$_goldens/$tag-first-result.png'),
        );
        await tester.ensureVisible(find.text('새 장면 읽기'));
        await tester.tap(find.text('새 장면 읽기'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('읽기 마치기'));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text('읽기 마치기')).bottom,
          lessThanOrEqualTo(size.height),
        );
        await expectLater(
          find.byKey(const Key('first-dream-screen')),
          matchesGoldenFile('$_goldens/$tag-reading-end.png'),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('읽기 마치기'));
        await tester.pumpAndSettle();
        expect(find.text('꿈 기록하기'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

class _ObservedEngine implements EngineClient {
  _ObservedEngine(MemoryRepository repo)
    : delegate = MockEngineClient(
        store: repo,
        stageDelay: const Duration(seconds: 1),
      );
  final MockEngineClient delegate;
  int enqueues = 0;
  @override
  Future<String> enqueue(String id, String key) {
    enqueues++;
    return delegate.enqueue(id, key);
  }

  @override
  Future<String> retry(String id) => delegate.retry(id);
  @override
  Stream<JobProgress> watch(String id) => delegate.watch(id);
}

class _SilentSpeech implements SpeechInput {
  @override
  Stream<SpeechUpdate> get updates => const Stream.empty();
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
}
