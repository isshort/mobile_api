import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_api/mobile_api.dart';

import 'model/auth_request.dart';
import 'model/auth_response.dart';
import 'model/general_error.dart';
import 'model/shipper_register.dart';

class AppInit {
  static IHttp httpInit() {
    return IHttpImpl(
      apiConfig: ApiConfig(
        apiUrl: Uri(
          scheme: 'http',
          host: 'applications.moamlogistics.com',
          port: 9090,
        ),
        marketplaceValue: 'ml',
        userAgentValue: 'mlApp',
        loggerPath: 'logger',
        refreshTokenPath: '/api/accounts/refresh',
      ),
    );
  }

  static IGraphQl graphInit() {
    return IGraphQlImpl(
      apiConfig: ApiConfig(
        apiUrl: Uri(
          scheme: 'http',
          host: 'applications.moamlogistics.com',
          port: 9090,
          path: '/graphql',
        ),
        marketplaceValue: 'ml',
        userAgentValue: 'mlApp',
        loggerPath: 'logger',
        refreshTokenPath: '/api/accounts/refresh',
      ),
    );
  }
}

void main() {
  late IHttp iHttp;
  late IGraphQl iGraphQl;
  setUp(() {
    iHttp = AppInit.httpInit();
    iGraphQl = AppInit.graphInit();
  });

  group('Auth Test', () {
    test('Shipper Login', () async {
      const body = AuthRequest(
        email: 'string@gmail.com',
        password: '1234qwerASDF',
      );
      final response = await iHttp.baseMethod(
        '/api/shipper/login',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: body.toJson(),
      );

      final value = switch (response) {
        Success(value: final value) => value,
        Failure(exception: final exception) => exception,
      };

      expect(value, isA<AuthResponse>());
    });
    test('Shipper Login Invalid', () async {
      const body = AuthRequest(email: 'string@gmail.com', password: 'asdf');
      final response = await iHttp.baseMethod(
        '/api/shipper/login',
        dataFromJson: AuthResponse.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: body.toJson(),
      );

      final value = switch (response) {
        Success(value: final value) => value,
        Failure(exception: final exception) => exception,
      };

      expect(value, isA<GeneralError>());
    });
    test('register shipper', () async {
      const body = ShipperRegister(
        email: 'test2@gmail.com',
        password: '1234qwerASDF',
        fullName: 'Test User',
        tinOrNationalID: '123456789',
        phoneNumber: '1234567890',
        companyLicense: 'ABC123',
        location: 'Test Location',
        regionServed: 'Test Region',
      );
      final response = await iHttp.baseMethod(
        '/api/shipper',
        dataFromJson: ShipperRegister.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: body.toJson(),
      );

      final value = switch (response) {
        Success(value: final value) => value,
        Failure(exception: final exception) => exception,
      };

      expect(value, isA<ShipperRegister>());
    });
    test('method not allowed', () async {
      const body = ShipperRegister(
        email: 'test@gmail.com',
        password: '1234qwerASDF',
        fullName: 'Test User',
        tinOrNationalID: '123456789',
        phoneNumber: '1234567890',
        companyLicense: 'ABC123',
        location: 'Test Location',
        regionServed: 'Test Region',
      );
      final response = await iHttp.baseMethod(
        '/api/shipper/register',
        dataFromJson: ShipperRegister.fromJson,
        errorFromJson: GeneralError.fromJson,
        requestType: RequestType.post,
        body: body.toJson(),
      );

      final value = switch (response) {
        Success(value: final value) => value,
        Failure(exception: final exception) => exception,
      };

      expect(value, isA<GeneralError>());
    });

    /// shipper get method list

    test('shipper get method list', () async {
      final shipperPath = '''
query getShippers {
  shippers {
    totalCount
    pageInfo {
      hasNextPage
    }
    items {
      userId
      fullName
      tinOrNationalID
      phoneNumber
      email
      companyLicence
      location
      regionServed
    }
  }
}
''';

      final simple = await iGraphQl.simpleQuery(path: shipperPath);
      print(simple);

      final response = await iGraphQl.queryList(
        field: 'shippers',
        dataFromJson: ShipperRegister.fromJson,
        errorFromJson: GeneralError.fromJson,
        path: shipperPath,
      );

      final value = switch (response) {
        Success(value: final value) => value,
        Failure(exception: final exception) => exception,
      };

      expect(value, isA<GeneralError>());
    });
  });
}
