// =============================================================================
// KillSwitchListener — real-time Firestore onSnapshot watcher for the
// /shops/{shopId}/featureFlags/runtime document.
//
// PRD I6.7 AC #7 + SAD ADR-007 v1.0.4 mandate that billable kill-switch
// flags propagate from server flip → client behavior change in <5 seconds
// end-to-end. That's tighter than Remote Config's 1-hour minimum fetch
// interval can achieve, so the canonical list of real-time flags lives in
// Firestore and is consumed via `onSnapshot`.
//
// Adapters (MediaStore, CommsChannel, Auth) consume this via synchronous
// bool getters exposed by the listener (`isCloudinaryBlocked`, etc.). Their
// factory's kill-switch probe parameter is a `() => listener.isXBlocked`
// lambda — no async state, no stale cache, no retry loop.
//
// See `runtime_feature_flags.dart` for the flag set and default values.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import 'runtime_feature_flags.dart';

/// Watches `/shops/{shopId}/featureFlags/runtime` and caches the latest
/// snapshot for synchronous probe queries by adapter factories.
///
/// Usage pattern (customer_app / shopkeeper_app):
/// ```dart
/// final listener = KillSwitchListener(
///   firestore: FirebaseFirestore.instance,
///   shopId: shopId,
/// );
/// await listener.start();
///
/// // Note: the probe parameter is FutureOr<bool> Function() so you can
/// // pass a sync closure directly — no `async =>` wrapper needed.
/// final mediaStore = MediaStoreFactory.build(
///   remoteConfig: remoteConfig,
///   firebaseStorage: FirebaseStorage.instance,
///   cloudinaryCloudName: 'yugma-prod',
///   isUploadKillSwitchActive: () => listener.isCloudinaryBlocked,
/// );
///
/// final commsChannel = CommsChannelFactory.build(
///   remoteConfig: remoteConfig,
///   firestore: FirebaseFirestore.instance,
///   isWriteKillSwitchActive: () => listener.isFirestoreBlocked,
/// );
/// // ... later, on app shutdown:
/// await listener.stop();
/// ```
///
/// **Error recovery posture (Phase 1.9 code review cleanup — Agent A
/// finding #2):** if the Firestore `onSnapshot` subscription errors
/// (transient 3G blip, emulator restart, rule change), the listener
/// keeps emitting the last-known-good `_current` snapshot AND logs the
/// error. This is DELIBERATELY fail-open-on-transient-error because:
///
/// 1. Kill-switch FLIPS are rare manual operator actions (approximately
///    monthly under normal Blaze budget cap conditions). The initial
///    snapshot, which we successfully read, is very likely still valid.
/// 2. Tier-3 3G connectivity is flaky — a fail-closed posture would
///    block every adapter upload on every transient blip, which breaks
///    the normal UX far more often than a kill-switch flip does.
/// 3. The typical kill-switch operator workflow (Cloud Function writes
///    the flag from a Pub/Sub budget alert) produces an immediate
///    onSnapshot, so the window between "flag set server-side" and
///    "client observes new state" is bounded by Firestore's propagation
///    latency (tens of ms under normal conditions), not by this
///    listener's error state.
///
/// The [lastSnapshotAt] field exposes the age of the cached state so
/// future refinements (Sprint 4+) can add a staleness check if needed.
/// Callers that want stronger guarantees can read [lastSnapshotAt] and
/// apply their own staleness threshold before honoring the probe.
class KillSwitchListener {
  /// Create a listener scoped to a single shop. One listener per shopId
  /// per app lifecycle — the app is single-tenant at runtime (PRD I6.4).
  KillSwitchListener({
    required FirebaseFirestore firestore,
    required String shopId,
  })  : _firestore = firestore,
        _shopId = shopId;

  final FirebaseFirestore _firestore;
  final String _shopId;

  static final Logger _log = Logger('KillSwitchListener');

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  final StreamController<RuntimeFeatureFlags> _controller =
      StreamController<RuntimeFeatureFlags>.broadcast();

  RuntimeFeatureFlags _current = RuntimeFeatureFlags.safeDefaults;

  DateTime? _lastSnapshotAt;

  // ---------------------------------------------------------------------------
  // Current snapshot accessors — used by adapter probes
  // ---------------------------------------------------------------------------

  /// The latest observed flag snapshot. Starts at [RuntimeFeatureFlags.safeDefaults]
  /// before [start] is called, which means adapter probes called during
  /// app startup (before the first onSnapshot emission) get safe defaults
  /// instead of null / throw / crash.
  RuntimeFeatureFlags get current => _current;

  /// Wall-clock time the last successful onSnapshot emission was received.
  /// Null before [start] completes its first snapshot. Advances on every
  /// subsequent successful snapshot (errors do NOT advance this).
  ///
  /// Phase 1.9 code review cleanup (Agent A finding #2): exposes the
  /// cached state's age so callers can apply their own staleness
  /// threshold if they need fail-closed semantics. Example:
  /// ```dart
  /// final ageMinutes = DateTime.now().difference(listener.lastSnapshotAt ?? DateTime.now()).inMinutes;
  /// if (ageMinutes > 10) {
  ///   // treat as stale — refuse the upload out of an abundance of caution
  /// }
  /// ```
  /// Sprint 4+ refinement: the adapter factories' probe signature may
  /// add an optional `maxStalenessMinutes` parameter that reads this
  /// field internally.
  DateTime? get lastSnapshotAt => _lastSnapshotAt;

