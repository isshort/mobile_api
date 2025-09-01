import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../mobile_api.dart';

final class IHttpImpl extends IHttp with RefreshTokenMixin {
  IHttpImpl({
    required Uri apiUrl,
    CheckNetwork? checkNetwork,
    ICacheRepo? appCache,
  }) : _apiUrl = apiUrl,
       _appCache = appCache,
       _checkNetwork = checkNetwork {
    _init();
  }
  final Uri _apiUrl;
  final CheckNetwork? _checkNetwork;
  final ICacheRepo? _appCache;

  late Client _client;
  late ErrorResponse _errorResponseToJson;

  void _init() {
    _errorResponseToJson = ErrorResponse();
    HttpOverrides.global = CustomHttpOverrides(bpHost: _apiUrl.host);
    final retryClient = RetryClient(
      Client(),
      retries: 1,
      when: (response) => response.statusCode == HttpStatus.unauthorized,
      onRetry: _onRetry,
    );

    _client = retryClient;
  }

  FutureOr<void> _onRetry(
    BaseRequest req,
    BaseResponse? res,
    dynamic retryCount,
  ) async {
    final token = await updateRefreshToken(_apiUrl);
    req.headers['Authorization'] = 'Bearer ${token?.accessToken}';
    req.headers['marketplace'] = 'PN';
    req.headers['User-Agent'] =
        'BpApp:${await _appCache?.read(CacheEnum.versionCode)}';

    return;
  }

  @override
  Future<SimpleResult> get(
    String path, {
    MapParam? params,
    Map<String, String>? headers,
  }) async {
    final result = await http.get(Uri.parse(path), headers: headers);
    if (result.statusCode != HttpStatus.ok) {
      return SimpleResult(
        result.statusCode,
        result.reasonPhrase ?? result.body,
      );
    }
    return SimpleResult(result.statusCode, result.body);
  }

