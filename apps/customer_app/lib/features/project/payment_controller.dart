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
enum PaymentFlowStage {
  /// Ready â€” UPI button visible.
  idle,

  /// UPI intent launching.
  launching,

  /// UPI app opened â€” waiting for the customer to return.
  awaitingReturn,

  /// Recording payment in Firestore.
  recording,

  /// Payment succeeded â€” Project is now paid.
  paid,

  /// Something failed.
  error,
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
final paymentControllerProvider = AsyncNotifierProvider.family<
    PaymentController, PaymentFlowState, String>(
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
        stage: PaymentFlowStage.paid,
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
        stage: PaymentFlowStage.paid,
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
        stage: PaymentFlowStage.paid,
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
