import 'package:mobile_api/src/utils/enum/cache.dart';

/// Secure key-value cache used by the API clients.
abstract class ICacheRepo {
  /// Saves a single string value for the given key.
  Future<void> save(CacheKey key, String value);

  /// Reads a string value, returning an empty string when the key is absent.
  Future<String> read(CacheKey key);

  /// Removes all values from the secure cache.
  Future<void> clear();

  /// Deletes a single cache key.
  Future<void> delete(CacheKey key);

  /// Deletes multiple cache keys.
  Future<void> deleteAll(List<CacheKey> keys);

  /// Saves multiple cache values.
  Future<void> saveAll(Map<CacheKey, String> values);
}
