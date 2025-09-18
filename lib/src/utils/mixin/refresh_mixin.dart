import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  IBaseErrorResponse get errorResponseToJson;

  http.Client get httpClient;

  String get refreshTokenPath => apiConfig.refreshTokenPath;
  String get loggerPath => apiConfig.loggerPath;

  /// Concurrency guard so only one refresh runs at a time.
  static Completer<IBOAuth2Token?>? _refreshCompleter;

  Future<Failure<R, E>> checkNetworkStatus<R, E extends Exception>({
    required FromJsonFun<E> errorFromJson,
  }) async => Failure(
    errorFromJson(
      errorResponseToJson
          .copyWith(
            status: HttpStatus.gatewayTimeout,
            reasonPhrase: 'No internet connection',
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

  /// Build refresh request body (override if backend differs).
  Map<String, dynamic> buildRefreshBody(String refreshToken) => {
    'refreshToken': refreshToken,
  };

  /// Called after new tokens stored (override for extra side-effects).
  Future<void> onTokensUpdated(IBOAuth2Token token) async {}

  /// Override for custom logger payload shaping.
  Map<String, dynamic> buildLoggerPayload(String message) => {
    'description': message,
  };
  Future<IBOAuth2Token?> updateRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<IBOAuth2Token?>();

    try {
      final refreshToken =
          await apiConfig.appCache?.read(CoreCacheKey.refreshToken) ??
          '+RGAbP4X+BlEgT3MnAVdweM3/dJCnPR3nlZwJoWqp29DRtbtxuqLjKuwFqDcxyozpV2VtoEY6lIGrVUkOQEW7w==';
      if (refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }
      final rawPath = refreshTokenPath.trim();
      final normalized = rawPath.startsWith('/')
          ? rawPath.substring(1)
          : rawPath;
      final uri = (apiConfig.apiUrl).replace(path: normalized);

      final response = await httpClient.post(
        uri,
        headers: await defaultHeaders(),
        body: jsonEncode(buildRefreshBody(refreshToken)),
      );
      if (response.statusCode != HttpStatus.ok) {
        await addLogger(
          'Refresh failed: ${response.statusCode} ${response.body}',
        );
        _refreshCompleter!.complete(null);
        return null;
      }

      final dynamic body = jsonDecode(response.body);
      if (body is! Map) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final tokenJson = body['data'];
      if (tokenJson is! Map<String, dynamic>) {
        _refreshCompleter!.complete(null);
        return null;
      }

      final token = IBOAuth2Token.fromJson(tokenJson);

      if (token.accessToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      await apiConfig.appCache?.saveAll(
        CacheKeyBundle.tokenPair(
          access: token.accessToken,
          refresh: token.refreshToken,
        ),
      );
      await onTokensUpdated(token);
      _refreshCompleter!.complete(token);
      return token;
    } catch (e) {
      await addLogger('Refresh exception: $e');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Map<String, String>> defaultHeaders() async {
    final token =
        await apiConfig.appCache?.read(CoreCacheKey.accessToken) ?? '';
    final lan = await apiConfig.appCache?.read(CoreCacheKey.language) ?? 'ru';
    final versionCode = await apiConfig.appCache?.read(CoreCacheKey.appVersion);

    return {
      HttpHeaders.contentTypeHeader: HttpHeadersConst.contentTypeJson,
      HttpHeaders.acceptHeader: HttpHeadersConst.contentTypeJson,
      HttpHeadersConst.authorization: '${HttpHeadersConst.bearer} $token',
      HttpHeadersConst.marketplace: apiConfig.marketplaceValue,
      HttpHeadersConst.acceptLanguage: lan,
      if (versionCode != null && versionCode.isNotEmpty)
        HttpHeadersConst.userAgent: '${apiConfig.userAgentValue}:$versionCode',
    };
  }

  Future<void> addLogger(String? loggerMessage) async {
    if (loggerMessage == null || loggerMessage.isEmpty) return;
    final raw = loggerPath.trim();
    if (raw.isEmpty) return; // logging disabled if path blank
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    final uri = apiConfig.apiUrl.replace(path: path);
    try {
      await httpClient.post(
        uri,
        body: jsonEncode(buildLoggerPayload(loggerMessage)),
        headers: await defaultHeaders(),
      );
    } catch (_) {
      // Intentionally swallow logging errors.
    }
  }


  Failure<T, E> onExceptionError<T, E extends Exception>(
    Object e,
    FromJsonFun<E> errorFromJson,
    IBaseErrorResponse errorData,
  ) {
    final status = e is SocketException
        ? HttpStatus.serviceUnavailable
        : HttpStatus.badRequest;
    return Failure(
      errorFromJson(
        errorData.copyWith(status: status, reasonPhrase: '$e').toJson(),
      ),
    );
  }
}
