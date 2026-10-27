import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/data_export.dart';
import '../../data/local/database.dart';
import '../../data/local/local_data_control.dart';
import '../../di/providers.dart';
import '../../domain/repository/mumumong_repository.dart';

/// The word a person types to confirm deleting every record.
const deleteEverythingConfirmation = '삭제';

bool confirmsDeleteEverything(String typed) =>
    typed.trim() == deleteEverythingConfirmation;

/// Export and delete-everything, shared by every settings interface so the
/// two cannot behave differently on a person's records.
abstract interface class RecordActions {
  /// Writes the local JSON export and opens the system share sheet.
  Future<void> shareExport({Rect? origin});

  /// Deletes the server account when signed in, then every local record,
  /// then signs out. Throws when the server deletion is not confirmed.
  Future<void> deleteEverything();
}

class DeviceRecordActions implements RecordActions {
  const DeviceRecordActions(this._database, this._repository);

  final AppDatabase _database;
  final MumumongRepository _repository;

  @override
  Future<void> shareExport({Rect? origin}) async {
    await _repository.watchActiveVolume().first;
    final content = await exportLocalManuscript(_database);
    await SharePlus.instance.share(
      ShareParams(
        title: '무무몽 내 기록',
        files: [
          XFile.fromData(utf8.encode(content), mimeType: 'application/json'),
        ],
        fileNameOverrides: ['mumumong-export.json'],
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Future<void> deleteEverything() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session != null) {
      final response = await client.functions.invoke(
        'delete-account',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('remote_delete_failed');
      }
    }
    await clearLocalData(_database);
    if (session != null) await client.auth.signOut();
  }
}

final recordActionsProvider = Provider<RecordActions>(
  (ref) => DeviceRecordActions(
    ref.watch(databaseProvider),
    ref.watch(repositoryProvider),
  ),
);
