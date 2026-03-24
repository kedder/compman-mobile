import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Sealed class representing all possible failures in the app.
///
/// Used as the left side of [Either] returns from repositories and use cases.
@freezed
sealed class Failure with _$Failure {
  /// A failure caused by a network error (no connection, timeout, HTTP error).
  const factory Failure.network(String message) = NetworkFailure;

  /// A failure caused by an error parsing the response (unexpected HTML structure).
  const factory Failure.parse(String message) = ParseFailure;

  /// A failure caused by a local storage error.
  const factory Failure.storage(String message) = StorageFailure;
}
