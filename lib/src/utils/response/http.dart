class ErrorModel implements Exception {
  ErrorModel({
    this.errors,
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.reasonPhrase,
  });
  factory ErrorModel.fromJson(Map<String, dynamic> json) => ErrorModel(
    errors: json['errors'],
    type: json['type'] as String?,
    reasonPhrase: json['reasonPhrase'] as String?,
    title: json['title'] as String?,
    status: (json['status'] ?? json['Status']) as int?,
    detail: (json['detail'] ?? json['Detail']) as String?,
    instance: json['instance'] as String?,
  );
  final dynamic errors;
  final String? reasonPhrase;
  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;

  String get message => detail ?? title ?? reasonPhrase ?? '$errors';
}
