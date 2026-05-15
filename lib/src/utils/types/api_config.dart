import '../../../mobile_api.dart';

/// Creates error response instances from decoded JSON maps.
typedef ErrorResponseFactory = IBaseErrorResponse Function();

/// Shared configuration for REST and GraphQL API clients.
final class ApiConfig {
  /// Base API URL used when request paths are relative.
  final Uri apiUrl;

  /// Static headers sent with each configured REST and GraphQL request.
  final Map<String, String> headers;

  /// Marketplace header value sent with each configured request.
  @Deprecated('Use headers[HttpHeadersConst.marketplace] instead.')
  String get marketplaceValue => headers[HttpHeadersConst.marketplace] ?? '';

  /// User-Agent prefix sent with each configured request.
  @Deprecated('Use headers[HttpHeadersConst.userAgent] instead.')
  String get userAgentValue => headers[HttpHeadersConst.userAgent] ?? '';

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

  /// Fallback language for the `Accept-Language` header.
  @Deprecated('Use headers[HttpHeadersConst.acceptLanguage] instead.')
  String get defaultLanguage =>
      headers[HttpHeadersConst.acceptLanguage] ?? 'en';

  /// Additional headers sent with each configured REST and GraphQL request.
  @Deprecated('Use headers instead.')
  Map<String, String> get customHeaders => headers;

  /// Allows bad TLS certificates for the configured host when explicitly true.
  final bool allowBadCertificates;

  /// Factory used to create package-level error responses.
  final ErrorResponseFactory errorResponseFactory;

  /// Builds API client configuration.
  ApiConfig({
    required this.apiUrl,
    String? marketplaceValue,
    String? userAgentValue,
    required this.refreshTokenPath,
    this.loggerPath,
    String? defaultLanguage,
    Map<String, String> headers = const {},
    @Deprecated('Use headers instead.')
    Map<String, String> customHeaders = const {},
    this.allowBadCertificates = false,
    this.pageFieldKeys = const PageFieldKeys(),
    this.checkNetwork,
    this.appCache,
    this.errorResponseFactory = _defaultErrorFactory,
  }) : headers = _buildHeaders(
         marketplaceValue: marketplaceValue,
         userAgentValue: userAgentValue,
         defaultLanguage: defaultLanguage,
         customHeaders: customHeaders,
         headers: headers,
       );

  /// Returns a copy with selected configuration values replaced.
  ApiConfig copyWith({
    Uri? apiUrl,
    String? marketplaceValue,
    String? userAgentValue,
    CheckNetwork? checkNetwork,
    ICacheRepo? appCache,
    PageFieldKeys? pageFieldKeys,
    String? refreshTokenPath,
    String? loggerPath,
    String? defaultLanguage,
    Map<String, String>? headers,
    @Deprecated('Use headers instead.') Map<String, String>? customHeaders,
    bool? allowBadCertificates,
    ErrorResponseFactory? errorResponseFactory,
  }) {
    final updatedHeaders = Map<String, String>.of(
      headers ?? customHeaders ?? this.headers,
    );
    if (marketplaceValue != null) {
      updatedHeaders[HttpHeadersConst.marketplace] = marketplaceValue;
    }
    if (userAgentValue != null) {
      updatedHeaders[HttpHeadersConst.userAgent] = userAgentValue;
    }
    if (defaultLanguage != null) {
      updatedHeaders[HttpHeadersConst.acceptLanguage] = defaultLanguage;
    }

    return ApiConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      checkNetwork: checkNetwork ?? this.checkNetwork,
      appCache: appCache ?? this.appCache,
      pageFieldKeys: pageFieldKeys ?? this.pageFieldKeys,
      refreshTokenPath: refreshTokenPath ?? this.refreshTokenPath,
      loggerPath: loggerPath ?? this.loggerPath,
      headers: updatedHeaders,
      allowBadCertificates: allowBadCertificates ?? this.allowBadCertificates,
      errorResponseFactory: errorResponseFactory ?? this.errorResponseFactory,
    );
  }

  static IBaseErrorResponse _defaultErrorFactory() =>
      const DefaultErrorResponse();

  static Map<String, String> _buildHeaders({
    required Map<String, String> customHeaders,
    required Map<String, String> headers,
    String? marketplaceValue,
    String? userAgentValue,
    String? defaultLanguage,
  }) {
    final acceptLanguage =
        defaultLanguage ??
        headers[HttpHeadersConst.acceptLanguage] ??
        customHeaders[HttpHeadersConst.acceptLanguage] ??
        'en';

    return {
      if (marketplaceValue != null && marketplaceValue.isNotEmpty)
        HttpHeadersConst.marketplace: marketplaceValue,
      if (userAgentValue != null && userAgentValue.isNotEmpty)
        HttpHeadersConst.userAgent: userAgentValue,
      if (acceptLanguage.isNotEmpty)
        HttpHeadersConst.acceptLanguage: acceptLanguage,
      ...customHeaders,
      ...headers,
    };
  }
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
