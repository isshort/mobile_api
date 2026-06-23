import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_api/mobile_api.dart';

import 'model/auth_response.dart';
import 'model/general_error.dart';
import 'model/shipper_register.dart';

ApiConfig _config({
  String path = '',
  ICacheRepo? appCache,
  Map<String, String> headers = const {},
}) {
  return ApiConfig(
    apiUrl: Uri(scheme: 'https', host: 'api.example.test', path: path),
    refreshTokenPath: '/api/accounts/refresh',
    appCache: appCache,
    headers: {
      HttpHeadersConst.marketplace: 'ml',
      HttpHeadersConst.userAgent: 'mlApp',
      HttpHeadersConst.acceptLanguage: 'en',
      ...headers,
    },
  );
}

InMemoryCacheRepo _tokenCache(String token) =>
    InMemoryCacheRepo({CoreCacheKey.accessToken: token});

const _hibetaHeaders = {
  'referer': 'https://teststore.hibeta.kz/',
  'x-hibeta-country-locked': 'true',
  'x-hibeta-language': 'tr',
  'x-hibeta-storefront-host': 'teststore.hibeta.kz',
  'x-hibeta-tenant-country': 'KZ',
  'x-hibeta-tenant-mode': 'single-country',
};

void main() {
  group('IHttpImpl', () {
    test('decodes successful JSON responses', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/shipper/login');
        expect(request.headers[HttpHeadersConst.authorization], isNull);
        expect(request.headers[HttpHeadersConst.marketplace], 'ml');

        return http.Response(
          jsonEncode({
            'accessToken': 'access-token',
            'userId': 'user-id',
            'email': 'shipper@example.test',
            'roles': ['Shipper'],
          }),
          200,
        );
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/shipper/login',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: {'email': 'shipper@example.test', 'password': 'secret'},
      );

      expect(response, isA<Success<AuthResponse, GeneralError>>());
      final success = response as Success<AuthResponse, GeneralError>;
      expect(success.statusCode, 200);
      expect(success.value.accessToken, 'access-token');
    });

    test('treats 202 JSON responses as success', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'accepted-token',
            'userId': 'user-id',
            'email': 'shipper@example.test',
            'roles': ['Shipper'],
          }),
          202,
        );
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/jobs',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
      );

      expect(response, isA<Success<AuthResponse, GeneralError>>());
      final success = response as Success<AuthResponse, GeneralError>;
      expect(success.statusCode, 202);
      expect(success.value.accessToken, 'accepted-token');
    });

    test('maps 204 empty responses with emptySuccessBuilder', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('', 204);
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/session',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.delete,
        emptySuccessBuilder: (statusCode) =>
            const AuthResponse(accessToken: 'deleted'),
      );

      expect(response, isA<Success<AuthResponse, GeneralError>>());
      final success = response as Success<AuthResponse, GeneralError>;
      expect(success.statusCode, 204);
      expect(success.value.accessToken, 'deleted');
    });

    test('returns clear failure for 204 without emptySuccessBuilder', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/session',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.delete,
      );

      expect(response, isA<Failure<AuthResponse, GeneralError>>());
      final failure = response as Failure<AuthResponse, GeneralError>;
      expect(failure.exception.status, 204);
      expect(failure.exception.reasonPhrase, contains('emptySuccessBuilder'));
    });

    test('preserves status for empty non-2xx failures', () async {
      final client = MockClient((request) async {
        return http.Response('', 404, reasonPhrase: 'Not Found');
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/missing',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.get,
      );

      expect(response, isA<Failure<AuthResponse, GeneralError>>());
      final failure = response as Failure<AuthResponse, GeneralError>;
      expect(failure.exception.status, 404);
      expect(failure.exception.reasonPhrase, 'Not Found');
    });

    test('decodes error JSON responses', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'Invalid Credentials',
            'description': 'Credentials are incorrect',
          }),
          400,
          reasonPhrase: 'Bad Request',
        );
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/shipper/login',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: {'email': 'shipper@example.test', 'password': 'wrong'},
      );

      expect(response, isA<Failure<AuthResponse, GeneralError>>());
      final failure = response as Failure<AuthResponse, GeneralError>;
      expect(failure.exception.reasonPhrase, 'Invalid Credentials');
      expect(failure.exception.detail, 'Credentials are incorrect');
    });

    test('builds GET requests from the configured base URL', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.example.test/users?page=1');
        return http.Response('ok', 200);
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.get('/users', params: {'page': '1'});

      expect(response.statusCode, 200);
      expect(response.body, 'ok');
    });

    test('raw GET treats 204 as a successful empty response', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.get('/api/session');

      expect(response.statusCode, 204);
      expect(response.body, isEmpty);
    });

    test(
      'sends Authorization header when token is supplied via InMemoryCacheRepo',
      () async {
        final client = MockClient((request) async {
          expect(
            request.headers[HttpHeadersConst.authorization],
            '${HttpHeadersConst.bearer} test-token',
          );
          return http.Response(
            jsonEncode({
              'accessToken': 'new-token',
              'userId': 'u1',
              'email': 'a@b.com',
              'roles': [],
            }),
            200,
          );
        });
        final api = IHttpImpl(
          apiConfig: _config(appCache: _tokenCache('test-token')),
          httpClient: client,
        );

        final response = await api.baseMethod<AuthResponse, GeneralError>(
          '/api/me',
          dataFromJson: AuthResponse.fromJson,
          errorFromJson: GeneralError.fromJson,
          requestType: RequestType.get,
        );

        expect(response, isA<Success<AuthResponse, GeneralError>>());
      },
    );

    test('sends configured custom headers', () async {
      final client = MockClient((request) async {
        for (final entry in _hibetaHeaders.entries) {
          expect(request.headers[entry.key], entry.value);
        }
        return http.Response(
          jsonEncode({
            'accessToken': 'access-token',
            'userId': 'user-id',
            'email': 'shipper@example.test',
            'roles': ['Shipper'],
          }),
          200,
        );
      });
      final api = IHttpImpl(
        apiConfig: _config(headers: _hibetaHeaders),
        httpClient: client,
      );

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/me',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.get,
      );

      expect(response, isA<Success<AuthResponse, GeneralError>>());
    });

    test('sends configured standard headers', () async {
      final client = MockClient((request) async {
        expect(request.headers[HttpHeadersConst.marketplace], 'ml');
        expect(request.headers[HttpHeadersConst.userAgent], 'mlApp');
        expect(request.headers[HttpHeadersConst.acceptLanguage], 'en');
        return http.Response(
          jsonEncode({
            'accessToken': 'access-token',
            'userId': 'user-id',
            'email': 'shipper@example.test',
            'roles': ['Shipper'],
          }),
          200,
        );
      });
      final api = IHttpImpl(apiConfig: _config(), httpClient: client);

      final response = await api.baseMethod<AuthResponse, GeneralError>(
        '/api/me',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.get,
      );

      expect(response, isA<Success<AuthResponse, GeneralError>>());
    });
  });

  group('IGraphQlImpl', () {
    test('decodes paginated query lists without live network calls', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/graphql');
        return http.Response(
          jsonEncode({
            'data': {
              'shippers': {
                'pageInfo': {'hasNextPage': false},
                'items': [
                  {
                    'fullName': 'Test User',
                    'tinOrNationalID': '123456789',
                    'phoneNumber': '1234567890',
                    'email': 'shipper@example.test',
                    'company_licence': 'ABC123',
                    'location': 'Test Location',
                    'regionServed': 'Test Region',
                  },
                ],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = IGraphQlImpl(
        apiConfig: _config(path: '/graphql'),
        httpClient: client,
      );

      final response = await api.queryList<ShipperRegister, GeneralError>(
        field: 'shippers',
        dataFromJson: ShipperRegister.fromJson,
        errorFromJson: GeneralError.fromJson,
        path: '''
query getShippers {
  shippers {
    pageInfo { hasNextPage }
    items { fullName email }
  }
}
''',
      );

      expect(response, isA<Success<List<ShipperRegister>, GeneralError>>());
      final success = response as Success<List<ShipperRegister>, GeneralError>;
      expect(success.value, hasLength(1));
      expect(success.value.first.email, 'shipper@example.test');
    });

    test(
      'sends Authorization header when token is supplied via InMemoryCacheRepo',
      () async {
        final client = MockClient((request) async {
          expect(
            request.headers[HttpHeadersConst.authorization],
            '${HttpHeadersConst.bearer} gql-token',
          );
          return http.Response(
            jsonEncode({
              'data': {
                'shippers': {
                  'pageInfo': {'hasNextPage': false},
                  'items': [],
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final api = IGraphQlImpl(
          apiConfig: _config(
            path: '/graphql',
            appCache: _tokenCache('gql-token'),
          ),
          httpClient: client,
        );

        final response = await api.queryList<ShipperRegister, GeneralError>(
          field: 'shippers',
          dataFromJson: ShipperRegister.fromJson,
          errorFromJson: GeneralError.fromJson,
          path:
              'query { shippers { pageInfo { hasNextPage } items { email } } }',
        );

        expect(response, isA<Success<List<ShipperRegister>, GeneralError>>());
      },
    );

    test('sends configured custom headers', () async {
      final client = MockClient((request) async {
        for (final entry in _hibetaHeaders.entries) {
          expect(request.headers[entry.key], entry.value);
        }
        return http.Response(
          jsonEncode({
            'data': {
              'shippers': {
                'pageInfo': {'hasNextPage': false},
                'items': [],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = IGraphQlImpl(
        apiConfig: _config(path: '/graphql', headers: _hibetaHeaders),
        httpClient: client,
      );

      final response = await api.queryList<ShipperRegister, GeneralError>(
        field: 'shippers',
        dataFromJson: ShipperRegister.fromJson,
        errorFromJson: GeneralError.fromJson,
        path: 'query { shippers { pageInfo { hasNextPage } items { email } } }',
      );

      expect(response, isA<Success<List<ShipperRegister>, GeneralError>>());
    });
  });
}
