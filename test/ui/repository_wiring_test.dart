import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/main.dart';
import 'package:mumumong/ui/archive/archive_screen.dart';
import 'package:mumumong/ui/capture/capture_flow.dart';
import 'package:mumumong/ui/reader/reader_screen.dart';

void main() {
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget scopedApp(MemoryRepository repository, Widget child) {
    return ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repository)],
      child: child,
    );
  }

  testWidgets('home renders volume progress and counts from repository', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(scopedApp(repository, const MumumongApp()));
    await tester.pumpAndSettle();

    expect(find.text('42%'), findsOneWidget);
    expect(find.text('7 dreams     11 scenes     약 35p'), findsOneWidget);
    expect(find.text('문틈으로 물소리가 새어 나오고 있었다.'), findsOneWidget);
  });

  testWidgets('archive groups typed dreams by month and filters them', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      scopedApp(
        repository,
        MaterialApp(
          theme: mumumongTheme(),
          home: Scaffold(body: ArchiveScreen(onCapture: () {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    expect(find.text('AUGUST 2026'), findsOneWidget);
    expect(find.text('작은 열쇠가 손바닥 위에 있었다.'), findsOneWidget);

    await tester.tap(find.text('기록만').first);
    await tester.pumpAndSettle();

    expect(find.text('작은 열쇠가 손바닥 위에 있었다.'), findsOneWidget);
    expect(find.text('비어 있는 학교 복도를 계속 걸었다.'), findsNothing);
  });

  testWidgets('reader renders repository scene and five passages', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      scopedApp(
        repository,
        MaterialApp(theme: mumumongTheme(), home: const ReaderScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('붉은 문'), findsOneWidget);
    expect(find.byType(ReaderPassage), findsNWidgets(5));
    expect(find.text('나는 그 소리가 안에서 나는 것이 아니라는 걸 알고 있었다.'), findsOneWidget);
  });

  testWidgets('capture submits, processes, and reveals repository data', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final repository = MemoryRepository(processingDelay: Duration.zero);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      scopedApp(
        repository,
        MaterialApp(
          theme: mumumongTheme(),
          home: const CaptureFlow(dreamNumber: 8, sceneNumber: 12),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '복도 끝에 파란 문이 있었다.');
    await tester.tap(find.text('기록 저장'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('기억의 빈자리만\n조금 더 확인할게요.'), findsOneWidget);

    await tester.tap(find.text('전체 건너뛰기'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    for (var index = 0; index < 5; index++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    for (var index = 0; index < 8; index++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('processing')), findsNothing);
    expect(find.byKey(const ValueKey('reveal')), findsOneWidget);
    expect(find.text('DREAM 008  →  SCENE 12'), findsOneWidget);
    expect(find.text('문 밖의 여자'), findsOneWidget);
    expect(find.text('그때 문틈으로 물소리가 새어 나오기 시작했다.'), findsOneWidget);
  });
}
