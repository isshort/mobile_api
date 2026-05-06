import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_api/src/cache/repo.dart';
import 'package:mobile_api/src/utils/enum/cache.dart';

final class ICacheRepoImpl implements ICacheRepo {
  ICacheRepoImpl({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<void> delete(CacheKey key) async {
    await _secureStorage.delete(key: key.value);
  }

  @override
  Future<void> deleteAll(List<CacheKey> keys) async {
    await Future.wait(keys.map(delete));
  }

  @override
  Future<String> read(CacheKey key) async {
    final sec = await _secureStorage.read(key: key.value);
    return sec ?? '';
  }

  @override
  Future<void> save(CacheKey key, String value) async {
    await _secureStorage.write(key: key.value, value: value);
  }

  @override
  Future<void> saveAll(Map<CacheKey, String> values) async {
    await Future.wait(
      values.entries.map((entry) => save(entry.key, entry.value)),
    );
  }
}
