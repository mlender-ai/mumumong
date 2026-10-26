import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/ui/archive/archive_screen.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/shared/policy_link.dart';
import 'package:mumumong/ui/home/home_screen.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';
import 'package:mumumong/ui/auth/auth_gate.dart';
import 'package:mumumong/data/sync/cloud_sync_service.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mocktail/mocktail.dart';
import 'processing_state_test.dart' show ControlledEngine;
import '../support/ui_preference_store.dart';

void main() {
  testWidgets(
    'Reader refreshes its appearance after returning from persisted settings',
    (tester) async {
      final book = MemoryRepository();
      addTearDown(book.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(book),
            uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
          ],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: mumumongTheme(),
              darkTheme: dreamNightTheme(),
              themeMode: ref.watch(uiPreferencesProvider).themeMode,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: const ReaderScreen(initialNight: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('화면과 글자 크기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('어둡게'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('설정으로 돌아가기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
        MongColor.nightPaper,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'first volume starts with real defaults; optional custom settings survive retry',
    (tester) async {
      final service = _VolumeService();
      var completed = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cloudSyncServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: VolumeSetupScreen(onComplete: () => completed++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pump();
      expect(service.calls.single, (
        AdaptationLevel.balanced,
        WritingStyle.plain,
        NarrativeVoice.firstPersonPast,
      ));
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
      service.calls.clear();
      service.fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cloudSyncServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: VolumeSetupScreen(onComplete: () => completed++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('이야기 설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('꿈에 충실하게'));
      await tester.ensureVisible(find.text('영화적으로'));
      await tester.tap(find.text('영화적으로'));
      await tester.ensureVisible(find.text('소설 속 인물 시점'));
      await tester.tap(find.text('소설 속 인물 시점'));
      await tester.pump();
      await tester.ensureVisible(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(find.textContaining('원고를 만들지 못했어요.'), findsOneWidget);
      service.fail = false;
      await tester.ensureVisible(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
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
    'visible paragraph menu preserves input on failed edit and reverts provenance',
    (tester) async {
      final book = _DelayedEditBook();
      addTearDown(book.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(book),
            uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            home: const ReaderScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('문단 메뉴').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('문장 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '내가 선택한 새 문장이다.');
      await tester.tap(find.text('저장').last);
      await tester.pump();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '저장 중'))
            .onPressed,
        isNull,
      );
      expect(book.edits, 1);
      book.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('저장하지 못했어요. 입력한 문장은 그대로 남아 있어요.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '내가 선택한 새 문장이다.',
      );
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      expect(book.edits, 2);
      await tester.tap(find.byTooltip('문단 메뉴').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('원래 문장으로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('원래 문장으로'));
      await tester.pumpAndSettle();
      expect(find.text('내가 선택한 새 문장이다.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'save, optional recall, leave and archive resume require explicit generation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository();
      final engine = ControlledEngine();
      addTearDown(repository.dispose);
      addTearDown(engine.controller.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            engineClientProvider.overrideWithValue(engine),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        quietPageRoute(
                          const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
                        ),
                      ),
                      child: const Text('기록 열기'),
                    ),
                    Expanded(child: ArchiveScreen(onCapture: () {})),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('기록 열기'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        '얇은 유리 계단을 올라가니 종이 우산이 있었다.',
      );
      await tester.tap(find.text('꿈 저장하기'));
      await tester.pumpAndSettle();
      expect(find.text('꿈이 저장됐어요'), findsOneWidget);
      expect(find.text('밝았나요, 어두웠나요?'), findsNothing);
      expect(engine.keys, isEmpty);
      await tester.tap(find.text('기억 더 보강하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('밝음'));
      await tester.ensureVisible(find.text('보강 마치기'));
      await tester.tap(find.text('보강 마치기'));
      await tester.pumpAndSettle();
      expect(engine.keys, isEmpty);
      await tester.tap(find.text('나중에 만들기'));
      await tester.pumpAndSettle();
      final dream = (await tester.runAsync(
        () => repository.watchDreams(DreamStatusFilter.all).first,
      ))!.firstWhere((d) => d.rawText.startsWith('얇은 유리'));
      await tester.ensureVisible(find.text(dream.rawText));
      await tester.runAsync(() async {
        await tester.tap(find.text(dream.rawText));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('장면 만들기'));
      await tester.tap(find.text('장면 만들기'));
      await tester.pumpAndSettle();
      expect(find.text('꿈이 저장됐어요'), findsOneWidget);
      expect(engine.keys, isEmpty);
      await tester.tap(find.text('장면 만들기'));
      await tester.pump(const Duration(seconds: 1));
      expect(engine.keys, [dream.id]);
      final generated = (await tester.runAsync(
        () => repository.watchDreams(DreamStatusFilter.all).first,
      ))!.firstWhere((d) => d.id == dream.id);
      expect(generated.recallAnswers['light'], '밝음');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'new scene primary changes back to capture after opened result metadata',
    (tester) async {
      final repository = MemoryRepository();
      addTearDown(repository.dispose);
      final volume = (await tester.runAsync(
        () => repository.watchActiveVolume().first,
      ))!;
      final scenes = (await tester.runAsync(
        () => repository.watchScenes(volume.id).first,
      ))!;
      for (final scene in scenes) {
        final passages = (await tester.runAsync(
          () => repository.watchPassages(scene.id).first,
        ))!;
        if (scene != scenes.last && passages.isNotEmpty) {
          await repository.markPassageRead(passages.first.id);
        }
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repository),
            uiPreferenceStoreProvider.overrideWithValue(MemoryUiStore()),
          ],
          child: MaterialApp(
            theme: mumumongTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: HomeScreen(
                  onCapture: () {},
                  onReadScene: (id) => Navigator.of(context).push(
                    quietPageRoute(
                      ReaderScreen(volumeId: volume.id, initialSceneId: id),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(EditorialButton, '새 장면 읽기'), findsOneWidget);
      await tester.ensureVisible(find.text('새 장면 읽기'));
      await tester.tap(find.text('새 장면 읽기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(EditorialButton, '꿈 기록하기'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'policy link opens actual URL, failure offers copy with feedback',
    (tester) async {
      final uri = Uri.parse('https://example.test/policy');
      final opened = <Uri>[];
      var fail = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            policyLinkOpenerProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return !fail;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PolicyLink(label: '이용 약관', uri: uri),
            ),
          ),
        ),
      );
      await tester.tap(find.text('이용 약관 열기'));
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
      await tester.tap(find.text('이용 약관 열기'));
      await tester.pumpAndSettle();
      expect(find.text('링크를 열지 못했어요.'), findsOneWidget);
      await tester.tap(find.text('주소 복사'));
      await tester.pumpAndSettle();
      expect(find.textContaining('주소를 복사했어요.'), findsOneWidget);
    },
  );
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
