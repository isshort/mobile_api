import '../../../mobile_api.dart';

/// Contract for REST requests supported by the package.
abstract class IHttp {
  /// Sends a simple GET request and returns the raw response body.
  Future<SimpleResult> get(
    String path, {
    MapParam? params,
    Map<String, String>? headers,
  });

  /// Sends a typed REST request and decodes the full response body.
  Future<Result<S, E>> baseMethod<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  });

  /// Sends a typed REST request and decodes a nested response field.
  Future<Result<S, E>> baseMethodType<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> dataFromJson,
    required ErrorFromJson<E> errorFromJson,
    required RequestType requestType,
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    MapParam? params,
    String? query,
    Map<String, dynamic>? body,
  });

  /// Sends a multipart/form-data request with optional file paths.
  Future<Result<S, E>?> multipart<S, E extends Exception>(
    String path, {
    required FromJsonFun<S> successFromJson,
    required ErrorFromJson<E> errorFromJson,
    required Map<String, String> body,
    EmptySuccessBuilder<S>? emptySuccessBuilder,
    Map<String, String>? files,
    Map<String, dynamic>? params,
    RequestType? httpMethod,
  });
}
