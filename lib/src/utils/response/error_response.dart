/// Public interface that external projects can implement and inject.
abstract class IBaseErrorResponse implements Exception {
  int? get status;
  dynamic get errors;
  String? get reasonPhrase;
  String? get detail;

  Map<String, dynamic> toJson();

  IBaseErrorResponse copyWith({
    int? status,
    dynamic errors,
    String? reasonPhrase,
    String? detail,
  });
}

/// Default implementation used by the package if caller does not provide one.
class DefaultErrorResponse implements IBaseErrorResponse {
  const DefaultErrorResponse({
    this.status,
    this.errors,
    this.reasonPhrase,
    this.detail,
  });

  factory DefaultErrorResponse.fromJson(Map<String, dynamic> json) =>
      DefaultErrorResponse(
        status: json['status'] as int?,
        errors: json['errors'],
        reasonPhrase: json['reasonPhrase'] as String?,
        detail: json['detail'] as String?,
      );

  @override
  final int? status;
  @override
  final dynamic errors;
  @override
  final String? reasonPhrase;
  @override
  final String? detail;

  @override
  Map<String, dynamic> toJson() => {
    'status': status,
    'errors': errors,
    'reasonPhrase': reasonPhrase,
    'detail': detail,
  };

  @override
  IBaseErrorResponse copyWith({
    int? status,
    dynamic errors,
    String? reasonPhrase,
    String? detail,
  }) => DefaultErrorResponse(
    status: status ?? this.status,
    errors: errors ?? this.errors,
    reasonPhrase: reasonPhrase ?? this.reasonPhrase,
    detail: detail ?? this.detail,
  );

  @override
  String toString() =>
      'DefaultErrorResponse(status: $status, reason: $reasonPhrase, detail: $detail, errors: $errors)';

  @override
  bool operator ==(Object other) =>
      other is DefaultErrorResponse &&
      other.status == status &&
      other.reasonPhrase == reasonPhrase &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(status, reasonPhrase, detail);
}

// /// (Optional) Backward compatibility typedef.
// /// External code that referenced ErrorResponse can switch gradually.
// @Deprecated('Use IBaseErrorResponse or DefaultErrorResponse')
// typedef ErrorResponse = DefaultErrorResponse;

final class AppErrorMessage {
  AppErrorMessage._();
  static const String noInternet = 'No internet connection';
}
