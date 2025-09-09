import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_api/src/utils/types/api_config.dart';

import '../../../mobile_api.dart';
final class HttpHeadersConst {
  HttpHeadersConst._();
  static const authorization = 'Authorization';
  static const bearer = 'Bearer';
  static const marketplace = 'marketplace';
  static const userAgent = 'User-Agent';
  static const contentTypeImage = 'image';
  static const contentTypeJpeg = 'jpeg';
  static const contentTypeJson = 'application/json; charset=utf-8';
  static const accept = 'Accept';
  static const acceptLanguage = 'Accept-Language';
}

mixin RefreshTokenMixin {
  ApiConfig get apiConfig;
  ErrorResponse get errorResponseToJson;
 

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

  Future<Result<T, E>> handleNetworkCall<T, E extends Exception>(
    Future<Result<T, E>> Function() call,
    ErrorFromJson<E> errorFromJson,
  ) async {
    try {
      if (apiConfig.checkNetwork != null &&
          !await apiConfig.checkNetwork!.isConnected) {
        return checkNetworkStatus<T, E>(errorFromJson: errorFromJson);
      }
      return await call();
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return onExceptionError(e, errorFromJson, errorResponseToJson);
    }
  }

  Future<Result<List<T>, E>> handleNetworkCallList<T, E extends Exception>(
    Future<Result<List<T>, E>> Function() call,
    ErrorFromJson<E> errorFromJson,
  ) async {
    try {
      if (apiConfig.checkNetwork != null &&
          !await apiConfig.checkNetwork!.isConnected) {
        return checkNetworkStatus<List<T>, E>(errorFromJson: errorFromJson);
      }
      return await call();
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return onExceptionError(e, errorFromJson, errorResponseToJson);
    }
  }

  Future<IBOAuth2Token?> updateRefreshToken(Uri url) async {
    final refreshToken =
        await apiConfig.appCache?.read(CacheEnum.refresh) ??
        'B268B7F278F295EC7DF8221B53959D6D6A83FF8779FDC475CAB0BA0B75592CA5';

    if (refreshToken.isNotEmpty) {
      final response = await http.Client().post(
        url.replace(path: 'Auths/MobileUser/RefreshToken'),
        headers: await defaultHeaders(),
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == HttpStatus.ok) {
        final dynamic body = await jsonDecode(response.body);
        if (body is! Map) return null;
        final token = IBOAuth2Token.fromJson(
          body['data'] as Map<String, dynamic>,
        );
        await apiConfig.appCache?.saveAll(
          CacheEnum.saveToken(token.accessToken, token.refreshToken),
        );
        return token;
      }
    }
    return null;
  }
  Future<Map<String, String>> defaultHeaders() async {
    final token = await apiConfig.appCache?.read(CacheEnum.token) ?? '';
    final lan = await apiConfig.appCache?.read(CacheEnum.lang) ?? 'ru';
    final versionCode = await apiConfig.appCache?.read(CacheEnum.versionCode);
    return {
      HttpHeaders.contentTypeHeader: HttpHeadersConst.contentTypeJson,
      HttpHeaders.acceptHeader: HttpHeadersConst.contentTypeJson,
      HttpHeadersConst.authorization: '${HttpHeadersConst.bearer} $token',
      HttpHeadersConst.marketplace: apiConfig.marketplaceValue,
      HttpHeadersConst.acceptLanguage: lan,
      if (versionCode != null && versionCode.isNotEmpty)
        HttpHeadersConst.userAgent:
            '${apiConfig.userAgentValue}:$versionCode',
    };
  }
 

  Future<void> addLogger(String? loggerMessage) async {
    if (loggerMessage == null) return;
    await http.Client().post(
      apiConfig.apiUrl.replace(path: 'loggers/api/Log/AddError'),
      body: jsonEncode({'description': loggerMessage}),
      headers: await defaultHeaders(),
    );
  }

  Failure<T, E> onExceptionError<T, E extends Exception>(
    Object e,
    FromJsonFun<E> errorFromJson,
    ErrorResponse errorData,
  ) {
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
