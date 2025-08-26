import 'package:graphql/client.dart';

class GraphQlErrorModel implements Exception {
  GraphQlErrorModel({
    this.error,
    this.status,
    this.reasonPhrase,
  });
  factory GraphQlErrorModel.fromJson(Map<String, dynamic> json) {
    return GraphQlErrorModel(
      error: json['errors'] == null ? null : json['errors'] as GraphQLError?,
      status: (json['status'] ?? json['Status']) as int?,
      reasonPhrase: json['reasonPhrase'] as String?,
    );
  }
  final int? status;
  final String? reasonPhrase;
  final GraphQLError? error;

  String errorMessage() {
    return error?.message ?? reasonPhrase ?? 'Unknown error';
  }
}

final class GraphqlErrorType extends GraphQLError {
  const GraphqlErrorType({
    required super.message,
    List<String>? super.path,
    super.extensions,
  });
  factory GraphqlErrorType.fromJson(Map<String, dynamic> json) =>
      GraphqlErrorType(
        message: json['message'] as String,
        path:
            (json['path'] as List<dynamic>?)?.map((e) => e as String).toList(),
        extensions: json['extensions'] as Map<String, dynamic>?,
      );
}
