import 'package:graphql/client.dart';

class GraphQlErrorModel implements Exception {
  GraphQlErrorModel({this.error, this.status, this.reasonPhrase});
  factory GraphQlErrorModel.fromJson(Map<String, dynamic> json) {
    return GraphQlErrorModel(
      error: _graphQlErrorFromJson(json['errors']),
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

  static GraphQLError? _graphQlErrorFromJson(Object? value) {
    if (value is GraphQLError) return value;
    if (value is List && value.isNotEmpty) {
      return _graphQlErrorFromJson(value.first);
    }
    if (value is Map<String, dynamic>) {
      final message = value['message'] as String?;
      if (message == null || message.isEmpty) return null;
      final extensions = value['extensions'] as Map<String, dynamic>?;
      final path = (value['path'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      return GraphqlErrorType(
        message: message,
        path: path,
        extensions: extensions,
      );
    }
    if (value is String && value.isNotEmpty) {
      return GraphqlErrorType(message: value);
    }
    return null;
  }

  @override
  String toString() =>
      'GraphQlErrorModel(status: $status, reasonPhrase: $reasonPhrase, error: ${errorMessage()})';
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
        path: (json['path'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        extensions: json['extensions'] as Map<String, dynamic>?,
      );
}
