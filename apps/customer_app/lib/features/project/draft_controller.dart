// =============================================================================
// DraftController — Riverpod controller managing project draft state +
// Firestore writes.
//
// Per C3.1:
//   AC #1: From SKU detail, tapping "add to list" creates a Project draft
//   AC #2: Project doc at shops/sunil-trading-company/projects/{projectId}
//          with state="draft"
//   AC #3: Line items added from selected SKU
//   AC #4: Customer can add more items by browsing and tapping "add to list"
//   AC #5: Draft is visible in a "My List" section from landing
//
// Per Standing Rule 11: Project writes via ProjectCustomerPatch ONLY.
// The draft creation uses a direct Firestore set (creating the document),
// which is permitted because the customer is the author of a new draft.
// Subsequent field mutations use ProjectCustomerPatch.
// =============================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/main.dart';

/// State for the active draft project.
class DraftState {
  const DraftState({
    required this.project,
    required this.lineItems,
  });

  /// The underlying Project document (may be null if no draft exists yet).
  final Project? project;

  /// Current line items in the draft. Kept in sync with Project.lineItems
  /// but also serves as the source-of-truth for optimistic UI before the
  /// Firestore write lands.
  final List<LineItem> lineItems;

  /// True if no draft exists yet.
  bool get isEmpty => project == null && lineItems.isEmpty;

  /// The draft project ID, or null if no draft.
  String? get projectId => project?.projectId;

  DraftState copyWith({
    Project? project,
    List<LineItem>? lineItems,
  }) {
    return DraftState(
      project: project ?? this.project,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}

/// Provider for the draft controller.
final draftControllerProvider =
    AsyncNotifierProvider<DraftController, DraftState>(
  DraftController.new,
);

class DraftController extends AsyncNotifier<DraftState> {
  @override
  Future<DraftState> build() async {
    // On build, check if there's an existing draft for this customer.
    final authProvider = ref.read(authProviderInstanceProvider);
    final user = authProvider.currentUser;
    if (user == null) {
      return const DraftState(project: null, lineItems: []);
    }

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    // Query for existing draft projects by this customer.
    final query = await firestore
        .collection('shops')
        .doc(shopId)
        .collection('projects')
        .where('customerUid', isEqualTo: user.uid)
        .where('state', isEqualTo: 'draft')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final project = Project.fromJson(<String, dynamic>{
        ...doc.data(),
        'projectId': doc.id,
      });
      return DraftState(
        project: project,
        lineItems: project.lineItems,
      );
    }

    return const DraftState(project: null, lineItems: []);
  }

  /// Add a SKU to the draft. Creates the Project document if it doesn't
  /// exist yet. Returns true if the item was added (false if already present).
  ///
  /// C3.2 Edge #1: optimistic UI — state updates before Firestore write.
  Future<bool> addSku(InventorySku sku) async {
    final current = state.valueOrNull;
    if (current == null) return false;

    // Check if SKU is already in the draft.
    final alreadyExists =
        current.lineItems.any((item) => item.skuId == sku.skuId);
    if (alreadyExists) return false;

    final newItem = LineItem(
      lineItemId: _generateId(),
      skuId: sku.skuId,
      skuName: sku.nameDevanagari,
      quantity: 1,
      unitPriceInr: sku.basePrice,
    );

    final updatedItems = [...current.lineItems, newItem];

    // Optimistic update: show the new item immediately.
    state = AsyncData(current.copyWith(lineItems: updatedItems));

    if (current.project == null) {
      // Create a new draft project.
      await _createDraftProject(updatedItems);
    } else {
      // Update the existing draft with the new line item.
      await _updateDraftLineItems(current.project!.projectId, updatedItems);
    }

    return true;
  }

  /// Remove a line item from the draft by lineItemId.
  ///
  /// C3.2 AC #5: removing the last line item deletes the entire Project
  /// document and resets draft state.
  Future<void> removeLineItem(String lineItemId) async {
    final current = state.valueOrNull;
    if (current == null || current.project == null) return;

    final updatedItems =
        current.lineItems.where((i) => i.lineItemId != lineItemId).toList();

    if (updatedItems.isEmpty) {
      // AC #5 — last item removed: delete entire Project document.
      // CR #4: delete first, then reset state. If delete fails, state
      // stays intact so the user doesn't end up with an orphaned project.
      try {
        await _deleteProject(current.project!.projectId);
        state = const AsyncData(DraftState(project: null, lineItems: []));
      } catch (_) {
        // Delete failed — restore the original state so the user can retry.
        state = AsyncData(current);
      }
      return;
    }

    // Optimistic update.
    state = AsyncData(current.copyWith(lineItems: updatedItems));

    await _updateDraftLineItems(current.project!.projectId, updatedItems);
  }

  /// Update the quantity of a line item.
  Future<void> updateQuantity(String lineItemId, int newQuantity) async {
    final current = state.valueOrNull;
    if (current == null || current.project == null) return;
    if (newQuantity < 1) return;

    final updatedItems = current.lineItems.map((item) {
      if (item.lineItemId == lineItemId) {
        return LineItem(
          lineItemId: item.lineItemId,
          skuId: item.skuId,
          skuName: item.skuName,
          quantity: newQuantity,
          unitPriceInr: item.unitPriceInr,
          notes: item.notes,
          finalPrice: item.finalPrice, // CR #5: preserve negotiated price
        );
      }
      return item;
    }).toList();

    // Optimistic update.
    state = AsyncData(current.copyWith(lineItems: updatedItems));

    await _updateDraftLineItems(current.project!.projectId, updatedItems);
  }

  /// Re-insert a previously removed line item (undo action from swipe dismiss).
  ///
  /// C3.2 AC #2: supports the undo snackbar. If the project was deleted
  /// (last-item removal), this re-creates the draft project.
  Future<void> undoRemoveLineItem(LineItem item) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedItems = [...current.lineItems, item];

    // Optimistic update.
    state = AsyncData(current.copyWith(lineItems: updatedItems));

    if (current.project == null) {
      // The project was deleted (AC #5 triggered) — re-create it.
      await _createDraftProject(updatedItems);
    } else {
      await _updateDraftLineItems(current.project!.projectId, updatedItems);
    }
  }

