import '../model/models.dart';

enum DreamStatusFilter { all, inManuscript, archivedOnly }

enum LinkChoice { same, different, unsure }

enum DeleteMode { deleteDerivedContent, keepDerivedContent }

class DreamDraft {
  const DreamDraft({
    required this.id,
    required this.rawText,
    required this.inputMode,
    required this.dreamDate,
    required this.isBackfill,
    required this.updatedAt,
  });

  final String id;
  final String rawText;
  final DreamInputMode inputMode;
  final DateTime dreamDate;
  final bool isBackfill;
  final DateTime updatedAt;

  DreamDraft copyWith({
    String? id,
    String? rawText,
    DreamInputMode? inputMode,
    DateTime? dreamDate,
    bool? isBackfill,
    DateTime? updatedAt,
  }) {
    return DreamDraft(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      inputMode: inputMode ?? this.inputMode,
      dreamDate: dreamDate ?? this.dreamDate,
      isBackfill: isBackfill ?? this.isBackfill,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

abstract class MumumongRepository {
  Stream<Volume?> watchActiveVolume();
  Stream<List<Dream>> watchDreams(DreamStatusFilter filter);
  Stream<List<Scene>> watchScenes(String volumeId);
  Stream<List<Passage>> watchPassages(String sceneId);
  Stream<List<ProgressEvent>> watchRecentProgress(String volumeId);
  Stream<JobProgress?> watchJob(String dreamId);

  Future<void> saveDraft(DreamDraft draft);
  Future<DreamDraft?> loadDraft();
  Future<void> clearDraft();
  Future<String> submitDream(DreamDraft draft);
  Future<void> answerRecall(String dreamId, Map<String, String> answers);
  Future<void> decideLink(String decisionId, LinkChoice choice);
  Future<void> changePlacement(String sceneId, PlacementKind kind);
  Future<void> editPassage(String passageId, String text);
  Future<void> revertPassage(String passageId);
  Future<void> markPassageRead(String passageId);
  Future<void> removeDreamFromManuscript(String dreamId);
  Future<void> deleteDream(String dreamId, DeleteMode mode);
}
