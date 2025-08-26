// ignore_for_file: public_member_api_docs

import 'package:graphql/client.dart';
import 'package:mobile_api/src/utils/enum/duration.dart';
import 'package:mobile_api/src/utils/response/result.dart';
import 'package:mobile_api/src/utils/types/custom_type.dart';

abstract class IGraphQl {
  Future<QueryResult?> simpleQuery({required String path});
  Future<Result<List<R>, E>> queryList<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });

  Future<Result<List<R>, E>> list<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });
  Future<Result<R, E>> queryMultiple<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    MapParam? params,
  });
  Future<Result<R, E>> queryDetail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
  });
  Future<Result<R, E>> detail<R, E extends Exception>({
    required FromJsonFun<R> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required String path,
    required String field,
    MapParam? params,
    DurationEnum? timeout,
  });
}
