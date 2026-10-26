import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thinking_orbs/thinking_orbs.dart' as orbs;
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import '../../tool/orb_motion_review.dart';
import '../../tool/visual_preview.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'empty preview starts with no manuscript and uses selected first-volume settings',
    () async {
      final repo = MemoryRepository(seedPrototype: false);
      addTearDown(repo.dispose);
      expect(await repo.watchActiveVolume().first, isNull);
      expect(await repo.watchDreams(DreamStatusFilter.all).first, isEmpty);
      await repo.createPreviewVolume(
        adaptation: AdaptationLevel.faithful,
        style: WritingStyle.lyrical,
        narrativeVoice: NarrativeVoice.thirdPersonPast,
      );
      final volume = (await repo.watchActiveVolume().first)!;
      expect(volume.progressMu, 0);
      expect(volume.format, VolumeFormat.short);
      expect(volume.style, WritingStyle.lyrical);
      expect(volume.adaptation, AdaptationLevel.faithful);
      expect(volume.narrativeVoice, NarrativeVoice.thirdPersonPast);
      expect(volume.genreProfile, isEmpty);
      expect(await repo.watchScenes(volume.id).first, isEmpty);
    },
  );

  testWidgets(
    'review begins at real onboarding and cannot skip the two checks',
    (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: VisualPreviewApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Orb 모션 보기'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      GlassActionButton action() =>
          tester.widget(find.byType(GlassActionButton).last);
      expect(action().onPressed, isNull);
      expect(find.textContaining('실제 계정·AI 요청·서버 동의 기록'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('age-confirmation')));
      await tester.tap(find.byKey(const Key('age-confirmation')));
      await tester.pumpAndSettle();
      expect(action().onPressed, isNull);
      await tester.ensureVisible(find.byKey(const Key('ai-consent')));
      await tester.tap(find.byKey(const Key('ai-consent')));
      await tester.pumpAndSettle();
      expect(action().onPressed, isNotNull);
      await tester.tap(find.text('확인하고 계속'));
      await tester.pumpAndSettle();
      expect(find.text('시작하기'), findsOneWidget);
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('첫 꿈을 기다리고 있어요'), findsOneWidget);
      expect(find.text('이어 읽기'), findsNothing);
      expect(find.text('42%'), findsNothing);
      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('온보딩 다시 보기'));
      await tester.pumpAndSettle();
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.text('꿈 기록하기'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'nine native orb states are selectable; pause and dark preview work',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const OrbMotionReview(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChipEditorial), findsNWidgets(9));
      for (final state in orbs.OrbState.values) {
        final choice = find.byWidgetPredicate(
          (w) => w is ChoiceChipEditorial && w.label == state.name,
        );
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(
          tester.widget<orbs.ThinkingOrb>(find.byType(orbs.ThinkingOrb)).state,
          state,
        );
      }
      expect(find.textContaining('기기에서 동작 줄이기'), findsOneWidget);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<orbs.ThinkingOrb>(find.byType(orbs.ThinkingOrb)).color,
        const Color(0xFFC8E6FA),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'orb review changes raster frames and pause freezes the same render',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: mumumongTheme(), home: const OrbMotionReview()),
      );
      await tester.pump();
      Future<List<int>> pixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('orb-review-animation')),
        );
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes!.buffer.asUint8List().toList();
      }

      final before = (await tester.runAsync(pixels))!;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 180)),
      );
      await tester.pump(const Duration(milliseconds: 180));
      final after = (await tester.runAsync(pixels))!;
      expect(before, isNot(orderedEquals(after)));
      await tester.ensureVisible(find.text('일시 정지'));
      await tester.tap(find.text('일시 정지'));
      await tester.pump();
      expect(
        tester.widget<orbs.ThinkingOrb>(find.byType(orbs.ThinkingOrb)).paused,
        isTrue,
      );
      final paused = (await tester.runAsync(pixels))!;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 180)),
      );
      await tester.pump(const Duration(milliseconds: 180));
      expect((await tester.runAsync(pixels))!, orderedEquals(paused));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
