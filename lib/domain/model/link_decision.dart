import 'enums.dart';
import 'serialization.dart';

class LinkDecision {
  LinkDecision({
    required this.id,
    required this.dreamId,
    required this.kind,
    required Map<String, dynamic> payload,
    required this.status,
  }) : payload = Map.unmodifiable(payload);

  final String id;
  final String dreamId;
  final LinkDecisionKind kind;
  final Map<String, dynamic> payload;
  final LinkDecisionStatus status;

  LinkDecision copyWith({
    String? id,
    String? dreamId,
    LinkDecisionKind? kind,
    Map<String, dynamic>? payload,
    LinkDecisionStatus? status,
  }) {
    return LinkDecision(
      id: id ?? this.id,
      dreamId: dreamId ?? this.dreamId,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dream_id': dreamId,
    'kind': kind.databaseValue,
    'payload': payload,
    'status': status.databaseValue,
  };

  factory LinkDecision.fromJson(Map<String, dynamic> json) {
    return LinkDecision(
      id: json['id'] as String,
      dreamId: json['dream_id'] as String,
      kind: enumFromDatabase(json['kind'], LinkDecisionKind.values),
      payload: jsonObject(json['payload'], 'payload'),
      status: enumFromDatabase(json['status'], LinkDecisionStatus.values),
    );
  }
}
