import 'package:mobile_api/src/utils/enum/cache.dart';

final class IBOAuth2Token {
  IBOAuth2Token({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.scope,
  });
  factory IBOAuth2Token.fromJson(Map<String, dynamic> json) => IBOAuth2Token(
    accessToken: json['accessToken'] as String,
    tokenType: json['tokenType'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresIn: json['expiresIn'] as int,
  );

  final String accessToken;
  final String refreshToken;
  final String? tokenType;
  final int? expiresIn;
  final String? scope;

  Map<String, String> tokenToJson() => <String, String>{
    CacheEnum.token.name: accessToken,
    CacheEnum.refresh.name: refreshToken,
  };
}
