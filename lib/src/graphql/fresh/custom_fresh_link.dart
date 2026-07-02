import 'package:fresh_graphql/fresh_graphql.dart';

import '../../../mobile_api.dart';

/// CustomFreshLink is a copy of FreshLink
final class CustomFreshLink<T> extends FreshLink<T> {
  /// Constructor for CustomFreshLink
  CustomFreshLink({
    required super.tokenStorage,
    required super.shouldRefresh,
    required super.refreshToken,
    super.tokenHeader,
  });

  /// Here we used our own custom TokenStorage [IBOAuth2Token]
  static CustomFreshLink<T> oAuth2<T extends IBOAuth2Token>({
    required TokenStorage<T> tokenStorage,
    required RefreshToken<T?> refreshToken,
    required ShouldRefresh shouldRefresh,
    TokenHeaderBuilder<T?>? tokenHeader,
  }) {
    return CustomFreshLink<T>(
      refreshToken: refreshToken,
      tokenStorage: tokenStorage,
      shouldRefresh: shouldRefresh,
      tokenHeader:
          tokenHeader ??
          (token) {
            if (token == null || token.accessToken.isEmpty) {
              return {};
            }
            return {'authorization': '${token.tokenType} ${token.accessToken}'};
          },
    );
  }
}
