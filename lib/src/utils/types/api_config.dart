import '../../../mobile_api.dart';

/// Creates error response instances from decoded JSON maps.
typedef ErrorResponseFactory = IBaseErrorResponse Function();

/// Shared configuration for REST and GraphQL API clients.
final class ApiConfig {
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
    Map<String, String> headers = const {},
    this.allowBadCertificates = false,
    this.pageFieldKeys = const PageFieldKeys(),
    this.checkNetwork,
    this.appCache,
    this.errorResponseFactory = _defaultErrorFactory,
  }) : headers = _buildHeaders(headers);

  /// Returns a copy with selected configuration values replaced.
  ApiConfig copyWith({
    Uri? apiUrl,
    CheckNetwork? checkNetwork,
    ICacheRepo? appCache,
    PageFieldKeys? pageFieldKeys,
    String? refreshTokenPath,
    String? loggerPath,
    Map<String, String>? headers,
    bool? allowBadCertificates,
    ErrorResponseFactory? errorResponseFactory,
  }) {
    return ApiConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      checkNetwork: checkNetwork ?? this.checkNetwork,
      appCache: appCache ?? this.appCache,
      pageFieldKeys: pageFieldKeys ?? this.pageFieldKeys,
      refreshTokenPath: refreshTokenPath ?? this.refreshTokenPath,
      loggerPath: loggerPath ?? this.loggerPath,
      headers: headers ?? this.headers,
      allowBadCertificates: allowBadCertificates ?? this.allowBadCertificates,
      errorResponseFactory: errorResponseFactory ?? this.errorResponseFactory,
    );
  }

  static IBaseErrorResponse _defaultErrorFactory() =>
      const DefaultErrorResponse();

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

  /// Creates key names for paginated GraphQL response containers.
  const PageFieldKeys({
    this.itemsKey = 'items',
    this.pageInfoKey = 'pageInfo',
    this.hasNextPageKey = 'hasNextPage',
  });
}
