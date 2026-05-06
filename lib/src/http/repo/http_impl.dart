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
    final token = await updateRefreshToken();
    if (token != null && token.accessToken.isNotEmpty) {
      req.headers[HttpHeadersConst.authorization] =
          '${HttpHeadersConst.bearer} ${token.accessToken}';
    } else {
      req.headers.remove(HttpHeadersConst.authorization);
    }
    req.headers[HttpHeadersConst.marketplace] = _apiConfig.marketplaceValue;
    final versionCode = await _apiConfig.appCache?.read(
      CoreCacheKey.appVersion,
    );
    if (versionCode != null && versionCode.isNotEmpty) {
      req.headers[HttpHeadersConst.userAgent] =
          '${apiConfig.userAgentValue}:$versionCode';
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
    return handleNetworkCall(() async {
      final response = await _customHttpRequest(
        path,
        requestType: requestType,
        headerParams: params,
        query: query,
        body: body,
      );
      return customHttpResponse<S, E>(dataFromJson, errorFromJson, response);
    }, errorFromJson);
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
      );
    }, errorFromJson);
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
    if (responseBody.statusCode == 200 || responseBody.statusCode == 201) {
      return Success(
        successFromJson(CustomJsonDecoder.toJsonData(responseBody.body)),
      );
    }
    await addLogger(responseBody.reasonPhrase);
    return Failure(
      errorFromJson(CustomJsonDecoder.toJsonData(responseBody.body)),
    );
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
            errorResponseToJson
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
            errorResponseToJson
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
