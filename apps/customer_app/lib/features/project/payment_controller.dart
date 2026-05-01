// =============================================================================
// PaymentController â€” Riverpod controller managing the C3.5 UPI payment flow.
//
// State machine: idle â†’ launching â†’ awaitingReturn â†’ recording â†’ paid | error
//
// Per C3.5:
//   AC #1: UPI primary CTA + "other ways" secondary link
//   AC #2: UPI deep link via url_launcher
//   AC #5: committed â†’ paid Firestore transaction (Triple Zero re-verified)
//   AC #8: Triple Zero UPI invariant (am= == totalAmount, pa= == shop.upiVpa)
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stages of the payment flow.
///
/// **Phase 4 (2026-05-01):** the previously misleading `paid` value was
/// renamed to `submitted` — the customer's flow finishing does NOT mean
/// the project's state is `ProjectState.paid`. Under Phase 3 the resulting
/// project state may be:
///   - `awaiting_verification` (UPI / bank-transfer claim — operator must
///     still confirm via `applyOperatorMarkPaidPatch`)
///   - `committed` (COD self-tag — operator marks paid at cash collection)
///   - `paid` (only via the future PSP webhook path; not reachable today)
///
/// `payment_screen.dart` `_successHeadline` branches on the actual project
/// state to render the right copy, so behaviour is unchanged. Issue #2
/// tracked the rename; this enum is the resolution.
///
/// A `@Deprecated` static getter `paid` is kept for one release so any
/// in-flight branch with `PaymentFlowStage.paid` callsites still compiles.
/// Removed in Phase 5.
enum PaymentFlowStage {
  /// Ready — UPI button visible.
  idle,

  /// UPI intent launching.
  launching,

  /// UPI app opened — waiting for the customer to return.
  awaitingReturn,

  /// Recording payment in Firestore.
  recording,

  /// The customer's flow finished. Despite the historical name `paid`, the
  /// project may be in `awaiting_verification`, `committed` (COD), or `paid`
  /// — see enum docstring.
  submitted,

  /// Something failed.
  error;

  /// Phase 4 deprecation alias for the historical `paid` value. Kept for
  /// one release per Phase 4 plan §D1. Remove in Phase 5.
  ///
  /// Dart 3 enhanced-enum form: a static getter inside the enum body lets
  /// `PaymentFlowStage.paid` resolve to `PaymentFlowStage.submitted`
  /// without polluting the value set or introducing an extension.
  @Deprecated('Renamed to PaymentFlowStage.submitted in Phase 4. '
      'Will be removed in Phase 5.')
  static PaymentFlowStage get paid => PaymentFlowStage.submitted;
}

/// Immutable state for the payment flow.
class PaymentFlowState {
  const PaymentFlowState({
    required this.stage,
    this.project,
    this.errorMessage,
  });

  final PaymentFlowStage stage;
  final Project? project;
  final String? errorMessage;

