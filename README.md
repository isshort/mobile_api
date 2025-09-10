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