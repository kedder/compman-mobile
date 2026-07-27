import 'package:flutter/material.dart';

import '../error/failures.dart';

/// Shared error message + retry button, used inline wherever an
/// [AsyncValue.when] error branch needs a simple recovery action.
class ErrorRetry extends StatelessWidget {
  /// Creates an [ErrorRetry] showing [message] with a retry button labelled
  /// [retryLabel] that calls [onRetry] when pressed.
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

/// Maps a [Failure] (or any other error object) to a human-readable message.
String failureMessage(Object err) {
  if (err is Failure) {
    return switch (err) {
      NetworkFailure(:final message) => message,
      ParseFailure(:final message) => message,
      StorageFailure(:final message) => message,
    };
  }
  return err.toString();
}
