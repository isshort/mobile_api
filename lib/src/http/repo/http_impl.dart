import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

import '../../../mobile_api.dart';

/// Default REST client implementation with refresh retry support.
final class IHttpImpl extends IHttp with RefreshTokenMixin {
  /// Creates a REST client from [apiConfig].
  IHttpImpl({required ApiConfig apiConfig, http.Client? httpClient})
    : _apiConfig = apiConfig,
      _baseClient = httpClient {
    _init();
  }

  final ApiConfig _apiConfig;
  http.Client? _baseClient;

  late Client _client;

  void _init() {
    _baseClient ??= _apiConfig.allowBadCertificates
        ? IOClient(
            CustomHttpOverrides(
              bpHost: _apiConfig.apiUrl.host,
            ).createHttpClient(null),
          )
        : Client();
    final retryClient = RetryClient(
      _baseClient!,
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
    req.headers.addAll(_apiConfig.headers);
    final token = await updateRefreshToken();
    if (token != null && token.accessToken.isNotEmpty) {
      req.headers[HttpHeadersConst.authorization] =
          '${HttpHeadersConst.bearer} ${token.accessToken}';
    } else {
      req.headers.remove(HttpHeadersConst.authorization);
    }
    final versionCode = await _apiConfig.appCache?.read(
      CoreCacheKey.appVersion,
    );
    final userAgent = _apiConfig.headers[HttpHeadersConst.userAgent] ?? '';
    if (userAgent.isNotEmpty && versionCode != null && versionCode.isNotEmpty) {
      req.headers[HttpHeadersConst.userAgent] = '$userAgent:$versionCode';
    }

    return;
  }

  @override
  Future<SimpleResult> get(
    String path, {
    MapParam? params,
    Map<String, String>? headers,
  }) async {
    final requestHeaders = await defaultHeaders();
    if (headers != null) requestHeaders.addAll(headers);
    final result = await _client.get(
      _buildUri(path, params: params),
      headers: requestHeaders,
    );
    if (!_isSuccessStatus(result.statusCode)) {
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
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  }) async {
    return handleNetworkCall(() async {
      final response = await _customHttpRequest(
        path,
        requestType: requestType,
        headerParams: params,
        query: query,
        body: body,
      );
      return customHttpResponse<S, E>(
        dataFromJson,
        errorFromJson,
        response,
        emptySuccessBuilder: emptySuccessBuilder,
      );
    }, errorFromJson);
  }

  @override
  Future<Result<S, E>> baseMethodType<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  }) async {
    return handleNetworkCall(() async {
      final response = await _customHttpRequest(
        path,
        requestType: requestType,
        headerParams: params,
        query: query,
        body: body,
      );
      return customHttpResponseType<S, E>(
        dataFromJson: dataFromJson,
        exception: errorFromJson,
        response: response,
        emptySuccessBuilder: emptySuccessBuilder,
      );
    }, errorFromJson);
  }

  @override
  Future<Result<S, E>?> multipart<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> successFromJson,
    required ErrorFromJson<E> errorFromJson,
    required Map<String, String> body,
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    Map<String, String>? files,
    Map<String, dynamic>? params,
    RequestType? httpMethod,
  }) async {
    final uri = _buildUri(path, params: params);
    final request = await _createMultipartRequest(
      httpMethod?.value ?? RequestType.post.value,
      uri,

      fields: body,
      files: files != null
          ? {
              for (final entry in files.entries)
                entry.key: await MultipartFile.fromPath(
                  entry.key,
                  entry.value,
                  contentType: MediaType(
                    HttpHeadersConst.contentTypeImage,
                    HttpHeadersConst.contentTypeJpeg,
                  ),
                ),
            }
          : null,
    );
    final response = await request.send();

    final responseBody = await http.Response.fromStream(response);
    if (_isSuccessStatus(responseBody.statusCode)) {
      if (responseBody.body.isEmpty) {
        return _emptySuccessResponse(
          responseBody,
          errorFromJson,
          emptySuccessBuilder,
        );
      }
      return Success(
        successFromJson(CustomJsonDecoder.toJsonData(responseBody.body)),
        statusCode: responseBody.statusCode,
      );
    }
    await addLogger(responseBody.reasonPhrase);
    return _failureResponse(responseBody, errorFromJson);
  }

  Future<MultipartRequest> _createMultipartRequest(
    String method,
    Uri uri, {
    Map<String, String>? fields,
    Map<String, MultipartFile>? files,
  }) async {
    final request = MultipartRequest(method, uri)
      ..headers.addAll(await defaultHeaders());
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files.values);
    return request;
  }

  Future<Response> _customHttpRequest(
    String path, {
    required RequestType requestType,
    Map<String, dynamic>? headerParams,
    Map<String, dynamic>? body,
    String? query,
  }) async {
    final request = switch (requestType) {
      RequestType.get => _client.get(
        _buildUri(path, params: headerParams, query: query),
        headers: await defaultHeaders(),
      ),
      RequestType.post => _client.post(
        _buildUri(path, params: headerParams, query: query),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.put => _client.put(
        _buildUri(path, params: headerParams, query: query),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.patch => _client.patch(
        _buildUri(path, params: headerParams, query: query),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.delete => _client.delete(
        _buildUri(path, params: headerParams, query: query),
        headers: await defaultHeaders(),
      ),
    };

    return request.timeout(DurationEnum.medium.duration);
  }

  Result<T, E> customHttpResponseType<T, E extends Exception>({
    required FromJsonFun<T> dataFromJson,
    required ErrorFromJson<E> exception,
    required http.Response response,
    String type = 'data',
    EmptySuccessBuilder<T>? emptySuccessBuilder,
  }) {
    if (_isSuccessStatus(response.statusCode)) {
      if (response.body.isEmpty) {
        return _emptySuccessResponse(response, exception, emptySuccessBuilder);
      }
      return Success<T, E>(
        dataFromJson(
          CustomJsonDecoder.toJsonDataType(body: response.body, data: type)!,
        ),
        statusCode: response.statusCode,
      );
    }
    addLogger(response.errorFullMessageHttp);
    return _failureResponse(response, exception);
  }

  Result<T, E> customHttpResponse<T, E extends Exception>(
    FromJsonFun<T> dataFromJson,
    ErrorFromJson<E> exception,
    http.Response response, {
    EmptySuccessBuilder<T>? emptySuccessBuilder,
  }) {
    if (_isSuccessStatus(response.statusCode)) {
      if (response.body.isEmpty) {
        return _emptySuccessResponse(response, exception, emptySuccessBuilder);
      }
      return Success<T, E>(
        dataFromJson(CustomJsonDecoder.toJsonData(response.body)),
        statusCode: response.statusCode,
      );
    }
    addLogger(response.errorFullMessageHttp);
    return _failureResponse(response, exception);
  }

  bool _isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  Result<T, E> _emptySuccessResponse<T, E extends Exception>(
    http.Response response,
    ErrorFromJson<E> exception,
    EmptySuccessBuilder<T>? emptySuccessBuilder,
  ) {
    if (emptySuccessBuilder != null) {
      return Success<T, E>(
        emptySuccessBuilder(response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return _failureResponse(
      response,
      exception,
      reasonPhrase:
          'Successful response has no body. Provide emptySuccessBuilder to map status ${response.statusCode}.',
    );
  }

  Failure<T, E> _failureResponse<T, E extends Exception>(
    http.Response response,
    ErrorFromJson<E> exception, {
    String? reasonPhrase,
  }) {
    if (response.body.isNotEmpty) {
      return Failure<T, E>(
        exception(CustomJsonDecoder.toJsonData(response.body)),
      );
    }
    return Failure<T, E>(
      exception(
        errorResponseToJson
            .copyWith(
              status: response.statusCode,
              reasonPhrase: reasonPhrase ?? response.reasonPhrase,
              errors: response.request,
            )
            .toJson(),
      ),
    );
  }

  @override
  IBaseErrorResponse get errorResponseToJson =>
      _apiConfig.errorResponseFactory();

  @override
  ApiConfig get apiConfig => _apiConfig;
  @override
  http.Client get httpClient => _baseClient ?? _client;

  Uri _buildUri(String path, {Map<String, dynamic>? params, String? query}) {
    final parsed = Uri.tryParse(path);
    final uri = parsed != null && parsed.hasScheme
        ? parsed
        : _apiConfig.apiUrl.replace(path: path);
    if (query != null) return uri.replace(query: query);
    return uri.replace(queryParameters: params);
  }
}
