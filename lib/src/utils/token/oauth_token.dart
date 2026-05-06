import 'package:mobile_api/src/utils/enum/cache.dart';

class IBOAuth2Token {
  IBOAuth2Token({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.scope,
    this.roles,
  });
  factory IBOAuth2Token.fromJson(Map<String, dynamic> json) => IBOAuth2Token(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,

    tokenType: json['tokenType'] as String? ?? 'Bearer',
    expiresIn: json['expiresIn'] as int?,
    scope: json['scope'] as String?,
    roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList(),
  );

  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String? scope;
  final List<String>? roles;

  Map<String, String> tokenToJson() => <String, String>{
    CoreCacheKey.accessToken.value: accessToken,
    CoreCacheKey.refreshToken.value: refreshToken,
  };
}
