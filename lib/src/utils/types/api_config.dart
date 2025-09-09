import '../../../mobile_api.dart';

final class ApiConfig {
  final Uri apiUrl;
  final CheckNetwork? checkNetwork;
  final ICacheRepo? appCache;
  final String marketplaceValue;
  final String userAgentValue;

  ApiConfig({
    required this.apiUrl,
    required this.checkNetwork,
    required this.appCache,
    required this.marketplaceValue,
    required this.userAgentValue,
  });
}
