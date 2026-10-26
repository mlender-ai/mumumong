import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mumumong/core/design/ui_preferences.dart';
import 'package:mumumong/core/design/dream_atmosphere.dart';

import '../../tool/visual_preview.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'preview entry uses the persisted night atmosphere after reopening',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        DeviceUiPreferenceStore.key: '{"theme":"dark","reader_scale":1.4}',
      });
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: VisualPreviewApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<DreamAtmosphere>(find.byType(DreamAtmosphere)).night,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'preview restores the full entry screen before the concise home',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: VisualPreviewApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('꿈이 자라,\n이야기가 되는 곳.'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.textContaining('Apple'), findsNothing);
      await _enterFromOnboarding(tester);
      expect(find.text('꿈 기록하기'), findsOneWidget);
      expect(find.text('원고 읽기'), findsNothing);
      expect(find.text('열린 장면'), findsNothing);
      final cover = tester.getRect(find.byType(DreamAtmosphere).first);
      expect(cover.left, 16);
      expect(cover.top, 10);
      expect(cover.width, 358);

      await tester.tap(find.text('보관함'));
      await tester.pump();
      expect(find.text('꿈 보관함'), findsOneWidget);
    },
  );

  testWidgets('설정은 허브에서 세부 항목으로 나뉘고 돌아올 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: VisualPreviewApp(),
      ),
    );
    await _enterFromOnboarding(tester);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    expect(find.text('내 기록과 설정'), findsNothing);
    expect(find.text('기록 관리'), findsOneWidget);
    expect(find.text('앱 잠금'), findsOneWidget);
    expect(find.text('AI 처리 고지'), findsOneWidget);
    expect(find.text('음성 기록'), findsOneWidget);

    await tester.ensureVisible(find.text('AI 처리 고지'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 처리 고지'));
    await tester.pumpAndSettle();
    expect(find.textContaining('디자인 검토용 목업'), findsOneWidget);
    expect(find.byTooltip('설정으로 돌아가기'), findsOneWidget);
    await tester.tap(find.byTooltip('설정으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('기록 관리'), findsOneWidget);
  });

  testWidgets('미리보기에서 기록부터 결과와 보관함까지 이어진다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: VisualPreviewApp(),
      ),
    );
    await _enterFromOnboarding(tester);
    await tester.tap(find.text('꿈 기록하기'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '푸른 문을 열고 작은 정원에 들어갔다.');
    await tester.pump();
    await tester.tap(find.text('꿈 저장하기'));
    await tester.pump(const Duration(milliseconds: 500));
    final skip = find.text('장면 만들기');
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    for (
      var attempt = 0;
      attempt < 40 && find.text('새 장면 읽기').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('새 장면 읽기'), findsOneWidget);
    await tester.ensureVisible(find.text('새 장면 읽기'));
    await tester.pump();
    await tester.tap(find.text('새 장면 읽기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보관함'));
    await tester.pump();
    expect(find.textContaining('푸른 문을 열고 작은 정원'), findsWidgets);
  });
}

Future<void> _enterFromOnboarding(WidgetTester tester) async {
  await tester.tap(find.text('시작하기'));
  await tester.pumpAndSettle();
  expect(find.text('시작 전,\n두 가지만 확인해 주세요.'), findsOneWidget);
  await tester.ensureVisible(find.byKey(const Key('age-confirmation')));
  await tester.tap(find.byKey(const Key('age-confirmation')));
  await tester.ensureVisible(find.byKey(const Key('ai-consent')));
  await tester.tap(find.byKey(const Key('ai-consent')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('확인하고 계속'));
  await tester.pumpAndSettle();
  expect(find.text('시작하기'), findsOneWidget);
  await tester.tap(find.text('시작하기'));
  await tester.pumpAndSettle();
}
