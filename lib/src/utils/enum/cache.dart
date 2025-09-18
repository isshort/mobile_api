abstract class CacheKey {
  String get value;
  const CacheKey();

  @override
  String toString() => value;
}

abstract final class CacheKeyResolver {
  static String asString(dynamic key) {
    if (key is CacheKey) return key.value;
    if (key is Enum) return key.name;
    if (key is String) return key;
    throw ArgumentError('Unsupported cache key type: $key');
  }
}

/// User/app-defined dynamic key (allows any custom key).
class DynamicCacheKey extends CacheKey {
  const DynamicCacheKey(this.value);
  @override
  final String value;
}

 
/// Built-in reusable (generic) keys.
class CoreCacheKey extends CacheKey {
  const CoreCacheKey._(this.value);
  @override
  final String value;

  // Common auth / app keys
  static const accessToken = CoreCacheKey._('access_token');
  static const refreshToken = CoreCacheKey._('refresh_token');
  static const theme = CoreCacheKey._('theme');
  static const pinCode = CoreCacheKey._('pin_code');
  static const appVersion = CoreCacheKey._('app_version');
  static const language = CoreCacheKey._('language');

 

  /// Keys you may want to preload / clear together.
  static const bootstrap = <CoreCacheKey>[accessToken, refreshToken, theme];
}

 
abstract final class CacheKeyBundle {
  static Map<CacheKey, String> tokenPair({
    required String access,
    required String refresh,
  }) => {CoreCacheKey.accessToken: access, CoreCacheKey.refreshToken: refresh};

  static Map<CacheKey, String> initialSecure({
    required String access,
    required String refresh,
    String? pin,
  }) => {
    CoreCacheKey.accessToken: access,
    CoreCacheKey.refreshToken: refresh,
    if (pin != null) CoreCacheKey.pinCode: pin,
  };
}
