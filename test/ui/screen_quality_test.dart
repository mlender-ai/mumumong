// P3 shared chrome: bottom navigation, context bar, list rows and the home
// progress-reason label all come from DESIGN.md components, not screens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/ui/home/home_screen.dart';

void main() {
  testWidgets('bottom navigation is one pill bar with a quiet selected tab', (
    tester,
  ) async {
    var selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: MongBottomNav(
              labels: const ['원고', '보관함', '설정'],
              selectedIndex: selected,
              onSelect: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MongBottomNav), findsOneWidget);
    expect(
      tester.getSize(find.byType(MongBottomNav)).height,
      greaterThanOrEqualTo(MongSize.nav),
    );
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MongBottomNav),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(MongRadius.nav));
    expect(decoration.boxShadow, MongShadow.whisper);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    final selectedTab = tester
        .widgetList<Semantics>(
          find.ancestor(of: find.text('설정'), matching: find.byType(Semantics)),
        )
        .firstWhere((s) => s.properties.selected != null);
    expect(selectedTab.properties.selected, isTrue);
  });

  testWidgets('list rows keep 44px touch, a chevron and alert ink when '
      'destructive', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: Column(
            children: [
              MongListRow(
                title: '화면과 읽기',
                subtitle: '테마 · 원고 글자 크기',
                onTap: () => taps++,
              ),
              MongListRow(
                title: '모든 기록 삭제',
                subtitle: '되돌릴 수 없어요',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MongListRow).first).height,
      greaterThanOrEqualTo(MongSize.touch),
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    final destructive = tester.widget<Text>(find.text('모든 기록 삭제'));
    expect(destructive.style?.color, MongColor.alert);
    await tester.tap(find.text('화면과 읽기'));
    expect(taps, 1);
  });

  testWidgets('context bar places leading, content and trailing on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mumumongTheme(),
        home: Scaffold(
          body: MongContextBar(
            leading: MongIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: '닫기',
              onPressed: () {},
            ),
            trailing: MongIconButton(
              icon: Icons.more_horiz,
              semanticLabel: '메뉴',
              onPressed: () {},
            ),
            child: const Text('VOL.01'),
          ),
        ),
      ),
    );
    final back = tester.getRect(find.byTooltip('닫기'));
    final title = tester.getRect(find.text('VOL.01'));
    final menu = tester.getRect(find.byTooltip('메뉴'));
    expect(back.right, lessThanOrEqualTo(title.left));
    expect(title.right, lessThanOrEqualTo(menu.left));
    expect(back.height, greaterThanOrEqualTo(MongSize.touch));
  });

  test('home progress label is derived only from recorded reasons', () {
    final event = ProgressEvent(
      id: 'e1',
      volumeId: 'v1',
      dreamId: 'd1',
      deltaMu: .8,
      reasons: const [
        {'type': 'new_scene', 'n': 1},
        {'type': 'recall', 'n': 2},
        {'type': 'unknown_future', 'n': 9},
      ],
      createdAt: DateTime.utc(2026, 10, 26),
    );
    expect(progressReasonLabel(event, 20), '+4%  ·  새 장면  ·  보강 2');
    expect(progressReasonLabel(event.copyWith(reasons: const []), 20), '+4%');
  });
}
