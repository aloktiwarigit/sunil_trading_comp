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
/// final mediaStore = MediaStoreFactory.build(
///   remoteConfig: remoteConfig,
///   firebaseStorage: FirebaseStorage.instance,
///   cloudinaryCloudName: 'yugma-prod',
///   isUploadKillSwitchActive: () async => listener.isCloudinaryBlocked,
/// );
///
/// final commsChannel = CommsChannelFactory.build(
///   remoteConfig: remoteConfig,
///   firestore: FirebaseFirestore.instance,
///   isWriteKillSwitchActive: () async => listener.isFirestoreBlocked,
/// );
/// // ... later, on app shutdown:
/// await listener.stop();
/// ```
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

  // ---------------------------------------------------------------------------
  // Current snapshot accessors — used by adapter probes
  // ---------------------------------------------------------------------------

  /// The latest observed flag snapshot. Starts at [RuntimeFeatureFlags.safeDefaults]
  /// before [start] is called, which means adapter probes called during
  /// app startup (before the first onSnapshot emission) get safe defaults
  /// instead of null / throw / crash.
  RuntimeFeatureFlags get current => _current;

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
        } else {
          try {
            final raw = snapshot.data()!;
            _current = RuntimeFeatureFlags.fromJson(<String, dynamic>{
              ...raw,
              // Normalize Firestore Timestamp → ISO string for Freezed JSON.
              'updatedAt': _normalizeTimestamp(raw['updatedAt']),
            });
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
            // Keep previous _current — do not downgrade to safeDefaults on
            // parse error because that could wipe out a kill-switch state.
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
        // Emit the current (possibly stale) value rather than error —
        // adapters should keep operating on their last-known-good state
        // rather than crash on a transient Firestore error.
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
