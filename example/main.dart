import 'package:flutter/foundation.dart';
import 'package:mobile_api/mobile_api.dart';

class UserProfile {
  const UserProfile({this.id, this.name});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  final String? id;
  final String? name;
}

Future<void> main() async {
  final cache = ICacheRepoImpl();
  await cache.saveAll(
    CacheKeyBundle.tokenPair(access: 'access-token', refresh: 'refresh-token'),
  );

  final config = ApiConfig(
    apiUrl: Uri.parse('https://api.example.com'),
    refreshTokenPath: '/api/accounts/refresh',
    appCache: cache,
    checkNetwork: CheckNetwork(),
    headers: const {
      HttpHeadersConst.marketplace: 'ml',
      HttpHeadersConst.userAgent: 'mlApp',
      HttpHeadersConst.acceptLanguage: 'en',
    },
  );

  final rest = IHttpImpl(apiConfig: config);
  final profileResult = await rest
      .baseMethod<UserProfile, DefaultErrorResponse>(
        '/api/users/me',
        requestType: RequestType.get,
        dataFromJson: UserProfile.fromJson,
        errorFromJson: DefaultErrorResponse.fromJson,
      );

  switch (profileResult) {
    case Success(value: final profile):
      debugPrint('Hello ${profile.name ?? profile.id}');
    case Failure(exception: final error):
      debugPrint('REST request failed: ${error.reasonPhrase}');
  }

  final graphQl = IGraphQlImpl(
    apiConfig: config.copyWith(
      apiUrl: Uri.parse('https://api.example.com/graphql'),
    ),
  );

  final usersResult = await graphQl
      .queryList<UserProfile, DefaultErrorResponse>(
        path: '''
query users {
  users {
    pageInfo { hasNextPage }
    items { id name }
  }
}
''',
        field: 'users',
        dataFromJson: UserProfile.fromJson,
        errorFromJson: DefaultErrorResponse.fromJson,
      );

  switch (usersResult) {
    case Success(value: final users):
      debugPrint('Loaded ${users.length} users');
    case Failure(exception: final error):
      debugPrint('GraphQL request failed: ${error.reasonPhrase}');
  }
}