  /// Broadcast stream of flag snapshots. Subscribe to react to flips in
  /// real time — typically used by state management layers (Riverpod /
  /// riverpod_generator providers in the app layer) that need to rebuild
  /// UI when a flag flips (e.g., showing a "अभी upload नहीं हो रहा" banner).
  Stream<RuntimeFeatureFlags> get stream => _controller.stream;

  /// Synchronous probe for the master kill-switch.
  bool get isKillSwitchActive => _current.killSwitchActive;

  /// Synchronous probe used by `MediaStoreCloudinaryFirebase.uploadCatalogImage`.
  /// Returns true if the master kill-switch is on OR `cloudinaryUploadsBlocked`
  /// is specifically set — master kill implies all sub-kills.
  bool get isCloudinaryBlocked =>
      _current.killSwitchActive || _current.cloudinaryUploadsBlocked;

  /// Synchronous probe used by `CommsChannelFirestore.sendText` /
  /// `sendVoiceNote`. Master kill implies all sub-kills.
  bool get isFirestoreBlocked =>
      _current.killSwitchActive || _current.firestoreWritesBlocked;

  /// Current auth provider strategy. Consumed by AuthProviderFactory on
  /// rebuild. Defaults to `firebase` before first snapshot.
  String get authProviderStrategy => _current.authProviderStrategy;

  /// Current comms channel strategy. Consumed by CommsChannelFactory on
  /// rebuild. Defaults to `firestore` before first snapshot.
  String get commsChannelStrategy => _current.commsChannelStrategy;

  /// Current media store strategy. Consumed by MediaStoreFactory on
  /// rebuild. Defaults to `cloudinary_firebase` before first snapshot.
  String get mediaStoreStrategy => _current.mediaStoreStrategy;

  /// Current OTP-at-commit flag. R12 kill-switch.
  bool get isOtpAtCommitEnabled => _current.otpAtCommitEnabled;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start listening. MUST be called before any adapter probe relies on
  /// the listener's state (though the probes are safe to call before start;
  /// they just return [RuntimeFeatureFlags.safeDefaults]).
  ///
  /// Idempotent — calling twice is a no-op.
  Future<void> start() async {
    if (_subscription != null) {
      _log.warning('start() called twice on KillSwitchListener for $_shopId');
      return;
    }

    final docRef = _firestore
        .collection('shops')
        .doc(_shopId)
        .collection('featureFlags')
        .doc('runtime');

    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          _log.info(
            'no featureFlags/runtime doc for $_shopId yet — using safe defaults',
          );
          _current = RuntimeFeatureFlags.safeDefaults;
          _lastSnapshotAt = DateTime.now();
        } else {
          try {
            final raw = snapshot.data()!;
            _current = RuntimeFeatureFlags.fromJson(<String, dynamic>{
              ...raw,
              // Normalize Firestore Timestamp → ISO string for Freezed JSON.
              'updatedAt': _normalizeTimestamp(raw['updatedAt']),
            });
            _lastSnapshotAt = DateTime.now();
            _log.fine(
              'runtime flags updated for $_shopId: '
              'killSwitch=${_current.killSwitchActive} '
              'cloudinary=${_current.cloudinaryUploadsBlocked} '
              'firestore=${_current.firestoreWritesBlocked}',
            );
          } on Object catch (e, st) {
            _log.warning(
              'failed to parse featureFlags/runtime for $_shopId: $e\n$st',
            );
            // Keep previous _current AND previous _lastSnapshotAt — do
            // not advance the timestamp on parse failure because that
            // would hide staleness from the Sprint 4+ refinement.
          }
        }
        if (!_controller.isClosed) {
          _controller.add(_current);
        }
      },
      onError: (Object error, StackTrace st) {
        _log.warning(
          'featureFlags/runtime onSnapshot error for $_shopId: $error\n$st',
        );
        // Deliberate fail-open-on-transient-error posture — see class
        // doc comment for rationale. _lastSnapshotAt is NOT advanced
        // here so staleness checks correctly reflect the age of the
        // last successful snapshot, not the age of the last error.
      },
    );

    _log.info('KillSwitchListener started for shop=$_shopId');
  }

  /// Stop listening and release the Firestore subscription. Does NOT
  /// close the broadcast stream controller — callers can still read the
  /// last known [current] value.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _log.info('KillSwitchListener stopped for shop=$_shopId');
  }

  /// Close the broadcast stream controller. Call only on full app shutdown.
  /// After dispose the listener cannot be restarted.
  Future<void> dispose() async {
    await stop();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Normalize Firestore Timestamp to an ISO8601 string the Freezed JSON
  /// round-trip understands.
  static Object? _normalizeTimestamp(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
