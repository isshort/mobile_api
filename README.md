# mobile_api

A Dart/Flutter package for REST and GraphQL API integration.

## Features

- REST client with shared headers, JSON decoding, typed success/failure results, and one retry after token refresh
- GraphQL client with typed list/detail helpers and refresh support
- Secure token/cache helpers backed by `flutter_secure_storage`
- Optional network connectivity checks
- Multipart/form-data upload support
- Optional logger endpoint for captured API errors

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  mobile_api: ^0.0.8+15
```

Import it:

```dart
import 'package:mobile_api/mobile_api.dart';
```

## Configuration

```dart
final cache = ICacheRepoImpl();

final apiConfig = ApiConfig(
  apiUrl: Uri.parse('https://api.example.com'),
  refreshTokenPath: '/api/accounts/refresh',
  loggerPath: '/logger',
  appCache: cache,
  checkNetwork: CheckNetwork(),
  headers: const {
    HttpHeadersConst.marketplace: 'ml',
    HttpHeadersConst.userAgent: 'mlApp',
    HttpHeadersConst.acceptLanguage: 'tr',
    'referer': 'https://teststore.hibeta.kz/',
    'x-hibeta-country-locked': 'true',
    'x-hibeta-language': 'tr',
    'x-hibeta-storefront-host': 'teststore.hibeta.kz',
    'x-hibeta-tenant-country': 'KZ',
    'x-hibeta-tenant-mode': 'single-country',
  },
);
```

Tokens are read from `CoreCacheKey.accessToken` and `CoreCacheKey.refreshToken`.

```dart
await cache.saveAll(
  CacheKeyBundle.tokenPair(
    access: accessToken,
    refresh: refreshToken,
  ),
);
```

## REST usage

```dart
final httpApi = IHttpImpl(apiConfig: apiConfig);

final result = await httpApi.baseMethod<UserResponse, DefaultErrorResponse>(
  '/api/users/me',
  requestType: RequestType.get,
  dataFromJson: UserResponse.fromJson,
  errorFromJson: DefaultErrorResponse.fromJson,
);

switch (result) {
  case Success(value: final user):
    // use user
  case Failure(exception: final error):
    // handle error
}
```

For endpoints that return `204 No Content` or another successful empty body,
provide an `emptySuccessBuilder` so the typed result can still be a success:

```dart
final result = await httpApi.baseMethod<BooleanResponse, DefaultErrorResponse>(
  '/api/users/me',
  requestType: RequestType.delete,
  dataFromJson: BooleanResponse.fromJsonPhone,
  errorFromJson: DefaultErrorResponse.fromJson,
  emptySuccessBuilder: (_) => BooleanResponse(isSuccess: true),
);
```

## GraphQL usage

```dart
final graphQlApi = IGraphQlImpl(
  apiConfig: apiConfig.copyWith(
    apiUrl: Uri.parse('https://api.example.com/graphql'),
  ),
);

final result = await graphQlApi.queryList<UserResponse, DefaultErrorResponse>(
  path: '''
query users {
  users {
    pageInfo { hasNextPage }
    items { id name }
  }
}
''',
  field: 'users',
  dataFromJson: UserResponse.fromJson,
  errorFromJson: DefaultErrorResponse.fromJson,
);
```

## Development certificates

By default, the package uses normal platform certificate validation. For local development against a host with a self-signed certificate, set `allowBadCertificates: true` in `ApiConfig`. Do not enable it for production builds.
