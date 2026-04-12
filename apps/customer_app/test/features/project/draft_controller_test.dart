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
