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
        refreshTokenPath: 'accounts/refresh',
      ),
    );
  }
}

void main() {
  late IHttp iHttp;
  setUp(() {
    iHttp = AppInit.httpInit();
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
    test('Shipper Register', () async {
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

      expect(value, isA<ShipperRegister>());
    });
  });
}
