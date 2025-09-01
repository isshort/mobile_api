import 'package:mobile_api/src/utils/enum/cache.dart';

abstract class ICacheRepo {
  Future<void> save(CacheEnum key, String value);
  Future<String> read(CacheEnum key);
  Future<void> clear();
  Future<void> delete(CacheEnum key);
  Future<void> deleteAll(List<CacheEnum> keys);
  Future<void> saveAll(Map<CacheEnum, String> values);
}
