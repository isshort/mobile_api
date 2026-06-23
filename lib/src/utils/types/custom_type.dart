import 'package:graphql/client.dart';

typedef FromJsonFun<T> = T Function(Map<String, dynamic>);
typedef ErrorFromJson<E extends Exception> = E Function(Map<String, dynamic>);
typedef EmptySuccessBuilder<T> = T Function(int statusCode);
typedef MapParam = Map<String, dynamic>;
typedef QueryResponse = QueryResult<Object?>;
