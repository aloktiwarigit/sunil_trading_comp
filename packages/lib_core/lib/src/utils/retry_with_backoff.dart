// =============================================================================
// retryWithBackoff — lightweight retry utility with exponential backoff.
//
// Auto-retries transient failures (unavailable, deadline-exceeded, aborted,
// network errors). Does NOT retry permanent failures (permission-denied,
// not-found, already-exists, invalid-argument).
//
// Usage:
//   final result = await retryWithBackoff(() => firestore.doc('x').get());
// =============================================================================

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('retryWithBackoff');

/// Transient Firestore error codes that are safe to retry.
const _retryableCodes = {
  'unavailable',
  'deadline-exceeded',
  'aborted',
  'resource-exhausted',
  'cancelled',
};

/// Permanent Firestore error codes that should NOT be retried.
const _permanentCodes = {
  'permission-denied',
  'not-found',
  'already-exists',
  'invalid-argument',
  'unauthenticated',
  'failed-precondition',
  'out-of-range',
  'unimplemented',
  'data-loss',
};

/// Default predicate: retries transient network/Firestore errors only.
bool _defaultShouldRetry(Object error) {
  if (error is FirebaseException) {
    final code = error.code;
    if (_permanentCodes.contains(code)) return false;
    if (_retryableCodes.contains(code)) return true;
    // Unknown code — err on the side of not retrying.
    return false;
  }
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  // HttpException from dart:io (e.g., connection reset).
  if (error is HttpException) return true;
  return false;
}

/// Execute [operation] with exponential backoff on transient failures.
///
/// - [maxAttempts]: total attempts including the first (default 3).
/// - [initialDelay]: wait before the first retry (default 500ms).
///   Subsequent retries double: 500ms → 1s → 2s.
/// - [shouldRetry]: custom predicate. Defaults to retrying only transient
///   Firestore + network errors.
///
/// Throws the last error if all attempts fail.
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  bool Function(Object error)? shouldRetry,
}) async {
  final retryPredicate = shouldRetry ?? _defaultShouldRetry;
  var delay = initialDelay;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e) {
      final isLastAttempt = attempt == maxAttempts;
      final isRetryable = retryPredicate(e);

      if (isLastAttempt || !isRetryable) {
        _log.warning(
          'retryWithBackoff: attempt $attempt/$maxAttempts failed '
          '(retryable=$isRetryable, last=$isLastAttempt): $e',
        );
        rethrow;
      }

      _log.info(
        'retryWithBackoff: attempt $attempt/$maxAttempts failed, '
        'retrying in ${delay.inMilliseconds}ms: $e',
      );
      await Future<void>.delayed(delay);
      delay *= 2;
    }
  }

  // Unreachable, but satisfies the type system.
  throw StateError('retryWithBackoff: exhausted all attempts');
}