  PaymentFlowState copyWith({
    PaymentFlowStage? stage,
    Project? project,
    String? errorMessage,
  }) {
    return PaymentFlowState(
      stage: stage ?? this.stage,
      project: project ?? this.project,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for the payment controller, scoped to a specific project.
final paymentControllerProvider =
    AsyncNotifierProvider.family<PaymentController, PaymentFlowState, String>(
  PaymentController.new,
);

class PaymentController extends FamilyAsyncNotifier<PaymentFlowState, String> {
  static final Logger _log = Logger('PaymentController');

  @override
  Future<PaymentFlowState> build(String arg) async {
    // Load the committed project.
    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );
    final project = await projectRepo.getById(arg);

    return PaymentFlowState(
      stage: PaymentFlowStage.idle,
      project: project,
    );
  }

  String get _projectId => arg;

  /// Launch UPI intent. Constructs the deep link per C3.5 AC #2 + AC #8.
  Future<void> launchUpiPayment({
    required String shopVpa,
    required String shopName,
    required int totalAmount,
  }) async {
    state = AsyncData(PaymentFlowState(
      stage: PaymentFlowStage.launching,
      project: state.valueOrNull?.project,
    ));

    // Build the UPI URI â€” Triple Zero invariant enforced by the builder.
    final upiUri = UpiIntentBuilder.build(
      shopVpa: shopVpa,
      shopName: shopName,
      totalAmount: totalAmount,
      projectId: _projectId,
    );

    _log.info('launching UPI intent: $upiUri');

    try {
      final canLaunch = await canLaunchUrl(upiUri);
      if (!canLaunch) {
        // C3.5 edge case #1: no UPI app installed.
        state = AsyncData(PaymentFlowState(
          stage: PaymentFlowStage.error,
          project: state.valueOrNull?.project,
          errorMessage: 'noUpiApp',
        ));
        return;
      }

      await launchUrl(upiUri, mode: LaunchMode.externalApplication);

      // After launching, we transition to awaitingReturn.
      // When the customer returns to the app, they tap "I paid" to
      // trigger the Firestore transition. (Full UPI callback parsing
      // is a depth-story enhancement â€” WS uses manual confirmation.)
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.awaitingReturn,
        project: state.valueOrNull?.project,
      ));
    } on Exception catch (e) {
      _log.warning('UPI launch failed: $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: 'launchFailed',
      ));
    }
  }

  /// Customer selects COD. Transition committed â†’ delivering (C3.6).
  Future<void> selectCod() async {
    state = AsyncData(PaymentFlowState(
      stage: PaymentFlowStage.recording,
      project: state.valueOrNull?.project,
    ));

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    try {
      await projectRepo.applyCustomerCodPatch(
        _projectId,
        const ProjectCustomerCodPatch(),
      );
      final updated = await projectRepo.getById(_projectId);
      _log.info('COD selected: $_projectId');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.submitted,
        project: updated,
      ));
    } on ProjectRepoException catch (e) {
      _log.warning('COD selection failed: $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: e.message,
      ));
    } on Exception catch (e) {
      _log.warning('COD failed (network/unknown): $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: 'unknown',
      ));
    }
  }

  /// Customer self-reports bank transfer. Transition committed â†’ awaiting_verification (C3.7).
  Future<void> selectBankTransfer() async {
    state = AsyncData(PaymentFlowState(
      stage: PaymentFlowStage.recording,
      project: state.valueOrNull?.project,
    ));

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    try {
      await projectRepo.applyCustomerBankTransferPatch(
        _projectId,
        const ProjectCustomerBankTransferPatch(),
      );
      final updated = await projectRepo.getById(_projectId);
      _log.info('bank transfer reported: $_projectId');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.submitted,
        project: updated,
      ));
    } on ProjectRepoException catch (e) {
      _log.warning('bank transfer failed: $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: e.message,
      ));
    } on Exception catch (e) {
      _log.warning('bank transfer failed (network/unknown): $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: 'unknown',
      ));
    }
  }

  /// Customer confirms UPI payment was successful. Record in Firestore.
  Future<void> confirmPayment({String? customerVpa}) async {
    state = AsyncData(PaymentFlowState(
      stage: PaymentFlowStage.recording,
      project: state.valueOrNull?.project,
    ));

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    try {
      await projectRepo.applyCustomerPaymentPatch(
        _projectId,
        ProjectCustomerPaymentPatch(customerVpa: customerVpa),
      );

      // Read the paid project for confirmation.
      final paid = await projectRepo.getById(_projectId);

      _log.info('payment recorded: $_projectId');

      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.submitted,
        project: paid,
      ));
    } on ProjectRepoException catch (e) {
      _log.warning('payment recording failed: $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: e.message,
      ));
    } on Exception catch (e) {
      _log.warning('payment failed (network/unknown): $e');
      state = AsyncData(PaymentFlowState(
        stage: PaymentFlowStage.error,
        project: state.valueOrNull?.project,
        errorMessage: 'unknown',
      ));
    }
  }

  /// Reset to idle for retry.
  void retry() {
    state = AsyncData(PaymentFlowState(
      stage: PaymentFlowStage.idle,
      project: state.valueOrNull?.project,
    ));
  }
}
