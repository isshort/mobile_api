import '../../../mobile_api.dart';

typedef ErrorResponseFactory = IBaseErrorResponse Function();

final class ApiConfig {
  final Uri apiUrl;
  final String marketplaceValue;
  final String userAgentValue;
  final CheckNetwork? checkNetwork;
  final ICacheRepo? appCache;
  final PageFieldKeys pageFieldKeys;
  final String refreshTokenPath;
  final String? loggerPath;
  final String defaultLanguage;
  final bool allowBadCertificates;
  final ErrorResponseFactory errorResponseFactory;

  ApiConfig({
    required this.apiUrl,
    required this.marketplaceValue,
    required this.userAgentValue,
    required this.refreshTokenPath,
    this.loggerPath,
    this.defaultLanguage = 'en',
    this.allowBadCertificates = false,
    this.pageFieldKeys = const PageFieldKeys(),
    this.checkNetwork,
    this.appCache,
    this.errorResponseFactory = _defaultErrorFactory,
  });

  // copywith
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
    bool? allowBadCertificates,
    ErrorResponseFactory? errorResponseFactory,
  }) {
    return ApiConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      marketplaceValue: marketplaceValue ?? this.marketplaceValue,
      userAgentValue: userAgentValue ?? this.userAgentValue,
      checkNetwork: checkNetwork ?? this.checkNetwork,
      appCache: appCache ?? this.appCache,
      pageFieldKeys: pageFieldKeys ?? this.pageFieldKeys,
      refreshTokenPath: refreshTokenPath ?? this.refreshTokenPath,
      loggerPath: loggerPath ?? this.loggerPath,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      allowBadCertificates: allowBadCertificates ?? this.allowBadCertificates,
      errorResponseFactory: errorResponseFactory ?? this.errorResponseFactory,
    );
  }

  static IBaseErrorResponse _defaultErrorFactory() =>
      const DefaultErrorResponse();
}

/// Configuration for paginated GraphQL container keys.
class PageFieldKeys {
  final String itemsKey;
  final String pageInfoKey;
  final String hasNextPageKey;
  const PageFieldKeys({
    this.itemsKey = 'items',
    this.pageInfoKey = 'pageInfo',
    this.hasNextPageKey = 'hasNextPage',
  });
}
