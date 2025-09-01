import 'dart:convert';
import 'dart:io';

import 'package:fresh_graphql/fresh_graphql.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;

import '../../../mobile_api.dart';

final class IGraphQlImpl extends IGraphQl with RefreshTokenMixin {
  IGraphQlImpl({
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

  /// late variables
  late GraphQLClient _client;
  late CustomFreshLink<IBOAuth2Token> _freshLink;
  final _errorResponseToJson = ErrorResponse();

  @override
  ErrorResponse get errorResponseToJson => _errorResponseToJson;

  @override
  Uri get url => _apiUrl;
  @override
  ICacheRepo? get cache => _appCache;
  void _init() {
    _freshLink = CustomFreshLink.oAuth2(
      tokenStorage: InMemoryTokenStorage(),
      refreshToken: (p0, p1) async {
        final token = await updateRefreshToken(_apiUrl);
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
      link: Link.from([_freshLink, HttpLink('$_apiUrl')]),
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
    await _freshLink.setToken(
      IBOAuth2Token(
        accessToken: await _appCache?.read(CacheEnum.token) ?? '',
        refreshToken: await _appCache?.read(CacheEnum.refresh) ?? '',
      ),
    );
    _client = _client.copyWith(
      link: Link.from([
        _freshLink,
        HttpLink(
          '$_apiUrl',
          defaultHeaders: {
            'accept-Language': await _appCache?.read(CacheEnum.lang) ?? 'en',
            'marketplace': 'PN',
            'User-Agent':
                'BpApp:${await _appCache?.read(CacheEnum.versionCode)}',
          },
        ),
      ]),
      cache: GraphQLCache(),
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
    final result = await _client.query<dynamic>(_queryOptions(path));
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
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<R, E>(errorFromJson: errorFromJson);
      }
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          _errorResponseToJson,
        );
      }
      return request.responseQueryDetail<R, E>(dataFromJson, field);
    } catch (e) {
      return onExceptionError(e, errorFromJson, _errorResponseToJson);
    }
  }

  @override
  Future<Result<R, E>> queryMultiple<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    MapParam? params,
  }) async {
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<R, E>(errorFromJson: errorFromJson);
      }
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          _errorResponseToJson,
        );
      }
      final response = request.responseMultipleQuery<R, E>(dataFromJson);
      if (response != null) return response;
    } catch (e) {
      return onExceptionError(e, errorFromJson, _errorResponseToJson);
    }
    return Failure(
      errorFromJson(
        _errorResponseToJson
            .copyWith(status: 503, reasonPhrase: 'Bad request')
            .toJson(),
      ),
    );
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
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<R, E>(errorFromJson: errorFromJson);
      }
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
          _errorResponseToJson,
        );
      }
      return request.responseDetail<R, E>(dataFromJson, field);
    } catch (e) {
      return onExceptionError(e, errorFromJson, _errorResponseToJson);
    }
  }

  @override
  Future<Result<List<R>, E>> queryList<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  }) async {
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<List<R>, E>(errorFromJson: errorFromJson);
      }
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          _errorResponseToJson,
        );
      }

      return request.responseItemPageList(dataFromJson, field);
    } catch (e) {
      return onExceptionError(e, errorFromJson, _errorResponseToJson);
    }
  }

  @override
  Future<Result<List<R>, E>> list<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  }) async {
    try {
      if (_checkNetwork != null && !await _checkNetwork.isConnected) {
        return checkNetworkStatus<List<R>, E>(errorFromJson: errorFromJson);
      }
      await _getHeaders();
      final request = await _queryRequest(path: path, variables: params);
      if (request.hasException) {
        return errorGraphQlResponse(
          errorFromJson,
          request,
          _errorResponseToJson,
        );
      }
      return request.responseList<R, E>(dataFromJson, field);
    } catch (e) {
      return onExceptionError(e, errorFromJson, _errorResponseToJson);
    }
  }

  Failure<R, E> errorGraphQlResponse<R, E extends Exception>(
    ErrorFromJson<E> errorJson,
    QueryResult<Object?> request,
    ErrorResponse errorData,
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
    final jsonData = jsonDecode(response.body);
    final mapData = jsonData as Map<String, dynamic>;

    mapData['Status'] = response.statusCode;
    mapData['reasonPhrase'] = response.reasonPhrase;
    addLogger('${response.statusCode} ${response.reasonPhrase}');
    return Failure(errorJson(mapData));
  }

  Failure<R, E> _responseServerDecode<R, E extends Exception>(
    Response? response,
    int? statusCode,
    ErrorFromJson<E> errorJson,
    ErrorResponse errorData,
  ) {
    addLogger(response?.errors?.first.errorFullMessage);
    return Failure(
      errorJson(
        errorData
            .copyWith(
              status: statusCode ?? HttpStatus.internalServerError,
              errors: response?.errors?.first,
            )
            .toJson(),
      ),
    );
  }

  Failure<R, E> _responseOperational<R, E extends Exception>({
    required ErrorFromJson<E> errorJson,
    required ErrorResponse errorData,
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
      addLogger(error.parsedResponse?.errors?.first.errorFullMessage);
      return Failure(
        errorJson(
          errorData
              .copyWith(
                errors: error.parsedResponse?.errors?.first,
                reasonPhrase: error.parsedResponse?.errors?.first.message,
                status: error.statusCode,
              )
              .toJson(),
        ),
      );
    }
    addLogger(
      graphErrors?.first.errorFullMessage ??
          linkException.toString().subStringLongString,
    );
    return Failure(
      errorJson(
        errorData
            .copyWith(
              errors: GraphQLError(message: '$graphErrors $linkException'),
              reasonPhrase: '$graphErrors',
              status: HttpStatus.badRequest,
            )
            .toJson(),
      ),
    );
  }
}
