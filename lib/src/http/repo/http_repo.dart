import '../../../mobile_api.dart';

abstract class IHttp {
  Future<SimpleResult> get(
    String path, {
    MapParam? params,
    Map<String, String>? headers,
  });

  Future<Result<S, E>> baseMethod<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  });

  Future<Result<S, E>> baseMethodType<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  });

 
  Future<Result<S, E>?> multipart<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> successFromJson,
    required ErrorFromJson<E> errorFromJson,
    required Map<String, String> body,
    Map<String, String>? files,
    Map<String, dynamic>? params,
    RequestType? httpMethod,
  });
  
}
