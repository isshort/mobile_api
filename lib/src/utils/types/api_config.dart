import '../../../mobile_api.dart';

final class ApiConfig {
  final Uri apiUrl;
  final String marketplaceValue;
  final String userAgentValue;
  final CheckNetwork? checkNetwork;
  final ICacheRepo? appCache;
  final PageFieldKeys pageFieldKeys;
  final String refreshTokenPath;
  final String loggerPath;
  final String defaultLanguage;


  ApiConfig({
    required this.apiUrl,
    required this.marketplaceValue,
    required this.userAgentValue,
    required this.refreshTokenPath,
    required this.loggerPath,
    this.defaultLanguage = 'en',
    this.pageFieldKeys = const PageFieldKeys(),
    this.checkNetwork,
    this.appCache,
  });
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
