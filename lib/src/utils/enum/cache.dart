/// A strongly typed cache key used by secure storage helpers.
abstract class CacheKey {
  /// Raw storage key value.
  String get value;

  /// Creates a cache key.
  const CacheKey();

  @override
  String toString() => value;
}

/// Converts supported cache key types into string values.
abstract final class CacheKeyResolver {
  /// Resolves a [CacheKey], [Enum], or [String] into a storage key string.
  static String asString(dynamic key) {
    if (key is CacheKey) return key.value;
    if (key is Enum) return key.name;
    if (key is String) return key;
    throw ArgumentError('Unsupported cache key type: $key');
  }
}

/// User/app-defined dynamic key (allows any custom key).
class DynamicCacheKey extends CacheKey {
  /// Creates a dynamic cache key.
  const DynamicCacheKey(this.value);

  /// Raw storage key value.
  @override
  final String value;
}

/// Built-in reusable (generic) keys.
class CoreCacheKey extends CacheKey {
  /// Creates a built-in cache key.
  const CoreCacheKey._(this.value);

  /// Raw storage key value.
  @override
  final String value;

  /// Access token cache key.
  static const accessToken = CoreCacheKey._('access_token');

  /// Refresh token cache key.
  static const refreshToken = CoreCacheKey._('refresh_token');

  /// Theme preference cache key.
  static const theme = CoreCacheKey._('theme');

  /// PIN code cache key.
  static const pinCode = CoreCacheKey._('pin_code');

  /// Application version cache key.
  static const appVersion = CoreCacheKey._('app_version');

  /// Language preference cache key.
  static const language = CoreCacheKey._('language');

  /// Login role cache key.
  static const loginRole = CoreCacheKey._('login_role');

  /// Onboarding state cache key.
  static const onBoard = CoreCacheKey._('on_board');

  /// User identifier cache key.
  static const userId = CoreCacheKey._('user_id');

  /// User roles cache key.
  static const userRoles = CoreCacheKey._('user_roles');

  /// User full name cache key.
  static const userFullName = CoreCacheKey._('user_full_name');

  /// User phone number cache key.
  static const userPhoneNumber = CoreCacheKey._('user_phone_number');

  /// Keys you may want to preload / clear together.
  static const bootstrap = <CoreCacheKey>[accessToken, refreshToken, theme];
}

/// Helper builders for groups of cache writes.
abstract final class CacheKeyBundle {
  /// Creates a map for saving an access/refresh token pair.
  static Map<CacheKey, String> tokenPair({
    required String access,
    required String refresh,
  }) => {CoreCacheKey.accessToken: access, CoreCacheKey.refreshToken: refresh};

  /// Creates initial secure values for common auth state.
  static Map<CacheKey, String> initialSecure({
    required String access,
    required String refresh,
    String? pin,
  }) => {
    CoreCacheKey.accessToken: access,
    CoreCacheKey.refreshToken: refresh,
    CoreCacheKey.pinCode: ?pin,
  };
}
