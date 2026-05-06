import 'dart:io';

import 'package:fresh_graphql/fresh_graphql.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../../mobile_api.dart';

/// Default GraphQL client implementation with token refresh support.
final class IGraphQlImpl extends IGraphQl with RefreshTokenMixin {
  /// Creates a GraphQL client from [apiConfig].
  IGraphQlImpl({required ApiConfig apiConfig, http.Client? httpClient})
    : _apiConfig = apiConfig,
      _rawClient = httpClient ?? _createHttpClient(apiConfig) {
    _init();
  }

  final ApiConfig _apiConfig;
  final http.Client _rawClient;

  /// late variables
  late GraphQLClient _client;
  late CustomFreshLink<IBOAuth2Token> _freshLink;

  void _init() {
    _freshLink = CustomFreshLink.oAuth2(
      tokenStorage: InMemoryTokenStorage(),
      refreshToken: (p0, p1) async {
        final token = await updateRefreshToken();
        return IBOAuth2Token(
          accessToken: token?.accessToken ?? '',
          refreshToken: token?.refreshToken ?? '',
        );
      },
      shouldRefresh: (Response response) {
        return response.shouldRefresh;
      },
    );
    _client = GraphQLClient(
      link: Link.from([_freshLink, _httpLink()]),
      cache: GraphQLCache(),
    );
  }

  QueryOptions<Object?> _queryOptions(String path, {MapParam? params}) {
    return QueryOptions(
      document: gql(path),
      variables: params ?? <String, String>{},
      fetchPolicy: FetchPolicy.noCache,
    );
  }

  Future<void> _getHeaders() async {
    final accessToken =
        await _apiConfig.appCache?.read(CoreCacheKey.accessToken) ?? '';
    final refreshToken =
        await _apiConfig.appCache?.read(CoreCacheKey.refreshToken) ?? '';
    await _freshLink.setToken(
      accessToken.isEmpty
          ? null
          : IBOAuth2Token(accessToken: accessToken, refreshToken: refreshToken),
    );
    _client = _client.copyWith(
      link: Link.from([_freshLink, _httpLink(await defaultHeaders())]),
      cache: GraphQLCache(),
    );
  }

  HttpLink _httpLink([Map<String, String> defaultHeaders = const {}]) {
    return HttpLink(
      '${_apiConfig.apiUrl}',
      defaultHeaders: defaultHeaders,
      httpClient: _rawClient,
    );
  }

  Future<QueryResult<Object?>> _queryRequest({
    required String path,
    Map<String, dynamic>? variables,
    DurationEnum? timeout,
  }) {
    return _client
        .query(_queryOptions(path, params: variables))
        .timeout(timeout?.duration ?? DurationEnum.medium.duration);
  }

  @override
  Future<QueryResult<Object?>?> simpleQuery({required String path}) async {
    await _getHeaders();
    final result = await _client.query<dynamic>(
      _queryOptions(path, params: {'page': 0, 'limit': 20}),
    );
    return result;
  }

