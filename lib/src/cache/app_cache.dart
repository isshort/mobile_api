import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_api/src/cache/repo.dart';
import 'package:mobile_api/src/utils/enum/cache.dart';

final class AppCacheRepoImpl implements IAppCacheRepo {
  AppCacheRepoImpl() {
    _init();
  }

  Future<void> _init() async {
    _secureStorage = const FlutterSecureStorage();
  }

  late final FlutterSecureStorage _secureStorage;

  @override
  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<void> delete(CacheEnum key) async {
    await _secureStorage.delete(key: key.name);
  }

  @override
  Future<void> deleteAll(List<CacheEnum> keys) async {
    await Future.wait(keys.map(delete));
  }

  @override
  Future<String> read(CacheEnum key) async {
    final sec = await _secureStorage.read(key: key.name);
    return sec ?? '';
  }

  @override
  Future<void> save(CacheEnum key, String value) async {
    await _secureStorage.write(key: key.name, value: value);
  }

  @override
  Future<void> saveAll(Map<CacheEnum, String> values) async {
    await Future.wait(
      values.entries.map((entry) => save(entry.key, entry.value)),
    );
  }
}
