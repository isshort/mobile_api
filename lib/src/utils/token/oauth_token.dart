import 'package:mobile_api/src/utils/enum/cache.dart';

/// OAuth2 token model used by REST and GraphQL refresh flows.
class IBOAuth2Token {
  /// Creates an OAuth2 token.
  IBOAuth2Token({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.scope,
    this.roles,
  });

  /// Creates an OAuth2 token from backend JSON.
  factory IBOAuth2Token.fromJson(Map<String, dynamic> json) => IBOAuth2Token(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,

    tokenType: json['tokenType'] as String? ?? 'Bearer',
    expiresIn: json['expiresIn'] as int?,
    scope: json['scope'] as String?,
    roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );

  /// Access token sent in authorization headers.
  final String accessToken;

  /// Refresh token used to renew access.
  final String refreshToken;

  /// Token type, usually `Bearer`.
  final String? tokenType;

  /// Optional expiration duration in seconds.
  final int? expiresIn;

  /// Optional OAuth scope.
  final String? scope;

  /// Optional roles included in the token response.
  final List<String>? roles;

  /// Converts the token pair into cache key values.
  Map<String, String> tokenToJson() => <String, String>{
    CoreCacheKey.accessToken.value: accessToken,
    CoreCacheKey.refreshToken.value: refreshToken,
  };
}
