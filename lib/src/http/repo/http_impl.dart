import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../mobile_api.dart';

final class IHttpImpl extends IHttp with RefreshTokenMixin {
  IHttpImpl({required ApiConfig apiConfig}) : _apiConfig = apiConfig {
    _init();
  }

  final ApiConfig _apiConfig;

  late Client _client;

  void _init() {
    HttpOverrides.global = CustomHttpOverrides(bpHost: _apiConfig.apiUrl.host);
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
    final token = await updateRefreshToken();
    req.headers[HttpHeadersConst.authorization] =
        '${HttpHeadersConst.bearer} ${token?.accessToken}';
    req.headers[HttpHeadersConst.marketplace] = _apiConfig.marketplaceValue;
    req.headers[HttpHeadersConst.userAgent] =
        '${apiConfig.userAgentValue}:${await _apiConfig.appCache?.read(CoreCacheKey.appVersion)}';

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
  Future<Result<S, E>> postIntegra<S, E extends Exception>({
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    MapParam? params,
    String? query,
    Uri? url,
    String? path,
    Map<String, dynamic>? body,
  }) async {
    final headers = await defaultHeaders();
    dynamic requestBody = body;
    Map<String, String> modHeaders = Map.from(headers);
    if (body != null) {
      requestBody = jsonEncode(body);
      modHeaders['Content-Type'] = 'application/json';
    }
    final response = await http.post(
      url ?? _apiConfig.apiUrl.replace(path: path, queryParameters: params),
      headers: modHeaders,
      body: requestBody,
    );
    final decodeJson =
        CustomJsonDecoder.decode(response.body) as Map<String, dynamic>?;
    final statusCode = decodeJson != null && decodeJson.containsKey('Code')
        ? decodeJson['Code']
        : null;
    if (statusCode == "1") {
      return Success(dataFromJson(decodeJson ?? {}));
    }
    return Failure(errorFromJson(decodeJson ?? {}));
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
    final uri = _apiConfig.apiUrl.replace(path: path, queryParameters: params);
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
        _apiConfig.apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: await defaultHeaders(),
      ),
      RequestType.post => _client.post(
        _apiConfig.apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.put => _client.put(
        _apiConfig.apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.patch => _client.patch(
        _apiConfig.apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
        headers: await defaultHeaders(),
        body: jsonEncode(body),
      ),
      RequestType.delete => _client.delete(
        _apiConfig.apiUrl.replace(
          path: path,
          queryParameters: headerParams,
          query: query,
        ),
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
  http.Client get httpClient => _client;
}
