// =============================================================================
// CommitController — Riverpod controller managing the C3.4 commit flow.
//
// State machine: idle → enteringPhone → awaitingOtp → committing →
//                committed | error
//
// Per C3.4:
//   AC #1: Prominent commit button when state is draft/negotiating
//   AC #2: OTP upgrade if otpAtCommitEnabled && anonymous
//   AC #3: Firestore transaction with Triple Zero invariant
//   AC #5: Post-commit confirmation → payment CTA
//
// Per Standing Rule 11: uses ProjectCustomerCommitPatch (typed cross-
// partition exception, same pattern as ProjectCustomerCancelPatch).
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';

import 'package:customer_app/main.dart';

/// Stages of the commit flow.
enum CommitFlowStage {
  /// Ready to start — the commit button is visible.
  idle,

  /// Customer is entering their phone number for OTP.
  enteringPhone,

  /// OTP sent — waiting for the customer to enter the code.
  awaitingOtp,

  /// Phone verified (or OTP skipped), now writing the commit transaction.
  committing,

  /// Commit succeeded — show confirmation + payment CTA.
  committed,

  /// Something failed — the customer can retry.
  error,
}

/// Immutable state for the commit flow.
class CommitFlowState {
  const CommitFlowState({
    required this.stage,
    this.verificationId,
    this.phoneE164,
    this.errorMessage,
    this.committedProject,
  });

  /// Current stage of the flow.
  final CommitFlowStage stage;

  /// Held between requestPhoneVerification → confirmPhoneVerification.
  final String? verificationId;

  /// Phone number the customer entered (E.164).
  final String? phoneE164;

  /// Human-readable error for the UI.
  final String? errorMessage;

  /// The committed Project snapshot (post-commit read).
  final Project? committedProject;

  CommitFlowState copyWith({
    CommitFlowStage? stage,
    String? verificationId,
    String? phoneE164,
    String? errorMessage,
    Project? committedProject,
  }) {
    return CommitFlowState(
      stage: stage ?? this.stage,
      verificationId: verificationId ?? this.verificationId,
      phoneE164: phoneE164 ?? this.phoneE164,
      errorMessage: errorMessage ?? this.errorMessage,
      committedProject: committedProject ?? this.committedProject,
    );
  }
}

/// Provider for the commit controller, scoped to a specific project.
final commitControllerProvider = AsyncNotifierProvider.family<
    CommitController, CommitFlowState, String>(
  CommitController.new,
);

class CommitController extends FamilyAsyncNotifier<CommitFlowState, String> {
  static final Logger _log = Logger('CommitController');

  @override
  Future<CommitFlowState> build(String arg) async {
    return const CommitFlowState(stage: CommitFlowStage.idle);
  }

  String get _projectId => arg;

  /// Start the commit flow. If the customer is anonymous and OTP is enabled,
  /// transitions to enteringPhone. Otherwise skips to committing.
  Future<void> startCommit() async {
    final authProvider = ref.read(authProviderInstanceProvider);
    final user = authProvider.currentUser;

    if (user == null) {
      state = AsyncData(const CommitFlowState(
        stage: CommitFlowStage.error,
        errorMessage: 'Not signed in',
      ));
      return;
    }

    // Check if OTP is needed: anonymous user + otpAtCommitEnabled.
    // For Walking Skeleton, otpAtCommitEnabled defaults to true via
    // RuntimeFeatureFlags.safeDefaults (no KillSwitchListener wired yet).
    final needsOtp = user.isAnonymous;

    if (needsOtp) {
      state = AsyncData(const CommitFlowState(
        stage: CommitFlowStage.enteringPhone,
      ));
    } else {
      // Already phone-verified or OTP disabled — skip to commit.
      await _executeCommit(
        customerPhone: user.phoneNumber,
        customerDisplayName: user.displayName,
      );
    }
  }

