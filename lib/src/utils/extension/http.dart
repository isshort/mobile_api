import 'package:http/http.dart' as http;
import 'package:mobile_api/src/src.dart';

extension CustomHttpResponseExtension on http.Response {
  String get errorFullMessageHttp {
    final errorMsg =
        'Status Code:$statusCode,ReasonPhrase :$reasonPhrase , error :$request';
    return errorMsg.subStringLongString;
  }
}

extension StreamedResponseExtension on http.StreamedResponse {
  String get errorFullMessageHttpStream {
    final errorMsg =
        'Status Code:$statusCode,ReasonPhrase :$reasonPhrase , error :$request';
    return errorMsg.subStringLongString;
  }
}
