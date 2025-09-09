import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_api/src/src.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late ICacheRepoImpl cacheRepo;

  WidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockStorage = MockSecureStorage();
    cacheRepo = ICacheRepoImpl();
  });

  test('read should return saved value', () async {
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'stored_value');

    final result = await cacheRepo.read(CacheEnum.token);

    expect(result, 'stored_value');

    verify(() => mockStorage.read(key: 'token')).called(1);
  });
}
