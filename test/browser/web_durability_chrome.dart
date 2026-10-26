// Browser-only real SQLite/IndexedDB regression. No auth, server data or AI.
// Run with tool/test_web_durability.sh, not as a VM widget test. This explicit
// *_chrome.dart target is excluded from the VM's default *_test.dart discovery.
import 'package:drift/wasm.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/models.dart';
import 'package:mumumong/domain/repository/mumumong_repository.dart';
import 'package:sqlite3/wasm.dart';

void main() {
  test('draft transaction reaches IndexedDB before a graceful close', () async {
    // Two independent readers are intentional, never two connections sharing a
    // VFS. Suppress only Drift's duplicate-class diagnostic for this test.
    final previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final name =
        'mumumong-qa-durability-${DateTime.now().microsecondsSinceEpoch}';
    final uri = Uri.parse('http://127.0.0.1:4217/sqlite3.wasm');
    final writerFs = await IndexedDbFileSystem.open(
      dbName: name,
      writeAutomatically: false,
    );
    final writerSqlite = await WasmSqlite3.loadFromUrl(uri);
    writerSqlite.registerVirtualFileSystem(writerFs, makeDefault: true);
    final writer = AppDatabase.forTesting(
      WasmDatabase(
        sqlite3: writerSqlite,
        path: '/database',
        fileSystem: writerFs,
      ),
    );
    AppDatabase? reader;
    IndexedDbFileSystem? readerFs;
    try {
      final repo = DriftRepository(writer, seedPrototype: false);
      final now = DateTime.now().toUtc();
      await repo.saveDraft(
        DreamDraft(
          id: '00000000-0000-4000-8000-000000000925',
          rawText: '가상 꿈: 푸른 종이별이 창가에서 춤췄다.',
          inputMode: DreamInputMode.text,
          dreamDate: now,
          isBackfill: false,
          updatedAt: now,
        ),
      );
      // Do NOT close or flush writer: old Drift only persisted at a later
      // statement/close. An independent VFS must already see the committed row.
      readerFs = await IndexedDbFileSystem.open(
        dbName: name,
        writeAutomatically: false,
      );
      final readerSqlite = await WasmSqlite3.loadFromUrl(uri);
      readerSqlite.registerVirtualFileSystem(readerFs, makeDefault: true);
      reader = AppDatabase.forTesting(
        WasmDatabase(
          sqlite3: readerSqlite,
          path: '/database',
          fileSystem: readerFs,
        ),
      );
      final restored = await DriftRepository(
        reader,
        seedPrototype: false,
      ).loadDraft();
      expect(restored?.rawText, '가상 꿈: 푸른 종이별이 창가에서 춤췄다.');
    } finally {
      await reader?.close();
      await writer.close();
      await readerFs?.close();
      await writerFs.close();
      // This exact per-test database was created above; never app/user storage.
      await IndexedDbFileSystem.deleteDatabase(name);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning;
    }
  });
}
