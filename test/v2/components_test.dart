// One interaction physics for every control (DESIGN_V2.md §7.1).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/v2/components/buttons.dart';
import 'package:mumumong/v2/components/feedback.dart';
import 'package:mumumong/v2/components/inputs.dart';
import 'package:mumumong/v2/design/keep_all.dart';
import 'package:mumumong/v2/design/theme.dart';

import 'support.dart';

// Found on the web consent page: 지우 / 면.
const _meta = '이 브라우저에서 이어 쓸 수 있어요. 브라우저 데이터를 지우면 기록을 복구할 수 없어요.';

Widget _host(Widget child) => MaterialApp(
  theme: v2Theme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUpAll(loadV2Fonts);

  testWidgets('a tap activates once, sinks the surface and gives haptics', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var taps = 0;
    await tester.pumpWidget(
      _host(V2Button(label: '꿈 저장하기', onPressed: () => taps++)),
    );
    double scale() => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(V2Button),
            matching: find.byType(Transform),
          ),
        )
        .map((t) => t.transform.storage[0])
        .reduce((a, b) => a < b ? a : b);
    expect(scale(), closeTo(1, .001));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(V2Button)),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(const Duration(milliseconds: 160));
    expect(scale(), lessThan(.99), reason: 'the surface sinks while held');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(scale(), closeTo(1, .002), reason: 'the spring restores it');
    expect(haptics, isNotEmpty);
  });

  testWidgets('disabled and loading controls never activate', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const V2Button(label: '비활성', onPressed: null),
            V2Button(
              label: '저장',
              loading: true,
              loadingLabel: '저장하는 중',
              onPressed: () => taps++,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('비활성'), warnIfMissed: false);
    await tester.tap(find.text('저장하는 중'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 0);
    final semantics = tester.getSemantics(find.text('저장하는 중'));
    expect(semantics.hint, '진행 중');
  });

  testWidgets('keyboard focus and Enter activate with the same physics', (
    tester,
  ) async {
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(V2Button.glass(label: '기억 보강하기', onPressed: () => taps++)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('every control keeps a 44pt target and a label', (tester) async {
    await tester.pumpWidget(
      _host(
        Wrap(
          children: [
            V2IconButton(
              icon: Icons.close,
              semanticLabel: '닫기',
              onPressed: () {},
            ),
            V2TextAction(label: '나중에 만들기', onPressed: () {}),
            V2ChoiceChip(label: '모름', selected: false, onSelected: () {}),
            V2RecordButton(recording: false, onPressed: () {}),
            V2Button(label: '작게', size: V2ButtonSize.compact, onPressed: () {}),
          ],
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('check rows and the recorder expose their state', (tester) async {
    var checked = false;
    var recording = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              V2CheckRow(
                label: '만 14세 이상입니다.',
                value: checked,
                onChanged: (value) => setState(() => checked = value),
              ),
              V2RecordButton(
                recording: recording,
                onPressed: () => setState(() => recording = !recording),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('만 14세 이상입니다.'));
    await tester.pumpAndSettle();
    expect(checked, isTrue);
    expect(
      tester.getSemantics(find.byType(V2CheckRow)),
      matchesSemantics(
        label: '만 14세 이상입니다.',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.bySemanticsLabel('말로 기록하기'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('녹음 멈추기'), findsOneWidget);
  });

  // Found on the simulator: a dialog body broke 화면에서 as 화면에 / 서.
  testWidgets('dialog, notice, toast and meta prose break only between words', (
    tester,
  ) async {
    const body = '공유할 곳은 다음 화면에서 직접 선택해 주세요.';
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const V2Notice(message: '연결이 돌아오면 다시 확인해요.'),
              const V2Meta(_meta),
              TextButton(
                onPressed: () => showV2Toast(context, '파일을 저장하지 않았어요.'),
                child: const Text('toast'),
              ),
              TextButton(
                onPressed: () => showV2Dialog<void>(
                  context,
                  title: '내 기록 내보내기',
                  body: body,
                  actions: (_) => const [],
                ),
                child: const Text('dialog'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('toast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dialog'));
    await tester.pumpAndSettle();
    for (final text in [body, '연결이 돌아오면 다시 확인해요.', '파일을 저장하지 않았어요.', _meta]) {
      expect(tester.widget<Text>(v2Text(text)).data, v2KeepAll(text));
    }
  });

  // Found on the simulator at the largest iOS text size: compact button
  // labels were cut off at the bottom.
  testWidgets('button labels fit their height at the largest text size', (
    tester,
  ) async {
    setV2View(tester, scale: 3.12);
    await tester.pumpWidget(
      _host(
        V2Button(
          label: '이어 읽기',
          size: V2ButtonSize.compact,
          trailingIcon: Icons.add_rounded,
          onPressed: () {},
        ),
      ),
    );
    // The label's natural line height must fit the box it was given.
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: v2Text('이어 읽기'), matching: find.byType(RichText)),
    );
    expect(
      paragraph.getMaxIntrinsicHeight(paragraph.size.width),
      lessThanOrEqualTo(paragraph.size.height + .5),
    );
    expect(tester.takeException(), isNull);
  });
}
