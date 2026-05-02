// {
// 	"code": "Invalid Credentials",
// 	"property": null,
// 	"description": "Credentials are incorrect"
// }

import 'package:mobile_api/mobile_api.dart';

final class GeneralError implements IBaseErrorResponse {
  @override
  final int? status;
  @override
  final dynamic errors;
  @override
  final String? reasonPhrase;
  @override
  final String? detail;

  GeneralError({this.status, this.errors, this.reasonPhrase, this.detail});

  @override
  GeneralError copyWith({
    int? status,
    dynamic errors,
    String? reasonPhrase,
    String? detail,
  }) => GeneralError(
    status: status ?? this.status,
    errors: errors ?? this.errors,
    reasonPhrase: reasonPhrase ?? this.reasonPhrase,
    detail: detail ?? this.detail,
  );

  factory GeneralError.fromJson(Map<String, dynamic> json) => GeneralError(
    status: json['status'] as int?,
    reasonPhrase: json['reasonPhrase'] as String? ?? json['code'] as String?,
    errors: json['errors'] ?? json['property'],
    detail: json['description'] as String? ?? json['detail'] as String?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'code': reasonPhrase,
    'property': errors,
    'description': detail,
  };
}
