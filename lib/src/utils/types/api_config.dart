import '../../../mobile_api.dart';

/// Creates error response instances from decoded JSON maps.
typedef ErrorResponseFactory = IBaseErrorResponse Function();

/// Shared configuration for REST and GraphQL API clients.
final class ApiConfig<TokenType extends IBOAuth2Token> {
  /// Base API URL used when request paths are relative.
  final Uri apiUrl;

  /// Static headers sent with each configured REST and GraphQL request.
  final Map<String, String> headers;

  /// Optional network checker used before executing API calls.
  final CheckNetwork? checkNetwork;

  /// Optional secure cache used for access tokens, refresh tokens, and headers.
  final ICacheRepo? appCache;

  /// GraphQL pagination key names used by list helpers.
  final PageFieldKeys pageFieldKeys;

  /// Relative endpoint used to refresh access tokens.
  final String refreshTokenPath;

  /// Builds the refresh-token request body.
  final RefreshBodyBuilder refreshBodyBuilder;

  /// Parses a refresh-token response payload into the configured token type.
  final RefreshTokenFromJson<TokenType> refreshTokenFromJson;

  /// Optional relative endpoint used for error logging.
  final String? loggerPath;

  /// Allows bad TLS certificates for the configured host when explicitly true.
  final bool allowBadCertificates;

  /// Factory used to create package-level error responses.
  final ErrorResponseFactory errorResponseFactory;

  /// Builds API client configuration.
  ApiConfig({
    required this.apiUrl,
    required this.refreshTokenPath,
    this.loggerPath,
    RefreshBodyBuilder? refreshBodyBuilder,
    RefreshTokenFromJson<TokenType>? refreshTokenFromJson,
    Map<String, String> headers = const {},
    this.allowBadCertificates = false,
    this.pageFieldKeys = const PageFieldKeys(),
    this.checkNetwork,
    this.appCache,
    this.errorResponseFactory = _defaultErrorFactory,
  }) : refreshBodyBuilder = refreshBodyBuilder ?? _defaultRefreshBodyBuilder,
       refreshTokenFromJson =
           refreshTokenFromJson ?? _defaultRefreshTokenFromJson<TokenType>,
       headers = _buildHeaders(headers);

  /// Returns a copy with selected configuration values replaced.
  ApiConfig<TokenType> copyWith({
    Uri? apiUrl,
    CheckNetwork? checkNetwork,
    ICacheRepo? appCache,
    PageFieldKeys? pageFieldKeys,
    String? refreshTokenPath,
    RefreshBodyBuilder? refreshBodyBuilder,
    RefreshTokenFromJson<TokenType>? refreshTokenFromJson,
    String? loggerPath,
    Map<String, String>? headers,
    bool? allowBadCertificates,
    ErrorResponseFactory? errorResponseFactory,
  }) {
    return ApiConfig<TokenType>(
      apiUrl: apiUrl ?? this.apiUrl,
      checkNetwork: checkNetwork ?? this.checkNetwork,
      appCache: appCache ?? this.appCache,
      pageFieldKeys: pageFieldKeys ?? this.pageFieldKeys,
      refreshTokenPath: refreshTokenPath ?? this.refreshTokenPath,
      refreshBodyBuilder: refreshBodyBuilder ?? this.refreshBodyBuilder,
      refreshTokenFromJson: refreshTokenFromJson ?? this.refreshTokenFromJson,
      loggerPath: loggerPath ?? this.loggerPath,
      headers: headers ?? this.headers,
      allowBadCertificates: allowBadCertificates ?? this.allowBadCertificates,
      errorResponseFactory: errorResponseFactory ?? this.errorResponseFactory,
    );
  }

  static IBaseErrorResponse _defaultErrorFactory() =>
      const DefaultErrorResponse();

  static Map<String, dynamic> _defaultRefreshBodyBuilder(String refreshToken) =>
      {'refreshToken': refreshToken};

  static T _defaultRefreshTokenFromJson<T extends IBOAuth2Token>(
    Map<String, dynamic> json,
  ) => IBOAuth2Token.fromJson(json) as T;

  static Map<String, String> _buildHeaders(Map<String, String> headers) =>
      Map.unmodifiable(headers);
}

/// Configuration for paginated GraphQL container keys.
class PageFieldKeys {
  /// Default GraphQL list item key.
  final String itemsKey;

  /// Default GraphQL pagination info key.
  final String pageInfoKey;

  /// Default GraphQL next-page flag key.
  final String hasNextPageKey;

  /// Default GraphQL end cursor key.
  final String endCursorKey;

  /// Creates key names for paginated GraphQL response containers.
  const PageFieldKeys({
    this.itemsKey = 'items',
    this.pageInfoKey = 'pageInfo',
    this.hasNextPageKey = 'hasNextPage',
    this.endCursorKey = 'endCursor',
  });
}
