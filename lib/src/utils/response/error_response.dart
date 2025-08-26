final class ErrorResponse implements Exception {
  ErrorResponse({this.status, this.errors, this.reasonPhrase, this.detail});
  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
        status: json['status'] as int?,
        errors: json['errors'] as dynamic,
        reasonPhrase: json['reasonPhrase'] as String?,
        detail: json['detail'] as String?,
      );

  final int? status;
  final dynamic errors;
  final String? reasonPhrase;
  final String? detail;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'errors': errors,
        'reasonPhrase': reasonPhrase,
        'detail': detail,
      };

  ErrorResponse copyWith({int? status, dynamic errors, String? reasonPhrase}) {
    return ErrorResponse(
      status: status,
      errors: errors,
      reasonPhrase: reasonPhrase,
      detail: detail,
    );
  }

  @override
  bool operator ==(Object other) =>
      (other is ErrorResponse) && other.status == status;
  @override
  int get hashCode => status.hashCode;
}

final class AppErrorMessage {
  AppErrorMessage._();
  static const String noInternet = 'Нет подключения к Интернету';
}
