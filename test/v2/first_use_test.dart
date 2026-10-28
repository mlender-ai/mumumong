// Migrated from test/ui/first_dream_experience_test.dart (4),
// test/ui/p3_flow_test.dart (6), the archive test of
// test/ui/repository_wiring_test.dart (1) and three screen tests of
// test/ui/mobile_delivery_test.dart (V1). First use on V2: the first dream
// may stay a record, the first result and its source, explicit generation
// only, first-volume settings, reader appearance, passage edits, policy
// links, archive months and filters, and screens that stay still.
// Invented fixtures only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mumumong/core/design/ui_preferences.dart';
import 'package:mumumong/data/engine/engine_client.dart';
import 'package:mumumong/data/engine/mock_engine_client.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/data/sync/cloud_sync_service.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/shared/policy_link.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/components/buttons.dart';
import 'package:mumumong/v2/components/inputs.dart';
import 'package:mumumong/v2/components/policy_link.dart';
import 'package:mumumong/v2/design/dot_matrix.dart';
import 'package:mumumong/v2/design/theme.dart';
import 'package:mumumong/v2/design/tokens.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/archive.dart';
import 'package:mumumong/v2/screens/capture.dart';
import 'package:mumumong/v2/screens/home.dart';
import 'package:mumumong/v2/screens/reader.dart';
import 'package:mumumong/v2/screens/settings.dart';
import 'package:mumumong/v2/screens/volume_setup.dart';

import 'processing_test.dart' show ControlledEngine;
import 'support.dart';

const _dream = '가상 테스트: 작은 종이배가 유리 숲 위로 날아갔다. 나는 길가에서 바라봤다.';

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

class _VolumeService extends Mock implements CloudSyncService {
  final calls = <(AdaptationLevel, WritingStyle, NarrativeVoice)>[];
  bool fail = false;

  @override
  Future<void> createVolume({
    required AdaptationLevel adaptation,
    required WritingStyle style,
    NarrativeVoice narrativeVoice = NarrativeVoice.firstPersonPast,
  }) async {
    calls.add((adaptation, style, narrativeVoice));
    if (fail) throw StateError('test_network_failure');
  }
}

class _DelayedEditBook extends MemoryRepository {
  final release = Completer<void>();
  int edits = 0;

  @override
  Future<void> editPassage(String passageId, String text) async {
    edits++;
    if (edits == 1) {
      await release.future;
      throw StateError('test_write_failure');
    }
    await super.editPassage(passageId, text);
  }
}

Future<T> _read<T>(WidgetTester tester, Stream<T> stream) async =>
    (await tester.runAsync(() => stream.first)) as T;

List<Override> _base(MumumongRepository repo, {UiPreferenceStore? prefs}) => [
  repositoryProvider.overrideWithValue(repo),
  speechInputProvider.overrideWithValue(SilentSpeech()),
  networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
  uiPreferenceStoreProvider.overrideWithValue(
    prefs ?? MemoryUiPreferenceStore(),
  ),
  outboxWorkerProvider.overrideWithValue(null),
];

Future<void> _pump(
  WidgetTester tester,
  List<Override> overrides,
  Widget home,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MumumongV2App(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapAsync(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder.first);
    // Sheets close, then the next one opens after real repository reads.
    await tester.pump(const Duration(milliseconds: 400));
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  await tester.pumpAndSettle();
}

final _firstPassage = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_Passage',
);

