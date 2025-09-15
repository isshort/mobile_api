import 'package:mobile_api/src/utils/enum/cache.dart';

abstract class ICacheRepo {
  Future<void> save(CacheKey key, String value);
  Future<String> read(CacheKey key);
  Future<void> clear();
  Future<void> delete(CacheKey key);
  Future<void> deleteAll(List<CacheKey> keys);
  Future<void> saveAll(Map<CacheKey, String> values);
}
