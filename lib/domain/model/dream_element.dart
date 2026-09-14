import 'enums.dart';
import 'serialization.dart';

class DreamElement {
  const DreamElement({
    required this.id,
    required this.dreamId,
    required this.type,
    required this.label,
    required this.detail,
    required this.salience,
    required this.source,
    required this.span,
  });

  static const Object _unset = Object();

  final String id;
  final String dreamId;
  final DreamElementType type;
  final String label;
  final String? detail;
  final DreamElementSalience salience;
  final DreamElementSource source;
  final (int, int)? span;

  DreamElement copyWith({
    String? id,
    String? dreamId,
    DreamElementType? type,
    String? label,
    Object? detail = _unset,
    DreamElementSalience? salience,
    DreamElementSource? source,
    Object? span = _unset,
  }) {
    return DreamElement(
      id: id ?? this.id,
      dreamId: dreamId ?? this.dreamId,
      type: type ?? this.type,
      label: label ?? this.label,
      detail: identical(detail, _unset) ? this.detail : detail as String?,
      salience: salience ?? this.salience,
      source: source ?? this.source,
      span: identical(span, _unset) ? this.span : span as (int, int)?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dream_id': dreamId,
    'type': type.databaseValue,
    'label': label,
    'detail': detail,
    'salience': salience.databaseValue,
    'source': source.databaseValue,
    'span': databaseIntRange(span),
  };

  factory DreamElement.fromJson(Map<String, dynamic> json) {
    return DreamElement(
      id: json['id'] as String,
      dreamId: json['dream_id'] as String,
      type: enumFromDatabase(json['type'], DreamElementType.values),
      label: json['label'] as String,
      detail: json['detail'] as String?,
      salience: enumFromDatabase(json['salience'], DreamElementSalience.values),
      source: enumFromDatabase(json['source'], DreamElementSource.values),
      span: jsonIntRange(json['span'], 'span'),
    );
  }
}
