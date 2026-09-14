Map<String, dynamic> jsonObject(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field must be a JSON object');
  }

  return value.map((key, nestedValue) {
    if (key is! String) {
      throw FormatException('$field contains a non-string key');
    }
    return MapEntry(key, nestedValue);
  });
}

Map<String, String> jsonStringMap(Object? value, String field) {
  final object = jsonObject(value, field);
  return object.map((key, nestedValue) {
    if (nestedValue is! String) {
      throw FormatException('$field.$key must be a string');
    }
    return MapEntry(key, nestedValue);
  });
}

Map<String, double> jsonDoubleMap(Object? value, String field) {
  final object = jsonObject(value, field);
  return object.map((key, nestedValue) {
    if (nestedValue is! num) {
      throw FormatException('$field.$key must be a number');
    }
    return MapEntry(key, nestedValue.toDouble());
  });
}

List<String> jsonStringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a JSON array');
  }

  return value
      .map((item) {
        if (item is! String) {
          throw FormatException('$field must contain only strings');
        }
        return item;
      })
      .toList(growable: false);
}

List<Map<String, dynamic>> jsonObjectList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a JSON array');
  }

  return [
    for (var index = 0; index < value.length; index++)
      jsonObject(value[index], '$field[$index]'),
  ];
}

int jsonInt(Object? value, String field) {
  if (value is! num || value != value.roundToDouble()) {
    throw FormatException('$field must be an integer');
  }
  return value.toInt();
}

double jsonDouble(Object? value, String field) {
  if (value is! num) {
    throw FormatException('$field must be a number');
  }
  return value.toDouble();
}

DateTime jsonDate(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be an ISO-8601 date');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw FormatException('$field must use YYYY-MM-DD');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String databaseDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-'
      '${twoDigits(value.month)}-${twoDigits(value.day)}';
}

DateTime jsonDateTime(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be an ISO-8601 timestamp');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$field must be an ISO-8601 timestamp');
  }
  return parsed;
}

(int, int)? jsonIntRange(Object? value, String field) {
  if (value == null) {
    return null;
  }

  if (value is List && value.length == 2) {
    return (jsonInt(value[0], '$field[0]'), jsonInt(value[1], '$field[1]'));
  }

  if (value is String) {
    final match = RegExp(r'^\[(-?\d+),(-?\d+)\)$').firstMatch(value);
    if (match != null) {
      return (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }
  }

  throw FormatException('$field must be an int4range or a two-item array');
}

String? databaseIntRange((int, int)? value) {
  if (value == null) {
    return null;
  }
  return '[${value.$1},${value.$2})';
}
