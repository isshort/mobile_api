// ignore_for_file: public_member_api_docs

import 'package:mobile_api/src/utils/response/result.dart';
import 'package:mobile_api/src/utils/types/custom_type.dart';

extension QueryPage on QueryResponse {
  ///
  /// here we should pass the first argument
  Map<String, dynamic>? object(String param) =>
      (data != null && data![param] is Map<String, dynamic>)
      ? data![param] as Map<String, dynamic>
      : null;

  /// Here we get list of items in a query
  List<dynamic> items(String model) {
    final transaction = object(model);

    return (transaction != null && transaction['items'] is List<dynamic>)
        ? transaction['items'] as List<dynamic>
        : [];
  }

  /// get information about pagination
  bool hasNextPage(String model) {
    final transaction = object(model);
    if (transaction == null) return false;

    final pageInfo = transaction['pageInfo'];
    if (pageInfo is Map<String, dynamic>) {
      return pageInfo['hasNextPage'] is bool && pageInfo['hasNextPage'] == true;
    }
    return false;
  }

  Success<List<R>, E> responseItemPageList<R, E extends Exception>(
    FromJsonFun<R> fromJsonFun,
    String model,
  ) {
    return Success(
      items(
        model,
      ).whereType<Map<String, dynamic>>().map((e) => fromJsonFun(e)).toList(),
      hasNextPage: hasNextPage(model),
    );
  }

  Success<R, E> responseQueryDetail<R, E extends Exception>(
    FromJsonFun<R> fromJsonFun,
    String field,
  ) {
    final result = items(field);
    if (result.isNotEmpty && result.first is Map<String, dynamic>) {
      return Success(fromJsonFun(result.first! as Map<String, dynamic>));
    }
    return Success(fromJsonFun({}));
  }

  Result<List<R>, E> responseList<R, E extends Exception>(
    FromJsonFun<R> fromJsonFun,
    String model,
  ) {
    final result = data?[model];
    if (result is List<Object?>) {
      return Success(
        result
            .whereType<Map<String, dynamic>>()
            .map((e) => fromJsonFun(e))
            .toList(),
      );
    }
    return Success([]);
  }

  Result<R, E>? responseMultipleQuery<R, E extends Exception>(
    FromJsonFun<R> dataFromJson,
  ) {
    if (data == null) return null;
    return Success(dataFromJson(data!));
  }

  Result<R, E> responseDetail<R, E extends Exception>(
    FromJsonFun<R> fromJsonFun,
    String field,
  ) {
    final mapData = data?[field] as Map<String, dynamic>?;
    if (mapData == null) return Success(fromJsonFun({}));
    return Success(fromJsonFun(mapData));
  }
}
