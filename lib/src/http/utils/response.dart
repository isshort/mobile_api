import 'dart:convert';

final class CustomJsonDecoder {
  CustomJsonDecoder._();

  static dynamic decode(String body) {
    return _decodeLoose(body);
  }

  static Map<String, dynamic> toJsonData(String body) {
    dynamic decoded = _decodeLoose(body);

    if (decoded is Map<String, dynamic>) return decoded;

    if (decoded is List) {
      // List of maps -> pick first if single, else wrap.
      if (decoded.isEmpty) return <String, dynamic>{};
      if (decoded.length == 1 && decoded.first is Map<String, dynamic>) {
        return decoded.first as Map<String, dynamic>;
      }
      // Wrap list so caller still receives a Map.
      return {'items': decoded};
    }

    // Primitive fallback
    return {'value': decoded};
  }

  static Map<String, dynamic>? toJsonDataType({
    required String data,
    required String body,
  }) {
    if (body.isEmpty) return null;
    final root = _decodeLoose(body);
    if (root is Map<String, dynamic>) {
      final v = root[data];
      if (v is Map<String, dynamic>) return v;
      if (v is String) {
        final inner = _decodeLoose(v);
        return inner is Map<String, dynamic> ? inner : null;
      }
      return null;
    }
    return null;
  }

  /// Tries to decode JSON; also handles nested JSON-in-string up to a few levels.
  static dynamic _decodeLoose(dynamic input, {int depth = 0}) {
    if (depth > 3) return input;
    if (input is String) {
      try {
        final d = jsonDecode(input);
        // If result is a JSON string again, recurse.
        if (d is String) {
          return _decodeLoose(d, depth: depth + 1);
        }
        return d;
      } catch (_) {
        return input; // Not JSON
      }
    }
    return input;
  }
}
