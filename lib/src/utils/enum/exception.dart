/// auth enums
enum ExceptionEnum {
  /// if auth is unauthenticated
  unauthenticated('AUTH_NOT_AUTHENTICATED'),

  unauthorized('AUTH_NOT_AUTHORIZED');

  const ExceptionEnum(this.value);

  /// value
  final String value;
}
