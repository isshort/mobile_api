import 'package:graphql/client.dart';

typedef FromJsonFun<T> = T Function(Map<String, dynamic>);
typedef ErrorFromJson<E extends Exception> = E Function(Map<String, dynamic>);
typedef MapParam = Map<String, dynamic>;
typedef QueryResponse = QueryResult<Object?>;
