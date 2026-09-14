enum PassageOrigin { dream, connection, user }

enum DreamClarity { fragment, partial, vivid }

enum DreamStatus { queued, processing, inManuscript, archivedOnly, failed }

enum PlacementKind {
  continuation,
  motif,
  interlude,
  fragmentAttach,
  standalone,
}

enum AdaptationLevel { faithful, balanced }

enum WritingStyle { plain, lyrical, cinematic }

enum NarrativeVoice { thirdPersonPast, firstPersonPast }

enum VolumeStatus { active, completable, completing, completed }

enum SceneKind { prologue, dream, interlude, ending }

enum JobType {
  extract,
  link,
  plan,
  write,
  validate,
  commit,
  remember,
  linkPatch,
}

enum VolumeFormat { short, novella }

enum DreamInputMode { voice, text }

enum DreamElementType { person, place, object, event, emotion, sensory }

enum DreamElementSalience { high, mid, low }

enum DreamElementSource { raw, recall }

enum StoryEntityStatus { confirmed, ambiguous }

enum LinkDecisionKind { entityMerge, placement }

enum LinkDecisionStatus { auto, pending, same, different, unsure, changed }

enum JobStatus { queued, running, done, failed }

const Map<Enum, String> _databaseEnumValues = {
  PassageOrigin.dream: 'D',
  PassageOrigin.connection: 'C',
  PassageOrigin.user: 'U',
  DreamClarity.fragment: 'fragment',
  DreamClarity.partial: 'partial',
  DreamClarity.vivid: 'vivid',
  DreamStatus.queued: 'queued',
  DreamStatus.processing: 'processing',
  DreamStatus.inManuscript: 'in_manuscript',
  DreamStatus.archivedOnly: 'archived_only',
  DreamStatus.failed: 'failed',
  PlacementKind.continuation: 'continuation',
  PlacementKind.motif: 'motif',
  PlacementKind.interlude: 'interlude',
  PlacementKind.fragmentAttach: 'fragment_attach',
  PlacementKind.standalone: 'standalone',
  AdaptationLevel.faithful: 'faithful',
  AdaptationLevel.balanced: 'balanced',
  WritingStyle.plain: 'plain',
  WritingStyle.lyrical: 'lyrical',
  WritingStyle.cinematic: 'cinematic',
  NarrativeVoice.thirdPersonPast: 'third_person_past',
  NarrativeVoice.firstPersonPast: 'first_person_past',
  VolumeStatus.active: 'active',
  VolumeStatus.completable: 'completable',
  VolumeStatus.completing: 'completing',
  VolumeStatus.completed: 'completed',
  SceneKind.prologue: 'prologue',
  SceneKind.dream: 'dream',
  SceneKind.interlude: 'interlude',
  SceneKind.ending: 'ending',
  JobType.extract: 'extract',
  JobType.link: 'link',
  JobType.plan: 'plan',
  JobType.write: 'write',
  JobType.validate: 'validate',
  JobType.commit: 'commit',
  JobType.remember: 'remember',
  JobType.linkPatch: 'link_patch',
  VolumeFormat.short: 'short',
  VolumeFormat.novella: 'novella',
  DreamInputMode.voice: 'voice',
  DreamInputMode.text: 'text',
  DreamElementType.person: 'person',
  DreamElementType.place: 'place',
  DreamElementType.object: 'object',
  DreamElementType.event: 'event',
  DreamElementType.emotion: 'emotion',
  DreamElementType.sensory: 'sensory',
  DreamElementSalience.high: 'high',
  DreamElementSalience.mid: 'mid',
  DreamElementSalience.low: 'low',
  DreamElementSource.raw: 'raw',
  DreamElementSource.recall: 'recall',
  StoryEntityStatus.confirmed: 'confirmed',
  StoryEntityStatus.ambiguous: 'ambiguous',
  LinkDecisionKind.entityMerge: 'entity_merge',
  LinkDecisionKind.placement: 'placement',
  LinkDecisionStatus.auto: 'auto',
  LinkDecisionStatus.pending: 'pending',
  LinkDecisionStatus.same: 'same',
  LinkDecisionStatus.different: 'different',
  LinkDecisionStatus.unsure: 'unsure',
  LinkDecisionStatus.changed: 'changed',
  JobStatus.queued: 'queued',
  JobStatus.running: 'running',
  JobStatus.done: 'done',
  JobStatus.failed: 'failed',
};

extension DatabaseEnumValue on Enum {
  String get databaseValue {
    final value = _databaseEnumValues[this];
    if (value == null) {
      throw StateError('No database mapping for $runtimeType.$name');
    }
    return value;
  }
}

T enumFromDatabase<T extends Enum>(Object? value, List<T> values) {
  if (value is! String) {
    throw FormatException('Expected a database enum string, got $value');
  }

  for (final candidate in values) {
    if (candidate.databaseValue == value) {
      return candidate;
    }
  }

  throw FormatException('Unknown ${T.toString()} database value: $value');
}
