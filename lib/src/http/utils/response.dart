import 'dart:convert';

final class CustomJsonDecoder {
  CustomJsonDecoder._();
  static Map<String, dynamic> toJsonData(String body) {
    dynamic data = jsonDecode(body);
    if (data is! Map) {
      data = jsonDecode(data as String);
    }

    return data as Map<String, dynamic>;
  }

  static Map<String, dynamic>? toJsonDataType({
    required String data,
    required String body,
  }) {
    if (body.isEmpty) return null;
    dynamic result = jsonDecode(body);
    if (result is! Map) {
      result = jsonDecode(result as String);
    }
    if (result is! Map) return null;
    return result[data] as Map<String, dynamic>;
  }
}