void main() {
  setUpAll(loadV2Fonts);

  // ---- first_dream_experience_test.dart

  Future<(MemoryRepository, _ObservedEngine)> mountShell(
    WidgetTester tester, {
    bool seeded = false,
    bool night = false,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    setV2View(tester, size: size, scale: scale, reduceMotion: true);
    final repo = MemoryRepository(seedPrototype: seeded);
    if (!seeded) {
      await tester.runAsync(
        () => repo.createPreviewVolume(
          adaptation: AdaptationLevel.balanced,
          style: WritingStyle.plain,
          narrativeVoice: NarrativeVoice.firstPersonPast,
        ),
      );
    }
    final engine = _ObservedEngine(repo);
    addTearDown(() {
      engine.delegate.dispose();
      repo.dispose();
    });
    final prefs = MemoryUiPreferenceStore()
      ..value = night
          ? '{"theme":"dark","reader_scale":1.0,"show_origins":false}'
          : null;
    await _pump(tester, [
      ..._base(repo, prefs: prefs),
      engineClientProvider.overrideWithValue(engine),
    ], const V2Shell());
    return (repo, engine);
  }

  Future<void> save(WidgetTester tester) async {
    await _tap(tester, find.text('꿈 기록'));
    await tester.enterText(
      find.byKey(const ValueKey('v2-dream-editor')),
      _dream,
    );
    await tester.pump();
    await _tap(tester, v2Text('꿈 저장하기'));
  }

  Future<void> generate(WidgetTester tester) async {
    await tester.ensureVisible(v2Text('장면 만들기'));
    await tester.tap(v2Text('장면 만들기'));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (v2Text('새 장면 읽기').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
    expect(v2Text('새 장면 읽기'), findsOneWidget);
  }

  final percentDelta = find.byWidgetPredicate(
    (w) => w is V2DotMatrix && w.text.endsWith('%'),
  );

  testWidgets('first saved dream can stay a record without generation', (
    tester,
  ) async {
    final (repo, engine) = await mountShell(tester);
    await save(tester);
    expect(v2TextContaining('떠오른 만큼 남겼다면 충분해요.'), findsOneWidget);
    await _tap(tester, v2Text('나중에 만들기'));
    expect(engine.enqueues, 0);
    final dreams = await _read(tester, repo.watchDreams(DreamStatusFilter.all));
    expect(dreams.single.rawText, _dream);
    expect(dreams.single.status, DreamStatus.queued);
    expect(
      await _read(tester, repo.watchScenes(MemorySeedIds.volume)),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'read first result, inspect its source, return and save next dream',
    (tester) async {
      final (repo, engine) = await mountShell(tester);
      await save(tester);
      await generate(tester);
      expect(v2Text('내 꿈에서 시작한 첫 장면이에요'), findsOneWidget);
      expect(percentDelta, findsNothing);
      expect(v2TextContaining('꿈 원문은 보관함에 따로'), findsOneWidget);
      final firstScene = (await _read(
        tester,
        repo.watchScenes(MemorySeedIds.volume),
      )).single;
      final before = await _read(tester, repo.watchPassages(firstScene.id));

      await _tap(tester, v2Text('새 장면 읽기'));
      expect(find.byType(V2ReaderScreen), findsOneWidget);
      await _tapAsync(tester, v2Text('꿈 원문 다시 보기'));
      expect(v2Text('원문'), findsOneWidget);
      final source = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(source.textSpan!.toPlainText(), _dream);
      Navigator.of(tester.element(v2Text('원문'))).pop();
      await tester.pumpAndSettle();

      await _tap(tester, v2Text('읽기 마치기'));
      expect(find.byType(V2ReaderScreen), findsNothing);
      expect(engine.enqueues, 1);
      expect(
        (await _read(tester, repo.watchScenes(MemorySeedIds.volume))).length,
        1,
      );
      final after = await _read(tester, repo.watchPassages(firstScene.id));
      expect(
        after.map((p) => (p.id, p.text, p.origin, p.locked)),
        before.map((p) => (p.id, p.text, p.origin, p.locked)),
      );

      await save(tester);
      expect(engine.enqueues, 1);
      expect(
        (await _read(tester, repo.watchDreams(DreamStatusFilter.all))).length,
        2,
      );
      await generate(tester);
      expect(v2Text('내 꿈에서 시작한 첫 장면이에요'), findsNothing);
      expect(v2Text('꿈이 한 장면이 되었어요'), findsOneWidget);
      expect(engine.enqueues, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'existing multi-scene reader does not show a first-result afterword',
    (tester) async {
      await mountShell(tester, seeded: true);
      await _tap(tester, v2Text('새 장면 읽기'));
      expect(find.byType(V2ReaderScreen), findsOneWidget);
      expect(find.byKey(const Key('v2-first-scene-afterword')), findsNothing);
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
          '${night ? 'night' : 'day'}-${size.width.toInt()}x${size.height.toInt()}-x$scale';
      testWidgets('first result and reading end stay accessible $tag', (
        tester,
      ) async {
        await mountShell(tester, night: night, size: size, scale: scale);
        await save(tester);
        await generate(tester);
        await expectGuidelines(tester, 'first result $tag');
        await _tap(tester, v2Text('새 장면 읽기'));
        await tester.ensureVisible(v2Text('읽기 마치기'));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(v2Text('읽기 마치기')).bottom,
          lessThanOrEqualTo(size.height),
        );
        // At the end of the scene a passage scrolls under the glass header,
        // so the contrast check would read occluded text. Unscrolled reader
        // contrast is covered by quality_test; here: targets and labels.
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(tester.takeException(), isNull);
        await _tap(tester, v2Text('읽기 마치기'));
        expect(find.text('꿈 기록'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  // ---- p3_flow_test.dart

  testWidgets(
    'Reader refreshes its appearance after returning from persisted settings',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      final book = MemoryRepository();
      addTearDown(book.dispose);
      await _pump(tester, _base(book), const V2ReaderScreen());
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        V2Color.paper,
      );
      await _tap(tester, find.bySemanticsLabel('읽기 설정'));
      await _tap(tester, find.text('밤의 종이'));
      await tester.tapAt(const Offset(200, 120));
      await tester.pumpAndSettle();
      expect(find.text('밤의 종이'), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        V2Color.nightPaper,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'first volume starts with real defaults; optional custom settings survive retry',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      final service = _VolumeService();
      var completed = 0;
      Future<void> mount() => _pump(tester, [
        cloudSyncServiceProvider.overrideWithValue(service),
        uiPreferenceStoreProvider.overrideWithValue(MemoryUiPreferenceStore()),
      ], V2VolumeSetupScreen(onComplete: () => completed++));

      await mount();
      await tester.tap(v2Text('시작하기'));
      await tester.pump();
      expect(service.calls.single, (
        AdaptationLevel.balanced,
        WritingStyle.plain,
        NarrativeVoice.firstPersonPast,
      ));
      expect(completed, 1);

      service
        ..calls.clear()
        ..fail = true;
      await mount();
      await _tap(tester, v2Text('이야기 설정'));
      await _tap(tester, v2Text('꿈에 충실하게'));
      await _tap(tester, v2Text('영화적으로'));
      await _tap(tester, v2Text('소설 속 인물 시점'));
      await _tap(tester, v2Text('시작하기'));
      expect(completed, 1);
      expect(v2TextContaining('원고를 만들지 못했어요.'), findsOneWidget);

      service.fail = false;
      await tester.ensureVisible(v2Text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(v2Text('시작하기'));
      await tester.pump();
      expect(service.calls.last, (
        AdaptationLevel.faithful,
        WritingStyle.cinematic,
        NarrativeVoice.thirdPersonPast,
      ));
      expect(completed, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'the passage sheet preserves input on a failed edit and reverts provenance',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      final book = _DelayedEditBook();
      addTearDown(book.dispose);
      await _pump(tester, _base(book), const V2ReaderScreen());
      await _tapAsync(tester, _firstPassage);
      await _tapAsync(tester, v2Text('내 문장으로 고치기'));
      await tester.enterText(find.byType(TextField), '내가 선택한 새 문장이다.');
      await tester.tap(v2Text('저장').last);
      await tester.pump();
      final saving = tester.widget<V2Button>(
        find.ancestor(of: v2Text('저장 중'), matching: find.byType(V2Button)),
      );
      expect(saving.onPressed, isNull);
      expect(book.edits, 1);

      book.release.complete();
      await tester.pumpAndSettle();
      expect(v2Text('저장하지 못했어요. 입력한 문장은 그대로 남아 있어요.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '내가 선택한 새 문장이다.',
      );
      await tester.tap(v2Text('저장').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(book.edits, 2);
      expect(v2Text('내가 선택한 새 문장이다.'), findsOneWidget);

      await _tapAsync(tester, _firstPassage);
      await _tapAsync(tester, v2Text('원래 문장으로'));
      expect(v2Text('원래 문장으로 돌아갈까요?'), findsOneWidget);
      await _tapAsync(tester, v2Text('원래 문장으로').last);
      expect(v2Text('내가 선택한 새 문장이다.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'save, optional recall, leave and archive resume require explicit generation',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      final repository = MemoryRepository();
      final engine = ControlledEngine();
      addTearDown(repository.dispose);
      addTearDown(engine.controller.close);
      await _pump(
        tester,
        [..._base(repository), engineClientProvider.overrideWithValue(engine)],
        Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      v2Route(
                        const V2CaptureFlow(dreamNumber: 8, sceneNumber: 12),
                      ),
                    ),
                    child: const Text('기록 열기'),
                  ),
                  Expanded(child: V2ArchiveScreen(onCapture: () {})),
                ],
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('기록 열기'));
      await tester.enterText(
        find.byKey(const ValueKey('v2-dream-editor')),
        '얇은 유리 계단을 올라가니 종이 우산이 있었다.',
      );
      await tester.pump();
      await _tap(tester, v2Text('꿈 저장하기'));
      expect(v2Text('꿈이 저장됐어요'), findsOneWidget);
      expect(v2Text('밝았나요, 어두웠나요?'), findsNothing);
      expect(engine.keys, isEmpty);

      await _tap(tester, v2Text('기억 더 보강하기'));
      await _tap(tester, v2Text('밝음'));
      await _tap(tester, v2Text('보강 마치기'));
      expect(engine.keys, isEmpty);
      await _tap(tester, v2Text('나중에 만들기'));

      final dream = (await _read(
        tester,
        repository.watchDreams(DreamStatusFilter.all),
      )).firstWhere((d) => d.rawText.startsWith('얇은 유리'));
      await _tapAsync(tester, v2TextContaining('얇은 유리 계단을'));
      await _tap(tester, v2Text('장면 만들기'));
      expect(v2Text('꿈이 저장됐어요'), findsOneWidget);
      expect(engine.keys, isEmpty);

      await tester.ensureVisible(v2Text('장면 만들기'));
      await tester.tap(v2Text('장면 만들기'));
      await tester.pump(const Duration(seconds: 1));
      expect(engine.keys, [dream.id]);
      final generated = (await _read(
        tester,
        repository.watchDreams(DreamStatusFilter.all),
      )).firstWhere((d) => d.id == dream.id);
      expect(generated.recallAnswers['light'], '밝음');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a read new scene becomes the recent scene to continue', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    final volume = (await _read(tester, repository.watchActiveVolume()))!;
    final scenes = await _read(tester, repository.watchScenes(volume.id));
    for (final scene in scenes) {
      final passages = await _read(tester, repository.watchPassages(scene.id));
      if (scene != scenes.last && passages.isNotEmpty) {
        await tester.runAsync(
          () => repository.markPassageRead(passages.first.id),
        );
      }
    }
    await _pump(
      tester,
      _base(repository),
      Builder(
        builder: (context) => Scaffold(
          body: V2HomeScreen(
            onCapture: () {},
            onRead: () {},
            onReadScene: (id) => Navigator.of(context).push(
              v2Route(V2ReaderScreen(volumeId: volume.id, initialSceneId: id)),
            ),
          ),
        ),
      ),
    );
    expect(v2Text('새 장면 읽기'), findsOneWidget);
    await _tap(tester, v2Text('새 장면 읽기'));
    await tester.tap(find.byTooltip('닫기').first);
    await tester.pumpAndSettle();
    // V2: capture lives in the floating nav; the card turns to continuing.
    expect(v2Text('새 장면 읽기'), findsNothing);
    expect(v2Text('이어 읽기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'policy link opens actual URL, failure offers copy with feedback',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      final uri = Uri.parse('https://example.test/policy');
      final opened = <Uri>[];
      var fail = false;
      await _pump(
        tester,
        [
          policyLinkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return !fail;
          }),
        ],
        Scaffold(
          body: Center(
            child: V2PolicyLink(label: '이용 약관', uri: uri),
          ),
        ),
      );
      await tester.tap(v2Text('이용 약관 열기'));
      await tester.pump();
      expect(opened, [uri]);

      fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async => null,
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.tap(v2Text('이용 약관 열기'));
      await tester.pumpAndSettle();
      expect(v2TextContaining('링크를 열지 못했어요'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('이용 약관 주소 복사'));
      await tester.pumpAndSettle();
      expect(v2TextContaining('주소를 복사했어요'), findsOneWidget);
    },
  );

  // ---- repository_wiring_test.dart

  testWidgets('archive groups typed dreams by month and filters them', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);
    await _pump(
      tester,
      _base(repository),
      Scaffold(body: V2ArchiveScreen(onCapture: () {})),
    );
    expect(find.bySemanticsLabel('2026년 9월'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.bySemanticsLabel('2026년 8월'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.bySemanticsLabel('2026년 8월'), findsOneWidget);
    expect(v2TextContaining('작은 열쇠가 손바닥 위에 있었다.'), findsOneWidget);

    await tester.tap(find.text('기록만').first);
    await tester.pumpAndSettle();
    expect(v2TextContaining('작은 열쇠가 손바닥 위에 있었다.'), findsOneWidget);
    expect(v2TextContaining('비어 있는 학교 복도를 계속 걸었다.'), findsNothing);
  });

  // ---- mobile_delivery_test.dart (screen tests)

  testWidgets(
    'the sky drift stops in the background and resumes; input is kept',
    (tester) async {
      // V1 stopped its looping atmosphere clock in the background; V2's
      // drifting sky does the same.
      await mountV2(tester, reduceMotion: false);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.tap(find.text('꿈 기록'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final editor = find.byKey(const ValueKey('v2-dream-editor'));
      await tester.enterText(editor, '가상 기록: 배경에서도 남는 종이별');
      await tester.pump(const Duration(milliseconds: 600));
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '가상 기록: 배경에서도 남는 종이별',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('off-tab home does not animate or claim growth', (tester) async {
    setV2View(tester);
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    await _pump(
      tester,
      _base(repo),
      Scaffold(
        body: V2HomeScreen(
          isActive: false,
          onCapture: () {},
          onRead: () {},
          onReadScene: (_) {},
          onArchive: () {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('web microphone help does not impersonate native recording', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    await _pump(tester, const [], const V2VoicePage(web: true));
    expect(v2TextContaining('이 웹 체험판에서는 사용할 수 없고'), findsOneWidget);
    expect(v2TextContaining('음성을 서버로 보내지는 않아요'), findsOneWidget);
    expect(v2TextContaining('듣고 있어요'), findsNothing);
    expect(find.byType(V2RecordButton), findsNothing);
    expect(find.byType(V2CaptureField), findsNothing);
  });
}
