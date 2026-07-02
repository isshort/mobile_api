import 'package:graphql/client.dart';

import '../token/oauth_token.dart';

typedef FromJsonFun<T> = T Function(Map<String, dynamic>);
typedef ErrorFromJson<E extends Exception> = E Function(Map<String, dynamic>);
typedef EmptySuccessBuilder<T> = T Function(int statusCode);
typedef RefreshBodyBuilder = Map<String, dynamic> Function(String refreshToken);
typedef RefreshTokenFromJson<T extends IBOAuth2Token> =
    T Function(Map<String, dynamic>);
typedef MapParam = Map<String, dynamic>;
typedef QueryResponse = QueryResult<Object?>;