  /// Customer entered their phone number. Send the OTP.
  Future<void> sendOtp(String phoneE164) async {
    final authProvider = ref.read(authProviderInstanceProvider);

    try {
      final result = await authProvider.requestPhoneVerification(phoneE164);
      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.awaitingOtp,
        verificationId: result.verificationId,
        phoneE164: phoneE164,
      ));
    } on AuthException catch (e) {
      _log.warning('OTP send failed: $e');
      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.error,
        errorMessage: _mapAuthError(e),
        phoneE164: phoneE164,
      ));
    }
  }

  /// Customer entered the OTP code. Verify via PhoneUpgradeCoordinator,
  /// then execute the commit transaction.
  Future<void> verifyOtpAndCommit(String otpCode) async {
    final current = state.valueOrNull;
    if (current == null ||
        current.verificationId == null ||
        current.phoneE164 == null) {
      return;
    }

    state = AsyncData(current.copyWith(stage: CommitFlowStage.committing));

    final authProvider = ref.read(authProviderInstanceProvider);
    final shopId = ref.read(shopIdProviderProvider).shopId;
    final customerRepo = CustomerRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    final coordinator = PhoneUpgradeCoordinator(
      authProvider: authProvider,
      customerRepo: customerRepo,
    );

    try {
      final result = await coordinator.upgradeAnonymousToPhone(
        verificationId: current.verificationId!,
        otpCode: otpCode,
        phoneE164: current.phoneE164!,
      );

      // Log analytics for the upgrade path.
      Observability.analytics.logEvent(
        name: AnalyticsEvents.authPhoneVerified,
        parameters: PhoneUpgradeAnalyticsParams.forResult(result),
      );

      // Now execute the commit transaction.
      await _executeCommit(
        customerPhone: current.phoneE164,
        customerDisplayName: result.user.displayName,
      );
    } on AuthException catch (e) {
      _log.warning('OTP verify failed: $e');
      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.error,
        errorMessage: _mapAuthError(e),
        verificationId: current.verificationId,
        phoneE164: current.phoneE164,
      ));
    }
  }

  /// Execute the Firestore commit transaction via ProjectRepo.
  Future<void> _executeCommit({
    String? customerPhone,
    String? customerDisplayName,
  }) async {
    final current = state.valueOrNull;
    state = AsyncData(CommitFlowState(
      stage: CommitFlowStage.committing,
      verificationId: current?.verificationId,
      phoneE164: current?.phoneE164 ?? customerPhone,
    ));

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    try {
      await projectRepo.applyCustomerCommitPatch(
        _projectId,
        ProjectCustomerCommitPatch(
          customerPhone: customerPhone,
          customerDisplayName: customerDisplayName,
        ),
      );

      // Read the committed project for the confirmation screen.
      // If this read fails, the commit still succeeded — show confirmation
      // with whatever data we have.
      Project? committed;
      try {
        committed = await projectRepo.getById(_projectId);
      } on Exception catch (e) {
        _log.warning('post-commit read failed (commit succeeded): $e');
      }

      _log.info('project committed: $_projectId');

      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.committed,
        phoneE164: customerPhone,
        committedProject: committed,
      ));
    } on ProjectRepoException catch (e) {
      _log.warning('commit transaction failed: $e');
      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.error,
        errorMessage: e.message,
        phoneE164: customerPhone,
      ));
    } on Exception catch (e) {
      _log.warning('commit failed (network/unknown): $e');
      state = AsyncData(CommitFlowState(
        stage: CommitFlowStage.error,
        errorMessage: 'unknown',
        phoneE164: customerPhone,
      ));
    }
  }

  /// Reset to idle so the customer can retry.
  void retry() {
    state = const AsyncData(CommitFlowState(stage: CommitFlowStage.idle));
  }

  /// Map AuthException codes to user-facing error keys.
  /// The caller renders these via AppStrings.
  static String _mapAuthError(AuthException e) {
    return switch (e.code) {
      AuthErrorCode.invalidCode => 'otpInvalidCode',
      AuthErrorCode.codeExpired => 'otpCodeExpired',
      AuthErrorCode.invalidPhoneNumber => 'invalidPhoneNumber',
      AuthErrorCode.network => 'network',
      AuthErrorCode.quotaExhausted => 'quotaExhausted',
      _ => 'unknown',
    };
  }
}
