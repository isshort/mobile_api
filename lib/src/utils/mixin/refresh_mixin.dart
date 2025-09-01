import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../mobile_api.dart';

mixin RefreshTokenMixin {
  ICacheRepo? get cache;
  ErrorResponse get errorResponseToJson;
  Uri get url;

  Future<IBOAuth2Token?> updateRefreshToken(Uri url) async {
    final refreshToken =
        await cache?.read(CacheEnum.refresh) ??
        'B268B7F278F295EC7DF8221B53959D6D6A83FF8779FDC475CAB0BA0B75592CA5';

    if (refreshToken.isNotEmpty) {
      final response = await http.Client().post(
        url.replace(path: 'Auths/MobileUser/RefreshToken'),
        headers: getHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == HttpStatus.ok) {
        final dynamic body = await jsonDecode(response.body);
        if (body is! Map) return null;
        final token = IBOAuth2Token.fromJson(
          body['data'] as Map<String, dynamic>,
        );
        await cache?.saveAll(
          CacheEnum.saveToken(token.accessToken, token.refreshToken),
        );
        return token;
      }
    }
    return null;
  }

  Map<String, String> get getHeaders => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    'marketplace': 'PN',
    HttpHeaders.authorizationHeader: 'Bearer ${cache?.read(CacheEnum.token)}',
  };
  Future<Failure<R, E>> checkNetworkStatus<R, E extends Exception>({
    required FromJsonFun<E> errorFromJson,
  }) async => Failure(
    errorFromJson(
      errorResponseToJson
          .copyWith(
            status: HttpStatus.gatewayTimeout,
            reasonPhrase: 'Нет подключения к Интернету',
          )
          .toJson(),
    ),
  );

  Future<void> addLogger(String? loggerMessage) async {
    if (loggerMessage == null) return;
    await http.Client().post(
      url.replace(path: 'loggers/api/Log/AddError'),
      body: jsonEncode({'description': loggerMessage}),
      headers: getHeaders,
    );
  }

  Failure<T, E> onExceptionError<T, E extends Exception>(
    Object e,
    FromJsonFun<E> errorFromJson,
    ErrorResponse errorData,
  ) {
    addLogger(e.toString().subStringLongString);
    if (e is SocketException) {
      return Failure(
        errorFromJson(
          errorData
              .copyWith(
                status: HttpStatus.serviceUnavailable,
                reasonPhrase: '$e',
              )
              .toJson(),
        ),
      );
    }
    return Failure(
      errorFromJson(
        errorData
            .copyWith(status: HttpStatus.badRequest, reasonPhrase: '$e')
            .toJson(),
      ),
    );
  }
}
