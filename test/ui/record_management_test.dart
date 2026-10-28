// V1 delete-everything leaves the settings pages after the shared record
// action succeeds, so the gate underneath (now signed out) is what shows.
// Invented fixtures only; the record action is a fake.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/core/design/design_system.dart';
import 'package:mumumong/data/memory/memory_repository.dart';
import 'package:mumumong/di/providers.dart';
import 'package:mumumong/ui/settings/record_actions.dart';
import 'package:mumumong/ui/settings/settings_screen.dart';

class _Records implements RecordActions {
  int deletes = 0;

  @override
  Future<void> shareExport({Rect? origin}) async {}

  @override
  Future<void> deleteEverything() async => deletes++;
}

void main() {
  testWidgets('a confirmed delete-everything returns to the first route', (
    tester,
  ) async {
    final repo = MemoryRepository();
    addTearDown(repo.dispose);
    final records = _Records();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          recordActionsProvider.overrideWithValue(records),
        ],
        child: MaterialApp(
          theme: mumumongTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: SettingsScreen()),
                    ),
                  ),
                  child: const Text('첫 화면'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('첫 화면'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('기록 관리'));
    await tester.tap(find.text('기록 관리'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('모든 기록 삭제'));
    await tester.tap(find.text('모든 기록 삭제').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '삭제');
    await tester.pump();
    await tester.tap(find.text('영구 삭제'));
    await tester.pumpAndSettle();

    expect(records.deletes, 1);
    expect(find.text('첫 화면'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}
