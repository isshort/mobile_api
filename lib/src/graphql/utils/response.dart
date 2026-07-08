import 'package:mobile_api/src/utils/response/result.dart';
import 'package:mobile_api/src/utils/types/types.dart';

import '../model/cursor_page.dart';

extension QueryPage on QueryResponse {
  Map<String, dynamic>? _asMap(String key) {
    final v = data == null ? null : data![key];
    return v is Map<String, dynamic> ? v : null;
  }

  Map<String, dynamic>? pageNode(String field) => _asMap(field);

  List<dynamic> pageItems({
    required String field,
    required PageFieldKeys keys,
  }) {
    final node = pageNode(field);
    final raw = node?[keys.itemsKey];
    return raw is List ? raw : const [];
  }

  bool hasNextPage({required PageFieldKeys keys, required String field}) {
    final node = pageNode(field);
    final info = node?[keys.pageInfoKey];
    if (info is Map<String, dynamic>) {
      final val = info[keys.hasNextPageKey];
      return val is bool && val;
    }
    return false;
  }

  String? endCursor({required PageFieldKeys keys, required String field}) {
    final node = pageNode(field);
    final info = node?[keys.pageInfoKey];
    if (info is Map<String, dynamic>) {
      final val = info[keys.endCursorKey];
      return val is String ? val : null;
    }
    return null;
  }

  Success<List<R>, E> responsePageList<R, E extends Exception>({
    required FromJsonFun<R> fromJson,
    required String field,
    required PageFieldKeys keys,
  }) {
    final itemsList = pageItems(
      field: field,
      keys: keys,
    ).whereType<Map<String, dynamic>>().map(fromJson).toList();
    return Success(
      itemsList,
      hasNextPage: hasNextPage(keys: keys, field: field),
    );
  }

  Success<CursorPage<R>, E> responseCursorPage<R, E extends Exception>({
    required FromJsonFun<R> fromJson,
    required String field,
    required PageFieldKeys keys,
  }) {
    final itemsList = pageItems(
      field: field,
      keys: keys,
    ).whereType<Map<String, dynamic>>().map(fromJson).toList();
    return Success(
      CursorPage(
        items: itemsList,
        hasNextPage: hasNextPage(keys: keys, field: field),
        endCursor: endCursor(keys: keys, field: field),
      ),
    );
  }

  Success<R, E> responseQueryDetail<R, E extends Exception>({
    required FromJsonFun<R> fromJson,
    required String field,
    required PageFieldKeys keys,
  }) {
    final direct = _asMap(field);
    if (direct != null) {
      return Success(fromJson(direct));
    }
    final paged = pageItems(field: field, keys: keys);
    if (paged.isNotEmpty && paged.first is Map<String, dynamic>) {
      return Success(fromJson(paged.first as Map<String, dynamic>));
    }
    return Success(fromJson(const {}));
  }

  Result<List<R>, E> responseList<R, E extends Exception>({
    required FromJsonFun<R> fromJson,
    required String field,
    required PageFieldKeys keys,
  }) {
    final paged = pageItems(field: field, keys: keys);
    if (paged.isNotEmpty && paged.first is Map<String, dynamic>) {
      final mapped = paged
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
      return Success(mapped);
    }
    return Success(const []);
  }

  Result<R, E>? responseMultipleQuery<R, E extends Exception>(
    FromJsonFun<R> fromJson,
  ) {
    final root = data;
    if (root == null) return null;
    return Success(fromJson(root));
  }

  Result<R, E> responseDetail<R, E extends Exception>(
    FromJsonFun<R> fromJson,
    String field,
  ) {
    final obj = _asMap(field) ?? const <String, dynamic>{};
    return Success(fromJson(obj));
  }
}
