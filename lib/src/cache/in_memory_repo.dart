import 'package:mobile_api/src/cache/repo.dart';
import 'package:mobile_api/src/utils/enum/cache.dart';

/// In-memory [ICacheRepo] for use in tests and temporary sessions.
///
/// Pass an optional initial map to pre-populate values at construction time:
/// ```dart
/// InMemoryCacheRepo({CoreCacheKey.accessToken: 'my-test-token'})
/// ```
final class InMemoryCacheRepo implements ICacheRepo {
  InMemoryCacheRepo([Map<CacheKey, String>? initial])
      : _store = Map.of(initial ?? {});

  final Map<CacheKey, String> _store;

  @override
  Future<void> save(CacheKey key, String value) async => _store[key] = value;

  @override
  Future<String> read(CacheKey key) async => _store[key] ?? '';

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<void> delete(CacheKey key) async => _store.remove(key);

  @override
  Future<void> deleteAll(List<CacheKey> keys) async {
    for (final k in keys) {
      _store.remove(k);
    }
  }

  @override
  Future<void> saveAll(Map<CacheKey, String> values) async =>
      _store.addAll(values);
}
