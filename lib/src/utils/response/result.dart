sealed class Result<S, E extends Exception> {}

final class Success<S, E extends Exception> extends Result<S, E> {
  Success(this.value, {this.statusCode, this.hasNextPage});
  final int? statusCode;
  final bool? hasNextPage;
  final S value;
}

final class Failure<S, E extends Exception> extends Result<S, E> {
  Failure(this.exception);

  final E exception;
}

final class SimpleResult {
  SimpleResult(this.statusCode, this.body);
  final int statusCode;
  final String body;
}