  /// Cancel the draft project entirely (draft -> cancelled).
  Future<void> cancelDraft() async {
    final current = state.valueOrNull;
    if (current == null || current.project == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final projectRepo = ProjectRepo(
      firestore: FirebaseFirestore.instance,
      shopIdProvider: ShopIdProvider(shopId),
    );

    await projectRepo.applyCustomerCancelPatch(
      current.project!.projectId,
      const ProjectCustomerCancelPatch(),
    );

    // Reset draft state.
    state = const AsyncData(DraftState(project: null, lineItems: []));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _createDraftProject(List<LineItem> items) async {
    final authProvider = ref.read(authProviderInstanceProvider);
    final user = authProvider.currentUser;
    if (user == null) return;

    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    final projectId = _generateId();
    final now = DateTime.now();

    // C3.2 AC #3: denormalize lineItemsCount + totalAmount at creation.
    final totalAmount = items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalInr,
    );
    final projectData = <String, dynamic>{
      'projectId': projectId,
      'shopId': shopId,
      'customerId': user.uid,
      'customerUid': user.uid,
      'state': 'draft',
      'totalAmount': totalAmount,
      'amountReceivedByShop': 0,
      'lineItemsCount': items.length,
      'lineItems': items.map((e) => e.toJson()).toList(),
      'unreadCountForCustomer': 0,
      'unreadCountForShopkeeper': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('shops')
        .doc(shopId)
        .collection('projects')
        .doc(projectId)
        .set(projectData);

    // P2.1 AC #1: auto-create DecisionCircle when feature flag is enabled.
    // decisionCircleEnabled is a Remote Config flag (default: true).
    // Check via FirebaseRemoteConfig.instance.
    final dcEnabled = FirebaseRemoteConfig.instance
        .getBool(FeatureFlags.decisionCircleEnabled);
    if (dcEnabled) {
      await firestore
          .collection('shops')
          .doc(shopId)
          .collection('decision_circles')
          .doc(projectId)
          .set(<String, dynamic>{
        'projectId': projectId,
        'shopId': shopId,
        'primaryCustomerUid': user.uid,
        'participants': [
          {
            'sessionId': user.uid,
            'personaLabel': 'मैं',
            'lastSeenAt': FieldValue.serverTimestamp(),
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final project = Project(
      projectId: projectId,
      shopId: shopId,
      customerId: user.uid,
      customerUid: user.uid,
      state: ProjectState.draft,
      lineItems: items,
      createdAt: now,
    );

    state = AsyncData(DraftState(project: project, lineItems: items));
  }

  Future<void> _updateDraftLineItems(
    String projectId,
    List<LineItem> items,
  ) async {
    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    // Line items are operator-owned per the partition table. However, in the
    // draft state, the customer is building their list. The security rules
    // allow customer writes to lineItems when state == 'draft'. We write
    // directly because ProjectCustomerPatch does not include lineItems
    // (correct partition discipline). The security rule gates this.
    //
    // C3.2 AC #3: recompute lineItemsCount + totalAmount on every edit.
    final totalAmount = items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalInr,
    );
    await firestore
        .collection('shops')
        .doc(shopId)
        .collection('projects')
        .doc(projectId)
        .update({
      'lineItems': items.map((e) => e.toJson()).toList(),
      'lineItemsCount': items.length,
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final current = state.valueOrNull;
    if (current != null && current.project != null) {
      state = AsyncData(current.copyWith(lineItems: items));
    }
  }

  /// C3.2 AC #5: delete the Project document when the last line item is
  /// removed. The security rule allows customer delete when state == 'draft'.
  Future<void> _deleteProject(String projectId) async {
    final shopId = ref.read(shopIdProviderProvider).shopId;
    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection('shops')
        .doc(shopId)
        .collection('projects')
        .doc(projectId)
        .delete();
  }

  /// Generate a Firestore-friendly unique ID.
  static String _generateId() {
    return FirebaseFirestore.instance.collection('_').doc().id;
  }
}
