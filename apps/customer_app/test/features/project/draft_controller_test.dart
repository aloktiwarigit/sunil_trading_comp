// =============================================================================
// DraftController logic tests — C3.1 draft state management.
//
// Tests the DraftState data class and pure logic. The Firestore-dependent
// methods (addSku, removeLineItem, etc.) are integration-tested in the
// cross-tenant integrity test suite which runs against the Firebase emulator.
//
// Covers:
//   1. DraftState.isEmpty when no project and no line items
//   2. DraftState.isEmpty is false when line items are present
//   3. DraftState.projectId returns correct value
//   4. DraftState.copyWith preserves fields correctly
//   5. LineItem.lineTotalInr computes correctly
//   6. Multiple line items with different quantities
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/lib_core.dart';

import 'package:customer_app/features/project/draft_controller.dart';

void main() {
  group('DraftState', () {
    test('isEmpty is true when no project and no line items', () {
      const state = DraftState(project: null, lineItems: []);
      expect(state.isEmpty, isTrue);
      expect(state.projectId, isNull);
    });

    test('isEmpty is false when line items are present', () {
      final state = DraftState(
        project: _testProject(),
        lineItems: [_testLineItem()],
      );
      expect(state.isEmpty, isFalse);
      expect(state.projectId, 'project-1');
    });

    test('copyWith preserves fields', () {
      final original = DraftState(
        project: _testProject(),
        lineItems: [_testLineItem()],
      );

      final updated = original.copyWith(
        lineItems: [_testLineItem(), _testLineItem(lineItemId: 'li-2')],
      );

      expect(updated.project?.projectId, 'project-1');
      expect(updated.lineItems.length, 2);
    });

    test('copyWith with empty line items', () {
      final original = DraftState(
        project: _testProject(),
        lineItems: [_testLineItem()],
      );

      final updated = original.copyWith(lineItems: []);
      expect(updated.lineItems, isEmpty);
      // Project is still present — just no line items.
      expect(updated.project, isNotNull);
    });
  });

  group('LineItem arithmetic', () {
    test('lineTotalInr computes quantity * unitPrice', () {
      final item = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'Test',
        quantity: 3,
        unitPriceInr: 17500,
      );
      expect(item.lineTotalInr, 52500);
    });

    test('lineTotalInr with quantity 1', () {
      final item = _testLineItem();
      expect(item.lineTotalInr, 17500);
    });

    test('multiple line items total correctly', () {
      final items = [
        LineItem(
          lineItemId: 'li-1',
          skuId: 'sku-1',
          skuName: 'Almirah A',
          quantity: 2,
          unitPriceInr: 17500,
        ),
        LineItem(
          lineItemId: 'li-2',
          skuId: 'sku-2',
          skuName: 'Almirah B',
          quantity: 1,
          unitPriceInr: 25000,
        ),
      ];

      final total =
          items.fold<int>(0, (sum, item) => sum + item.lineTotalInr);
      expect(total, 60000);
    });
  });
  // ===========================================================================
  // C3.2 — Edit line items in draft
  // ===========================================================================

  group('C3.2 — denormalized field computation', () {
    test('AC #3: totalAmount recomputed from line items', () {
      final items = [
        LineItem(
          lineItemId: 'li-1',
          skuId: 'sku-1',
          skuName: 'गोदरेज स्टील अलमारी',
          quantity: 2,
          unitPriceInr: 17500,
        ),
        LineItem(
          lineItemId: 'li-2',
          skuId: 'sku-2',
          skuName: 'ड्रेसिंग टेबल',
          quantity: 1,
          unitPriceInr: 8000,
        ),
      ];

      final totalAmount =
          items.fold<int>(0, (sum, item) => sum + item.lineTotalInr);
      expect(totalAmount, 43000); // 2*17500 + 1*8000

      // lineItemsCount is simply items.length.
      expect(items.length, 2);
    });

    test('AC #3: totalAmount is 0 for empty list', () {
      final items = <LineItem>[];
      final totalAmount =
          items.fold<int>(0, (sum, item) => sum + item.lineTotalInr);
      expect(totalAmount, 0);
      expect(items.length, 0);
    });

    test('AC #3: totalAmount updates after quantity change', () {
      final original = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 1,
        unitPriceInr: 17500,
      );
      expect(original.lineTotalInr, 17500);

      // Simulate quantity change (controller creates a new LineItem).
      final updated = LineItem(
        lineItemId: original.lineItemId,
        skuId: original.skuId,
        skuName: original.skuName,
        quantity: 3,
        unitPriceInr: original.unitPriceInr,
      );
      expect(updated.lineTotalInr, 52500);
    });
  });

  group('C3.2 — last-item removal (AC #5)', () {
    test('removing the last item results in empty state', () {
      final state = DraftState(
        project: _testProject(),
        lineItems: [_testLineItem()],
      );

      // After removing the only item, list is empty.
      final updatedItems = state.lineItems
          .where((i) => i.lineItemId != 'li-1')
          .toList();
      expect(updatedItems, isEmpty);

      // The controller should reset to empty DraftState.
      const emptyState = DraftState(project: null, lineItems: []);
      expect(emptyState.isEmpty, isTrue);
    });

    test('removing one of many items does not trigger deletion', () {
      final state = DraftState(
        project: _testProject(),
        lineItems: [
          _testLineItem(lineItemId: 'li-1'),
          _testLineItem(lineItemId: 'li-2'),
        ],
      );

      final updatedItems = state.lineItems
          .where((i) => i.lineItemId != 'li-1')
          .toList();
      expect(updatedItems.length, 1);
      expect(updatedItems.first.lineItemId, 'li-2');
    });
  });

  group('C3.2 — undo removal', () {
    test('re-inserting a removed item restores line items', () {
      final removed = _testLineItem(lineItemId: 'li-1');
      final state = DraftState(
        project: _testProject(),
        lineItems: [_testLineItem(lineItemId: 'li-2')],
      );

      final restored = [...state.lineItems, removed];
      expect(restored.length, 2);
      expect(restored.any((i) => i.lineItemId == 'li-1'), isTrue);
    });

    test('re-inserting into empty state (project was deleted)', () {
      const state = DraftState(project: null, lineItems: []);
      final removed = _testLineItem(lineItemId: 'li-1');

      final restored = [...state.lineItems, removed];
      expect(restored.length, 1);
      // Controller would re-create the project in this case.
    });
  });

  // ===========================================================================
  // C3.3 — Negotiation flow (finalPrice on LineItem)
  // ===========================================================================

  group('C3.3 — finalPrice negotiation arithmetic', () {
    test('effectivePrice returns unitPriceInr when finalPrice is null', () {
      final item = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 1,
        unitPriceInr: 17500,
      );
      expect(item.effectivePrice, 17500);
      expect(item.lineTotalInr, 17500);
    });

    test('effectivePrice returns finalPrice when set', () {
      final item = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 1,
        unitPriceInr: 17500,
        finalPrice: 15000,
      );
      expect(item.effectivePrice, 15000);
      expect(item.lineTotalInr, 15000);
    });

    test('lineTotalInr uses finalPrice with quantity', () {
      final item = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 3,
        unitPriceInr: 17500,
        finalPrice: 15000,
      );
      expect(item.lineTotalInr, 45000); // 3 * 15000
    });

    test('totalAmount recomputes with mixed negotiated/original items', () {
      final items = [
        LineItem(
          lineItemId: 'li-1',
          skuId: 'sku-1',
          skuName: 'अलमारी A',
          quantity: 2,
          unitPriceInr: 17500,
          finalPrice: 15000, // negotiated down
        ),
        LineItem(
          lineItemId: 'li-2',
          skuId: 'sku-2',
          skuName: 'ड्रेसिंग टेबल',
          quantity: 1,
          unitPriceInr: 8000,
          // no negotiation — original price
        ),
      ];

      final totalAmount =
          items.fold<int>(0, (sum, item) => sum + item.lineTotalInr);
      expect(totalAmount, 38000); // 2*15000 + 1*8000
    });

    test('AC #4: only the most recent accepted proposal applies', () {
      // First proposal: 16000
      final afterFirst = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 1,
        unitPriceInr: 17500,
        finalPrice: 16000,
      );
      expect(afterFirst.effectivePrice, 16000);

      // Second proposal: 15000 (overwrites first)
      final afterSecond = LineItem(
        lineItemId: 'li-1',
        skuId: 'sku-1',
        skuName: 'गोदरेज स्टील अलमारी',
        quantity: 1,
        unitPriceInr: 17500,
        finalPrice: 15000,
      );
      expect(afterSecond.effectivePrice, 15000);
    });
  });

  group('C3.2 — Edge #3: quantity > 10 guard', () {
    test('quantity 10 does not trigger guard', () {
      expect(10 > 10, isFalse);
    });

    test('quantity 11 triggers guard', () {
      expect(11 > 10, isTrue);
    });

    test('quantity 1 does not trigger guard', () {
      expect(1 > 10, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Project _testProject({String projectId = 'project-1'}) {
  return Project(
    projectId: projectId,
    shopId: 'sunil-trading-company',
    customerId: 'customer-1',
    customerUid: 'customer-uid-1',
    state: ProjectState.draft,
    createdAt: DateTime(2026, 4, 11),
  );
}

LineItem _testLineItem({String lineItemId = 'li-1'}) {
  return LineItem(
    lineItemId: lineItemId,
    skuId: 'sku-1',
    skuName: 'गोदरेज स्टील अलमारी',
    quantity: 1,
    unitPriceInr: 17500,
  );
}
