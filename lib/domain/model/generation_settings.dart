import 'enums.dart';

class GenerationSettings {
  const GenerationSettings({
    required this.adaptation,
    required this.style,
    required this.narrativeVoice,
  });
  final AdaptationLevel adaptation;
  final WritingStyle style;
  final NarrativeVoice narrativeVoice;
  Map<String, dynamic> toJson() => {
    'adaptation': adaptation.databaseValue,
    'style': style.databaseValue,
    'narrative_voice': narrativeVoice.databaseValue,
  };
  factory GenerationSettings.fromJson(Map<String, dynamic> value) =>
      GenerationSettings(
        adaptation: enumFromDatabase(
          value['adaptation'],
          AdaptationLevel.values,
        ),
        style: enumFromDatabase(value['style'], WritingStyle.values),
        narrativeVoice: enumFromDatabase(
          value['narrative_voice'],
          NarrativeVoice.values,
        ),
      );
  @override
  bool operator ==(Object other) =>
      other is GenerationSettings &&
      other.adaptation == adaptation &&
      other.style == style &&
      other.narrativeVoice == narrativeVoice;
  @override
  int get hashCode => Object.hash(adaptation, style, narrativeVoice);
}

enum SettingsSyncStatus { synced, pending, conflict }

class GenerationSettingsState {
  const GenerationSettingsState({
    required this.confirmed,
    required this.version,
    this.pending,
    this.status = SettingsSyncStatus.synced,
  });
  final GenerationSettings confirmed;
  final int version;
  final GenerationSettings? pending;
  final SettingsSyncStatus status;
  GenerationSettings get selected => pending ?? confirmed;
}

class GenerationSettingsPending implements Exception {
  const GenerationSettingsPending();
}

class GenerationSettingsConflict implements Exception {
  const GenerationSettingsConflict();
}
