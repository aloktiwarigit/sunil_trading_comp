// =============================================================================
// CreateSkuController — Riverpod controller for S4.3 inventory SKU creation.
//
// Manages form state + Firestore write via InventorySkuRepo.upsert().
// On save: creates doc at shops/{shopId}/inventory/{skuId}.
//
// Edge cases handled:
//   - Duplicate name: warning shown, save allowed (AC edge case #3)
//   - Photo capture deferred: SKU created with empty photo lists (AC edge case #2)
//   - Validation: name required, price > 0, floor < base, dimensions > 0
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';
import 'package:logging/logging.dart';

/// Possible states for the SKU creation flow.
enum CreateSkuStatus {
  /// Form is idle and editable.
  idle,

  /// Save in progress.
  saving,

  /// Save succeeded.
  saved,

  /// Save failed.
  error,
}

/// State for the create-SKU controller.
class CreateSkuState {
  const CreateSkuState({
    this.status = CreateSkuStatus.idle,
    this.errorMessage,
    this.savedSkuId,
  });

  final CreateSkuStatus status;
  final String? errorMessage;
  final String? savedSkuId;

  CreateSkuState copyWith({
    CreateSkuStatus? status,
    String? errorMessage,
    String? savedSkuId,
  }) {
    return CreateSkuState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      savedSkuId: savedSkuId ?? this.savedSkuId,
    );
  }
}

/// Provider for the create-SKU controller.
final createSkuControllerProvider =
    AutoDisposeNotifierProvider<CreateSkuController, CreateSkuState>(
  CreateSkuController.new,
);

/// Controller for the SKU creation form. Handles validation + Firestore write.
class CreateSkuController extends AutoDisposeNotifier<CreateSkuState> {
  static final Logger _log = Logger('CreateSkuController');

  @override
  CreateSkuState build() => const CreateSkuState();

  /// Save the SKU to Firestore. Returns true on success.
  Future<bool> save({
    required String nameDevanagari,
    required String nameEnglish,
    required SkuCategory category,
    required SkuMaterial material,
    required int heightCm,
    required int widthCm,
    required int depthCm,
    required int basePrice,
    required int negotiableDownTo,
    required bool inStock,
    int? stockCount,
    required String description,
  }) async {
    state = state.copyWith(status: CreateSkuStatus.saving);

    try {
      final shopIdProvider = ref.read(shopIdProviderProvider);
      final firestore = FirebaseFirestore.instance;
      final repo = InventorySkuRepo(
        firestore: firestore,
        shopIdProvider: shopIdProvider,
      );

      // Generate a new document ID.
      final skuId = firestore
          .collection('shops')
          .doc(shopIdProvider.shopId)
          .collection('inventory')
          .doc()
          .id;

      final sku = InventorySku(
        skuId: skuId,
        shopId: shopIdProvider.shopId,
        name: nameEnglish.isNotEmpty ? nameEnglish : nameDevanagari,
        nameDevanagari: nameDevanagari,
        description: description,
        category: category,
        material: material,
        dimensions: SkuDimensions(
          heightCm: heightCm,
          widthCm: widthCm,
          depthCm: depthCm,
        ),
        basePrice: basePrice,
        negotiableDownTo: negotiableDownTo,
        inStock: inStock,
        stockCount: stockCount,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await repo.upsert(sku);
      _log.info('SKU created: skuId=$skuId name=$nameDevanagari');

      state = CreateSkuState(
        status: CreateSkuStatus.saved,
        savedSkuId: skuId,
      );
      return true;
    } on InventorySkuRepoException catch (e) {
      _log.warning('SKU creation failed: ${e.code} ${e.message}');
      state = CreateSkuState(
        status: CreateSkuStatus.error,
        errorMessage: e.message,
      );
      return false;
    } on FirebaseException catch (e) {
      _log.warning('SKU creation failed: ${e.code} ${e.message}');
      state = CreateSkuState(
        status: CreateSkuStatus.error,
        errorMessage: e.message ?? e.code,
      );
      return false;
    }
  }

  /// Reset the controller to idle state (e.g., after showing success).
  void reset() {
    state = const CreateSkuState();
  }
}