  @override
  Future<Result<R, E>> queryDetail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  }) async {
    return handleNetworkCall(() async {
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          errorResponseToJson,
        );
      }
      return request.responseQueryDetail<R, E>(
        field: field,
        fromJson: dataFromJson,
        keys: apiConfig.pageFieldKeys,
      );
    }, errorFromJson);
  }

  @override
  Future<Result<R, E>> queryMultiple<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    MapParam? params,
  }) async {
    return handleNetworkCall(() async {
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          errorResponseToJson,
        );
      }
      final response = request.responseMultipleQuery<R, E>(dataFromJson);
      if (response != null) return response;
      return Failure(
        errorFromJson(
          errorResponseToJson
              .copyWith(status: 503, reasonPhrase: 'Bad request')
              .toJson(),
        ),
      );
    }, errorFromJson);
  }

  @override
  Future<Result<R, E>> detail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
    DurationEnum? timeout,
  }) async {
    return handleNetworkCall(() async {
      await _getHeaders();

      final request = await _queryRequest(
        path: path,
        variables: params,
        timeout: timeout,
      );

      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          errorResponseToJson,
        );
      }
      return request.responseDetail<R, E>(dataFromJson, field);
    }, errorFromJson);
  }

  @override
  Future<Result<List<R>, E>> queryList<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  }) async {
    return handleNetworkCallList(() async {
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          errorResponseToJson,
        );
      }
      return request.responseList<R, E>(
        fromJson: dataFromJson,
        field: field,
        keys: apiConfig.pageFieldKeys,
      );
    }, errorFromJson);
  }

  @override
  Future<Result<List<R>, E>> list<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  }) async {
    return handleNetworkCallList(() async {
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          errorResponseToJson,
        );
      }
      return request.responseList<R, E>(
        fromJson: dataFromJson,
        field: field,
        keys: apiConfig.pageFieldKeys,
      );
    }, errorFromJson);
  }

  Failure<R, E> errorGraphQlResponse<R, E extends Exception>(
    ErrorFromJson<E> errorJson,
    QueryResult<Object?> request,
    IBaseErrorResponse errorData,
  ) {
    final result = switch (request.exception) {
      HttpLinkParserException(response: final response) =>
        _responseDecode<R, E>(response, errorJson),
      HttpLinkServerException(response: final response) =>
        _responseDecode<R, E>(response, errorJson),
      ServerException(parsedResponse: final response, statusCode: final code) =>
        _responseServerDecode<R, E>(response, code, errorJson, errorData),
      OperationException(
        graphqlErrors: final graphqlErrors,
        linkException: final linkException,
      ) =>
        _responseOperational<R, E>(
          errorData: errorData,
          errorJson: errorJson,
          graphErrors: graphqlErrors,
          linkException: linkException,
        ),
      _ => () {
        addLogger('${request.exception}');
        return Failure<R, E>(
          errorJson(
            errorData
                .copyWith(
                  status: HttpStatus.badRequest,
                  reasonPhrase: '${request.exception}',
                )
                .toJson(),
          ),
        );
      }(),
    };
    return result;
  }

  Failure<R, E> _responseDecode<R, E extends Exception>(
    http.Response response,
    ErrorFromJson<E> errorJson,
  ) {
    final mapData = CustomJsonDecoder.toJsonData(response.body);
    mapData['Status'] = response.statusCode;
    mapData['reasonPhrase'] = response.reasonPhrase;
    addLogger('${response.statusCode} ${response.reasonPhrase}');
    return Failure(errorJson(mapData));
  }

  Failure<R, E> _responseServerDecode<R, E extends Exception>(
    Response? response,
    int? statusCode,
    ErrorFromJson<E> errorJson,
    IBaseErrorResponse errorData,
  ) {
    final error = _firstGraphQlError(response?.errors);
    addLogger(error?.errorFullMessage);
    return Failure(
      errorJson(
        errorData
            .copyWith(
              status: statusCode ?? HttpStatus.internalServerError,
              errors: error,
            )
            .toJson(),
      ),
    );
  }

  Failure<R, E> _responseOperational<R, E extends Exception>({
    required ErrorFromJson<E> errorJson,
    required IBaseErrorResponse errorData,
    LinkException? linkException,
    List<GraphQLError>? graphErrors,
  }) {
    if (graphErrors != null &&
        graphErrors.isNotEmpty &&
        graphErrors.first.extensions != null) {
      final error = graphErrors.first;
      final errorMessage = '${error.extensions!['code']}';
      if (errorMessage.contains(ExceptionEnum.unauthenticated.value) ||
          errorMessage.contains(ExceptionEnum.unauthorized.value)) {
        return Failure(
          errorJson(
            errorData
                .copyWith(
                  reasonPhrase: error.message,
                  status: HttpStatus.unauthorized,
                  errors: error,
                )
                .toJson(),
          ),
        );
      }
    }
    if (linkException != null && linkException is ServerException) {
      final error = linkException;
      final graphQlError = _firstGraphQlError(error.parsedResponse?.errors);
      addLogger(graphQlError?.errorFullMessage);
      return Failure(
        errorJson(
          errorData
              .copyWith(
                errors: graphQlError,
                reasonPhrase: graphQlError?.message,
                status: error.statusCode,
              )
              .toJson(),
        ),
      );
    }
    final graphQlError = _firstGraphQlError(graphErrors);
    addLogger(
      graphQlError?.errorFullMessage ??
          linkException.toString().subStringLongString,
    );
    return Failure(
      errorJson(
        errorData
            .copyWith(
              errors: GraphQLError(message: '$graphErrors $linkException'),
              reasonPhrase: graphQlError?.message ?? '$linkException',
              status: HttpStatus.badRequest,
            )
            .toJson(),
      ),
    );
  }

  GraphQLError? _firstGraphQlError(List<GraphQLError>? errors) {
    if (errors == null || errors.isEmpty) return null;
    return errors.first;
  }

  @override
  ApiConfig get apiConfig => _apiConfig;
  @override
  http.Client get httpClient => _rawClient;

  @override
  IBaseErrorResponse get errorResponseToJson =>
      _apiConfig.errorResponseFactory();

  static http.Client _createHttpClient(ApiConfig apiConfig) {
    if (!apiConfig.allowBadCertificates) return http.Client();
    return IOClient(
      CustomHttpOverrides(bpHost: apiConfig.apiUrl.host).createHttpClient(null),
    );
  }
}
