import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mumumong/data/export/book_store.dart';
import 'package:mumumong/data/local/database.dart';
import 'package:mumumong/data/local/drift_repository.dart';
import 'package:mumumong/domain/model/frozen_book.dart';

Future<String> readyBookFixture(AppDatabase db) async {
  final repo = DriftRepository(db);
  final volume = (await repo.watchActiveVolume().first)!;
  final scenes = await db.select(db.scenes).get();
  final source = scenes.last;
  final passage = (await (db.select(
    db.passages,
  )..where((p) => p.sceneId.equals(source.id))).get()).first;
  final bodyScenes = (await db.select(db.passages).get())
      .map((p) => p.sceneId)
      .toSet();
  for (var i = bodyScenes.length; i < 5; i++) {
    final id = 'synthetic-scene-$i';
    await db.into(db.scenes).insert(source.copyWith(id: id, orderKey: 'z$i'));
    await db
        .into(db.passages)
        .insert(
          passage.copyWith(
            id: 'synthetic-passage-$i',
            sceneId: id,
            content: '가상 원고: 종이 별이 빛났다.',
          ),
        );
  }
  await (db.update(db.volumes)..where((v) => v.id.equals(volume.id))).write(
    const VolumesCompanion(
      progressMu: Value(14),
      targetMu: Value(20),
      format: Value('short'),
    ),
  );
  await (db.update(
    db.entities,
  )).write(const EntitiesCompanion(mentionCount: Value(2)));
  await db.customStatement(
    "INSERT INTO entities(id,volume_id,type,role_name,status,mention_count,created_at,updated_at) VALUES (?,?, 'object','synthetic recurring object','confirmed',2,0,0)",
    ['synthetic-entity', volume.id],
  );
  return volume.id;
}

class FakeBookGateway implements BookGateway {
  @override
  String? userId = localUserId;
  final receipts = <String, FrozenBook>{};
  late BookCompletionPreview prepared;
  bool loseAck = false, conflict = false;
  @override
  Future<List<FrozenBook>> list() async => receipts.values.toList();
  @override
  Future<BookCompletionPreview> preview(String id) async => prepared;
  @override
  Future<void> next(String id) async {}
  @override
  Future<FrozenBook> complete(Map<String, dynamic> body) async {
    if (conflict) {
      throw const PostgrestException(
        message: 'manuscript changed',
        code: 'PT409',
      );
    }
    final id = body['p_request_id'] as String;
    final book = receipts.putIfAbsent(
      id,
      () => FrozenBook({
        ...prepared.document,
        'version': 1,
        'request_id': id,
        'title': body['p_title'],
        'author_note': body['p_author_note'],
        'completed_at': DateTime.utc(2026, 10, 23).toIso8601String(),
      }),
    );
    if (loseAck) throw StateError('synthetic_lost_ack');
    return book;
  }
}

void main() {
  test(
    'local book is immutable across source edits, reopen and next volume',
    () async {
      final dir = await Directory.systemTemp.createTemp('mumumong-book-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/synthetic.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final id = await readyBookFixture(db);
      var store = BookStore(db);
      final preview = await store.prepare(id);
      expect(preview.eligible, isTrue);
      await store.complete(id, preview, '종이 별의 책', '내가 쓴 가상 작가의 말');
      final book = (await store.watchBooks().first).single;
      final original = jsonEncode(book.toJson());
      await db.customStatement(
        "UPDATE passages SET text='synthetic later source change' WHERE origin<>'U'",
      );
      expect(
        jsonEncode((await store.watchBooks().first).single.toJson()),
        original,
      );
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      store = BookStore(db);
      expect((await store.watchBooks().first).single.title, '종이 별의 책');
      await store.next(book);
      await store.next(book);
      final repo = DriftRepository(db);
      final active = (await repo.watchActiveVolume().first)!;
      expect(active.volNo, 2);
      expect(active.progressMu, 0);
      expect((await store.watchBooks().first).length, 1);
    },
  );
  test(
    'completion rejects pending edits and stale local revision without book loss',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await readyBookFixture(db);
      final store = BookStore(db);
      final preview = await store.prepare(id);
      await db.customStatement(
        "UPDATE passages SET text='synthetic new content' WHERE origin<>'U'",
      );
      await expectLater(
        store.complete(id, preview, '책', null),
        throwsStateError,
      );
      expect(await store.watchBooks().first, isEmpty);
      await db
          .into(db.outbox)
          .insert(
            OutboxCompanion.insert(
              id: 'pending',
              op: 'edit_passage',
              payload: '{}',
              idempotencyKey: 'pending',
              nextAttemptAt: DateTime.now(),
              status: 'pending',
            ),
          );
      await expectLater(store.prepare(id), throwsStateError);
    },
  );
  test(
    'offline/lost completion ACK retains same request; retry stores exactly one book',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await readyBookFixture(db);
      final preview = await BookStore(db).prepare(id);
      final gateway = FakeBookGateway()
        ..prepared = preview
        ..loseAck = true;
      final store = BookStore(db, gateway: gateway);
      await store.complete(id, preview, '가상 원고', '가상 작가의 말');
      await store.complete(id, preview, 'duplicate tap ignored', null);
      final request = (await store.watchRequest(id).first)!;
      final row = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(request.requestId))).getSingle();
      final body = Map<String, dynamic>.from(
        jsonDecode(row.payload)['body'] as Map,
      );
      await expectLater(store.deliver(body), throwsStateError);
      expect(
        (await store.watchRequest(id).first)!.requestId,
        request.requestId,
      );
      expect(await store.watchBooks().first, isEmpty);
      gateway.loseAck = false;
      await store.retry(id);
      await store.deliver(body);
      await store.deliver(body);
      expect((await store.watchBooks().first).length, 1);
      expect(gateway.receipts.length, 1);
      expect(await store.watchRequest(id).first, isNull);
    },
  );
  test(
    'conflict restores active volume and explicit retry uses a fresh preview/request',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await readyBookFixture(db);
      final preview = await BookStore(db).prepare(id);
      final gateway = FakeBookGateway()
        ..prepared = preview
        ..conflict = true;
      final store = BookStore(db, gateway: gateway);
      await store.complete(id, preview, '가상 책', null);
      final original = (await store.watchRequest(id).first)!;
      final row = await (db.select(
        db.outbox,
      )..where((o) => o.id.equals(original.requestId))).getSingle();
      await store.deliver(
        Map<String, dynamic>.from(jsonDecode(row.payload)['body'] as Map),
      );
      expect((await store.watchRequest(id).first)!.status, 'conflict');
      expect(
        (await DriftRepository(db).watchActiveVolume().first)!.status.name,
        'active',
      );
      await store.complete(id, preview, '가상 책', null);
      expect(
        (await store.watchRequest(id).first)!.requestId,
        isNot(original.requestId),
      );
    },
  );
  test(
    'v4 to v5 migration preserves pending settings and manuscripts',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'mumumong-book-upgrade-',
      );
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/synthetic.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      final id = await readyBookFixture(db);
      final before = (await db.select(db.passages).get())
          .map((p) => p.toJson())
          .toList();
      await db.customStatement('DROP TABLE completed_books');
      await db.customStatement('DROP TABLE completion_requests');
      await db.customStatement('PRAGMA user_version=4');
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      expect((await BookStore(db).prepare(id)).eligible, isTrue);
      expect(
        (await db.select(db.passages).get()).map((p) => p.toJson()),
        before,
      );
      expect(await BookStore(db).watchBooks().first, isEmpty);
    },
  );
}
