import 'package:graphql/client.dart';
import 'package:mobile_api/src/graphql/model/cursor_page.dart';
import 'package:mobile_api/src/utils/enum/duration.dart';
import 'package:mobile_api/src/utils/response/result.dart';
import 'package:mobile_api/src/utils/types/custom_type.dart';

/// Contract for GraphQL query helpers supported by the package.
abstract class IGraphQl {
  /// Executes a raw query and returns the underlying GraphQL result.
  Future<QueryResult?> simpleQuery({required String path});

  /// Executes a paginated query and decodes the configured list field.
  Future<Result<List<R>, E>> queryList<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });

  /// Executes a paginated query and decodes items plus cursor metadata.
  Future<Result<CursorPage<R>, E>> queryCursorPage<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });

  /// Executes a list query and decodes items from the configured field.
  Future<Result<List<R>, E>> list<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });

  /// Executes a query and decodes the full GraphQL response data object.
  Future<Result<R, E>> queryMultiple<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    MapParam? params,
  });

  /// Executes a query and decodes a detail object or first paginated item.
  Future<Result<R, E>> queryDetail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });

  /// Executes a detail query with an optional timeout override.
  Future<Result<R, E>> detail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
    DurationEnum? timeout,
  });
}
