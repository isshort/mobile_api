final class SuccessResponse {
  SuccessResponse({
    this.data,
    this.error,
    this.status,
  });
  factory SuccessResponse.fromJson(Map<String, dynamic> json) =>
      SuccessResponse(
        data: json['data'] as Map<String, dynamic>?,
        error: json['error'] as Map<String, dynamic>?,
        status: json['status'] as int?,
      );

  final int? status;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? error;
}

final class BooleanResponse {
  BooleanResponse({required this.isSuccess});

  factory BooleanResponse.fromJsonPhone(Map<String, dynamic> json) =>
      BooleanResponse(isSuccess: json['isExist'] as bool);

  final bool isSuccess;
}
