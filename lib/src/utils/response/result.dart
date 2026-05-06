/// Result of a typed API call.
sealed class Result<S, E extends Exception> {}

/// Successful API result containing a decoded value.
final class Success<S, E extends Exception> extends Result<S, E> {
  /// Creates a success result.
  Success(this.value, {this.statusCode, this.hasNextPage});

  /// HTTP status code when available.
  final int? statusCode;

  /// GraphQL pagination flag when available.
  final bool? hasNextPage;

  /// Decoded success value.
  final S value;
}

/// Failed API result containing a typed exception.
final class Failure<S, E extends Exception> extends Result<S, E> {
  /// Creates a failure result.
  Failure(this.exception);

  /// Decoded failure exception.
  final E exception;
}

/// Lightweight raw response used by simple requests.
final class SimpleResult {
  /// Creates a simple raw result.
  SimpleResult(this.statusCode, this.body);

  /// HTTP status code.
  final int statusCode;

  /// Raw response body or error message.
  final dynamic body;
}
