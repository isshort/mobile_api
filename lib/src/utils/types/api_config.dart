import '../../../mobile_api.dart';

final class ApiConfig {
  final Uri apiUrl;
  final String marketplaceValue;
  final String userAgentValue;
  final CheckNetwork? checkNetwork;
  final ICacheRepo? appCache;

  ApiConfig({
    required this.apiUrl,
    required this.marketplaceValue,
    required this.userAgentValue,
    this.checkNetwork,
    this.appCache,
  });
}
