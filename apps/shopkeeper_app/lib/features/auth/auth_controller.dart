// =============================================================================
// AuthController — Riverpod AsyncNotifier for the shopkeeper ops app.
//
// Flow: Google sign-in --> load Operator doc --> determine role --> signal
// ready or unauthorized per S4.1 ACs #1-6.
//
// Edge cases:
//   - No network: cached operator doc allows offline read-only access
//   - Operator doc deleted while signed in: permission-denied
//   - Multiple Google accounts: standard account picker via AuthProvider
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

/// The resolved auth state for the ops app.
enum OpsAuthStatus {
  /// Not yet determined — splash screen should be showing.
  loading,

  /// No Google session — show the sign-in screen.
  signedOut,

  /// Google session exists but no operator doc found.
  unauthorized,

  /// Operator doc found and valid — grant scoped access.
  authorized,

  /// Operator doc was deleted while signed in.
  permissionRevoked,
}

/// Holds the operator's resolved state after sign-in.
class OpsAuthState {
  const OpsAuthState({
    required this.status,
    this.user,
    this.operator,
  });

  final OpsAuthStatus status;
  final AppUser? user;
  final Operator? operator;

  /// Factory for the initial loading state.
  static const loading = OpsAuthState(status: OpsAuthStatus.loading);

  /// Factory for signed-out state.
  static const signedOut = OpsAuthState(status: OpsAuthStatus.signedOut);
}

/// Auth controller provider for the ops app.
final opsAuthControllerProvider =
    AsyncNotifierProvider<OpsAuthController, OpsAuthState>(
  OpsAuthController.new,
);

/// The ops auth controller. Manages:
/// 1. Google sign-in via AuthProvider
/// 2. Operator doc lookup via OperatorRepo
/// 3. Reactive operator doc watching (deletion detection)
/// 4. Sign-out with local storage cleanup
class OpsAuthController extends AsyncNotifier<OpsAuthState> {
  static final Logger _log = Logger('OpsAuthController');

  StreamSubscription<Operator?>? _operatorWatchSub;

  @override
  Future<OpsAuthState> build() async {
    // Clean up operator watch when provider is disposed.
    ref.onDispose(() {
      _operatorWatchSub?.cancel();
    });

    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    final currentUser = authProvider.currentUser;

    if (currentUser == null ||
        currentUser.tier == AuthTier.signedOut ||
        currentUser.isAnonymous) {
      return OpsAuthState.signedOut;
    }

    // User has a persisted Google session — check operator doc.
    return _resolveOperator(currentUser);
  }

  /// Trigger the Google sign-in flow and resolve operator status.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final authProvider = ref.read(shopkeeperAuthProviderInstance);
      final user = await authProvider.signInWithGoogle();
      return _resolveOperator(user);
    });
  }

  /// Sign out: cancel watches, clear local storage, reset state.
  Future<void> signOut() async {
    _operatorWatchSub?.cancel();
    _operatorWatchSub = null;

    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    await authProvider.signOut();

    // Clear any cached operator/task data from local storage.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    state = const AsyncValue.data(OpsAuthState.signedOut);
  }

  /// Look up the operator doc and start watching for live changes.
  /// Role is resolved from ID-token claims (matching Firestore rule layer);
  /// the Operator doc provides displayName, email, joinedAt, permissions.
  Future<OpsAuthState> _resolveOperator(AppUser user) async {
    final authProvider = ref.read(shopkeeperAuthProviderInstance);
    final shopIdProvider = ref.read(shopIdProviderProvider);
    final firestore = FirebaseFirestore.instance;
    final operatorRepo = OperatorRepo(
      firestore: firestore,
      shopIdProvider: shopIdProvider,
    );

    // Resolve role from token claims — this is what Firestore security rules
    // see on `request.auth.token.role`, so it is the authoritative source.
    final claims = await authProvider.getTokenClaims(forceRefresh: true);
    final roleStr = claims['role'] as String? ?? '';
    final role = OperatorRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () {
        _log.warning(
          'token claim "role" missing or unrecognised '
          '(got: "$roleStr") for uid=${user.uid} — falling back to beta',
        );
        return OperatorRole.beta;
      },
    );

    try {
      final op = await operatorRepo.getByUid(user.uid);

      if (op == null) {
        _log.info('operator doc not found for uid=${user.uid} — unauthorized');
        return OpsAuthState(
          status: OpsAuthStatus.unauthorized,
          user: user,
        );
      }

      _log.info(
        'operator resolved: uid=${user.uid} role=${role.name} (from claims)',
      );

      // Touch lastActiveAt for burnout telemetry (non-blocking).
      unawaited(operatorRepo.touchLastActive(user.uid));

      // Start watching the operator doc for live deletions / role changes.
      _startOperatorWatch(operatorRepo, user.uid);

      return OpsAuthState(
        status: OpsAuthStatus.authorized,
        user: user,
        // Role from token claims; rest (displayName, email, joinedAt,
        // permissions) from the Operator doc.
        operator: op.copyWith(role: role),
      );
    } on OperatorRepoException catch (e) {
      if (e.code == 'permission-denied') {
        return OpsAuthState(
          status: OpsAuthStatus.permissionRevoked,
          user: user,
        );
      }
      rethrow;
    }
  }

  /// Watch the operator doc for live deletions. If the doc disappears
  /// while the user is signed in, transition to permissionRevoked.
  void _startOperatorWatch(OperatorRepo repo, String uid) {
    _operatorWatchSub?.cancel();
    _operatorWatchSub = repo.watchByUid(uid).listen(
      (op) {
        if (op == null) {
          _log.warning('operator doc deleted for uid=$uid — revoking access');
          state = AsyncValue.data(
            OpsAuthState(
              status: OpsAuthStatus.permissionRevoked,
              user: state.value?.user,
            ),
          );
        }
      },
      onError: (Object error) {
        _log.warning('operator watch error for uid=$uid: $error');
        if (error is FirebaseException && error.code == 'permission-denied') {
          state = AsyncValue.data(
            OpsAuthState(
              status: OpsAuthStatus.permissionRevoked,
              user: state.value?.user,
            ),
          );
        }
      },
    );
  }
}
