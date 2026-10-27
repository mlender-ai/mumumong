// Migrated from test/ui/start_flow_simplification_test.dart and
// test/ui/shell_layout_test.dart (V1): the first-volume setup keeps the
// person's choices when creation fails and never starts twice, and the home
// pending summary leaves out zero counts and opens the archive.
// Invented fixtures only.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:mumumong/v2/app.dart';
import 'package:mumumong/v2/components/inputs.dart';
import 'package:mumumong/v2/preview/preview_stores.dart';
import 'package:mumumong/v2/screens/home.dart';
import 'package:mumumong/v2/screens/volume_setup.dart';

import 'support.dart';

void main() {
  setUpAll(loadV2Fonts);

  testWidgets(
    'setup keeps selected choices on failure and starts once during a pending request',
    (tester) async {
      setV2View(tester, reduceMotion: true);
      var requests = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            uiPreferenceStoreProvider.overrideWithValue(
              MemoryUiPreferenceStore(),
            ),
          ],
          child: MumumongV2App(
            home: V2VolumeSetupScreen(
              onComplete: () {},
              createVolume:
                  ({
                    required adaptation,
                    required style,
                    required narrativeVoice,
                  }) {
                    requests++;
                    expect(adaptation, AdaptationLevel.faithful);
                    return pending.future;
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(v2Text('이야기 설정'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(v2Text('꿈에 충실하게'));
      await tester.tap(v2Text('꿈에 충실하게'));
      await tester.pump();
      await tester.ensureVisible(v2Text('시작하기'));
      await tester.tap(v2Text('시작하기'));
      await tester.pump();
      expect(requests, 1);
      expect(v2TextContaining('준비하고 있어요'), findsOneWidget);

      // A second tap while the request is pending must not start again.
      await tester.tap(v2Text('준비하는 중'), warnIfMissed: false);
      await tester.pump();
      expect(requests, 1);

      pending.completeError(StateError('synthetic_offline'));
      await tester.pumpAndSettle();
      expect(v2TextContaining('원고를 만들지 못했어요'), findsOneWidget);
      await tester.ensureVisible(v2Text('꿈에 충실하게'));
      expect(
        tester
            .widget<V2ChoiceChip>(find.widgetWithText(V2ChoiceChip, '꿈에 충실하게'))
            .selected,
        isTrue,
      );
    },
  );

  testWidgets('home pending summary omits zero counts and opens archive', (
    tester,
  ) async {
    setV2View(tester, reduceMotion: true);
    final repository = MemoryRepository(seedPrototype: false);
    addTearDown(repository.dispose);
    await tester.runAsync(() async {
      await repository.createPreviewVolume(
        adaptation: AdaptationLevel.balanced,
        style: WritingStyle.plain,
        narrativeVoice: NarrativeVoice.firstPersonPast,
      );
      await repository.submitDream(
        DreamDraft(
          id: 'shell-pending-fixture',
          rawText: '가상 기록: 나는 종이 구름을 바라봤다.',
          inputMode: DreamInputMode.text,
          dreamDate: DateTime(2026, 10, 23),
          isBackfill: false,
          updatedAt: DateTime(2026, 10, 23),
        ),
      );
    });
    var opened = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          networkConnectedProvider.overrideWith((ref) => Stream.value(true)),
          uiPreferenceStoreProvider.overrideWithValue(
            MemoryUiPreferenceStore(),
          ),
        ],
        child: MumumongV2App(
          home: Scaffold(
            body: V2HomeScreen(onCapture: () {}, onArchive: () => opened++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(v2Text('첫 꿈이\n남아 있어요'), findsOneWidget);
    expect(v2TextContaining('첫 꿈을'), findsNothing);
    final summary = v2Text('보관함  ·  1개 생성 전');
    expect(summary, findsOneWidget);
    expect(v2TextContaining('0개'), findsNothing);
    await tester.ensureVisible(summary);
    await tester.pumpAndSettle();
    await tester.tap(summary);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
