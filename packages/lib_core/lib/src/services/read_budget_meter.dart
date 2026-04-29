// =============================================================================
// ReadBudgetMeter — session-wide Firestore read budget enforcement.
//
// Architecture requirement: ≤30 reads per customer session (SAD §3).
// Wraps get() and query.get() calls (NOT snapshots/streams which use
// WebSocket and don't count as per-read billing after initial fetch).
//
// Usage in repos: _meter?.trackRead(count) before every get/query.get.
// =============================================================================

import 'dart:async';
import 'package:logging/logging.dart';

/// Event types emitted when budget thresholds are crossed.
enum ReadBudgetEvent { warning, exceeded }

/// Exception thrown when the session read budget is exceeded.
class ReadBudgetExceededException implements Exception {
  const ReadBudgetExceededException(this.currentCount, this.maxReads);
  final int currentCount;
  final int maxReads;

  @override
  String toString() =>
      'ReadBudgetExceededException: $currentCount reads exceeds limit of $maxReads';
}

/// Tracks Firestore get/query reads within a session and enforces a cap.
class ReadBudgetMeter {
  ReadBudgetMeter({
    this.maxReads = 30,
    this.warningThreshold = 25,
  }) : assert(warningThreshold < maxReads);

  static final Logger _log = Logger('ReadBudgetMeter');

  final int maxReads;
  final int warningThreshold;
  int _count = 0;
  final StreamController<ReadBudgetEvent> _eventController =
      StreamController<ReadBudgetEvent>.broadcast();

  /// Current read count this session.
  int get currentCount => _count;

  /// Stream of budget events (warning at threshold, exceeded at max).
  Stream<ReadBudgetEvent> get events => _eventController.stream;

  /// Track [count] Firestore reads. Call before every get/query.get.
  /// Throws [ReadBudgetExceededException] if the budget is exceeded.
  void trackRead([int count = 1]) {
    _count += count;
    _log.fine('trackRead: +$count → $_count/$maxReads');

    if (_count >= maxReads) {
      _eventController.add(ReadBudgetEvent.exceeded);
      _log.warning('Read budget EXCEEDED: $_count/$maxReads');
      throw ReadBudgetExceededException(_count, maxReads);
    }

    if (_count >= warningThreshold && _count - count < warningThreshold) {
      _eventController.add(ReadBudgetEvent.warning);
      _log.info('Read budget WARNING: $_count/$maxReads');
    }
  }

  /// Reset the counter (call on session start / app resume).
  void resetSession() {
    _log.info('Session reset: $_count → 0');
    _count = 0;
  }

  /// Clean up resources.
  void dispose() {
    _eventController.close();
  }
}