  @override
  Future<Result<S, E>> baseMethod<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<S, E>(errorFromJson: errorFromJson);
      }

      return _customRequest(
        path,
        requestType: requestType,
        headerParams: params,
        query: query,
        body: body,
      ).then((value) => customHttpResponse(dataFromJson, errorFromJson, value));
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return onExceptionError<S, E>(e, errorFromJson, _errorResponseToJson);
    }
  }

  @override
  Future<Result<S, E>> baseMethodType<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  }) async {
    if (_checkNetwork != null && !await _checkNetwork.isConnected) {
      return checkNetworkStatus<S, E>(errorFromJson: errorFromJson);
    }
    try {
      return _customRequest(
        path,
        requestType: requestType,
        headerParams: params,
        query: query,
        body: body,
      ).then(
        (value) => customHttpResponseType(
          dataFromJson: dataFromJson,
          exception: errorFromJson,
          response: value,
        ),
      );
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return onExceptionError<S, E>(e, errorFromJson, _errorResponseToJson);
    }
  }

  @override
  Future<SimpleResult> uploadImage({
    required String filePath,
    required String fileLabel,
    required String path,
    String? method,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_checkNetwork != null && !await _checkNetwork.isConnected) {
      return SimpleResult(
        HttpStatus.gatewayTimeout,
        AppErrorMessage.noInternet,
      );
    }
    try {
      final request =
          MultipartRequest(
              method ?? RequestType.post.value,
              _apiUrl.replace(path: path, queryParameters: queryParameters),
            )
            ..headers[HttpHeaders.authorizationHeader] =
                'Bearer ${await _appCache?.read(CacheEnum.token)}'
            ..headers['marketplace'] = 'PN'
            ..files.add(
              await MultipartFile.fromPath(
                fileLabel,
                filePath,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
      // log('${_appCache?.read(CacheEnum.token)}');
      final result = await request.send().timeout(
        DurationEnum.extraLong.duration,
      );
      if (result.statusCode != HttpStatus.ok) {
        await addLogger(result.errorFullMessageHttpStream);
      }
      return _imageResponse(result);
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return SimpleResult(HttpStatus.internalServerError, e.toString());
    }
  }

  @override
  Future<SimpleResult> multipleImages({
    required String path,
    required Map<String, String> images,
    String? method,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_checkNetwork != null && !await _checkNetwork.isConnected) {
      return SimpleResult(
        HttpStatus.gatewayTimeout,
        AppErrorMessage.noInternet,
      );
    }
    try {
      final request =
          MultipartRequest(
              method ?? RequestType.post.value,
              _apiUrl.replace(path: path, queryParameters: queryParameters),
            )
            ..headers[HttpHeaders.authorizationHeader] =
                'Bearer ${await _appCache?.read(CacheEnum.token)}'
            ..headers['marketplace'] = 'PN';
      images.forEach((key, value) async {
        request.files.add(
          await MultipartFile.fromPath(
            key,
            value,
            filename: key,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      });

      final result = await request.send().timeout(
        DurationEnum.extraLong.duration,
      );
      if (result.statusCode != HttpStatus.ok) {
        await addLogger(result.errorFullMessageHttpStream);
      }
      return _imageResponse(result);
    } catch (e) {
      await addLogger(e.toString().subStringLongString);
      return SimpleResult(HttpStatus.internalServerError, e.toString());
    }
  }

  @override
  Future<Result<S, E>?> multipart<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> successFromJson,
    required ErrorFromJson<E> errorFromJson,
    required Map<String, String> body,
    Map<String, String>? files,
    Map<String, dynamic>? params,
    RequestType? httpMethod,
  }) async {
    final request =
        MultipartRequest(
            httpMethod?.value ?? RequestType.post.value,
            _apiUrl.replace(path: path),
          )
          ..fields.addAll(body)
          ..headers.addAll(getHeaders);

    if (files != null && files.isNotEmpty) {
      for (final file in files.entries) {
        final fromPath = await MultipartFile.fromPath(
          file.key,
          file.value,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(fromPath);
      }
    }

    final response = await request.send();
    String? responseBody;
    final stream = response.stream.transform(utf8.decoder);
    await for (final chunk in stream) {
      responseBody = chunk;
    }
    if (responseBody == null) return null;
    if (response.statusCode == HttpStatus.ok) {
      return Success(
        successFromJson(CustomJsonDecoder.toJsonData(responseBody)),
      );
    }
    await addLogger(responseBody);
    return Failure(errorFromJson(CustomJsonDecoder.toJsonData(responseBody)));
  }

  SimpleResult _imageResponse(http.StreamedResponse result) {
    return SimpleResult(
      result.statusCode,
      result.reasonPhrase ?? '${result.request}',
    );
  }

  Future<Response> _customRequest(
    String path, {
    required RequestType requestType,
    Map<String, dynamic>? headerParams,
    Map<String, dynamic>? body,
    String? query,
  }) {
    final request = switch (requestType) {
      RequestType.get => _client.get(
        _apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: getHeaders,
      ),
      RequestType.post => _client.post(
        _apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: getHeaders,
        body: jsonEncode(body),
      ),
      RequestType.put => _client.put(
        _apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: getHeaders,
        body: jsonEncode(body),
      ),
      RequestType.patch => _client.patch(
        _apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: getHeaders,
        body: jsonEncode(body),
      ),
      RequestType.delete => _client.delete(
        _apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: getHeaders,
      ),
    };

    return request.timeout(DurationEnum.medium.duration);
  }

  Result<T, E> customHttpResponseType<T, E extends Exception>({
    required FromJsonFun<T> dataFromJson,
    required ErrorFromJson<E> exception,
    required http.Response response,
    String type = 'data',
  }) {
    final result = switch (response.statusCode) {
      HttpStatus.ok ||
      HttpStatus.created when response.body.isNotEmpty => Success<T, E>(
        dataFromJson(
          CustomJsonDecoder.toJsonDataType(body: response.body, data: type)!,
        ),
      ),
      _ => () {
        addLogger(response.errorFullMessageHttp);
        if (response.body.isNotEmpty) {
          return Failure<T, E>(
            exception(CustomJsonDecoder.toJsonData(response.body)),
          );
        }
        return Failure<T, E>(
          exception(
            _errorResponseToJson
                .copyWith(
                  status: response.statusCode,
                  reasonPhrase: response.reasonPhrase,
                  errors: response.request,
                )
                .toJson(),
          ),
        );
      }(),
    };
    return result;
  }

  Result<T, E> customHttpResponse<T, E extends Exception>(
    FromJsonFun<T> dataFromJson,
    ErrorFromJson<E> exception,
    http.Response response,
  ) {
    final statusResult = switch (response.statusCode) {
      HttpStatus.ok || HttpStatus.created => Success<T, E>(
        dataFromJson(CustomJsonDecoder.toJsonData(response.body)),
      ),
      _ => () {
        addLogger(response.errorFullMessageHttp);
        if (response.body.isNotEmpty) {
          return Failure<T, E>(
            exception(CustomJsonDecoder.toJsonData(response.body)),
          );
        }
        return Failure<T, E>(
          exception(
            _errorResponseToJson
                .copyWith(
                  status: response.statusCode,
                  reasonPhrase: response.reasonPhrase,
                  errors: response.request,
                )
                .toJson(),
          ),
        );
      }(),
    };
    return statusResult;
  }

  @override
  ICacheRepo? get cache => _appCache;

  @override
  ErrorResponse get errorResponseToJson => _errorResponseToJson;

  @override
  Uri get url => _apiUrl;
}
