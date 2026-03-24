/// Exception thrown when a network request fails (connection error, timeout, HTTP error).
class ServerException implements Exception {
  /// Human-readable description of the error.
  final String message;

  /// Creates a [ServerException] with the given [message].
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// Exception thrown when an HTTP response cannot be parsed as expected.
class ParseException implements Exception {
  /// Human-readable description of the parse error.
  final String message;

  /// Creates a [ParseException] with the given [message].
  const ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}
