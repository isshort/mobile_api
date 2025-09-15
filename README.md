# mobile_api

A Dart/Flutter package for seamless REST and GraphQL API integration in Moam Digital System apps.

## Features

- Unified HTTP and GraphQL client
- Automatic token refresh
- Customizable headers (marketplace, user agent, etc.)
- Error handling and logging
- Multipart/form-data support

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  mobile_api: ^0.0.2
```

Import in your Dart code:

```dart
import 'package:mobile_api/mobile_api.dart';
```

## Usage

```dart
final apiConfig = ApiConfig(
  apiUrl: Uri.parse('https://your.api.url'),
  marketplaceValue: 'YOUR_MARKETPLACE',
  userAgentValue: 'YOUR_USER_AGENT',
  // ...other config
);

final httpRepo = IHttp


/// Built-in reusable (generic) keys.
class CoreCacheKey extends CacheKey {
  const CoreCacheKey._(this.value);
  @override
  final String value;

  // Common auth / app keys
  static const accessToken = CoreCacheKey._('access_token');
  static const refreshToken = CoreCacheKey._('refresh_token');
  static const language = CoreCacheKey._('language');
  static const theme = CoreCacheKey._('theme');
  static const appVersion = CoreCacheKey._('app_version');
  static const biometricEnabled = CoreCacheKey._('biometric_enabled');
  static const onboarding = CoreCacheKey._('onboarding');
  static const pinCode = CoreCacheKey._('pin_code');
  static const session = CoreCacheKey._('session');

  /// Keys you may want to preload / clear together.
  static const bootstrap = <CoreCacheKey>[
    accessToken,
    refreshToken,
    theme,
  ];
}

/// User/app-defined dynamic key (allows any custom key).
class DynamicCacheKey extends CacheKey {
  const DynamicCacheKey(this.value);
  @override
  final String value;
}

/// Optional namespaced key (adds a prefix automatically).
class NamespacedCacheKey extends CacheKey {
  NamespacedCacheKey(this._raw, {String? namespace})
      : value = namespace == null ? _raw : '$namespace-$_raw';
  final String _raw;
  @override
  final String value;
}


/// Helper builders for grouped cache writes.
abstract final class CacheKeyBundle {
  static Map<CacheKey, String> tokenPair({
    required String access,
    required String refresh,
  }) =>
      {
        CoreCacheKey.accessToken: access,
        CoreCacheKey.refreshToken: refresh,
      };

  static Map<CacheKey, String> initialSecure({
    required String access,
    required String refresh,
    String? pin,
  }) =>
      {
        CoreCacheKey.accessToken: access,
        CoreCacheKey.refreshToken: refresh,
        if (pin != null) CoreCacheKey.pinCode: pin,
      };
}
