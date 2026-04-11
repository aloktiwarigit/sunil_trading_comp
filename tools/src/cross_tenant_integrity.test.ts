// =============================================================================
// cross_tenant_integrity.test.ts
//
// THE non-negotiable CI gate (PRD I6.4 + ADR-012 + R9 mitigation).
//
// Runs the actual `firestore.rules` file against the Firebase emulator and
// asserts that:
//   1. A shop_1 operator CANNOT read any shop_0 collection (every entity type)
//   2. A shop_1 operator CANNOT write to any shop_0 collection
//   3. A shop_1 operator CAN read its own shop_1 collections (no false positives)
//   4. The udhaar ledger rejects forbidden lending vocabulary at the rule layer
//      (interest, dueDate, overdueFee, etc. — ADR-010)
//   5. Anonymous users are scoped correctly
//
// NOTE on the Dart counterpart (packages/lib_core/test/cross_tenant_integrity_test.dart):
//   The SAD §6 pseudo-code samples a Dart test using FakeFirebaseFirestore.
//   FakeFirebaseFirestore does NOT actually enforce security rules — it
//   simulates the data layer only. This TS test is therefore the actual rules
//   enforcement test (uses @firebase/rules-unit-testing against a live
//   emulator). The Dart-side counterpart instead validates SHAPE invariants
//   (every model has a shopId field) — complementary, not duplicate.
//
// Run: cd tools && npm run test:rules
// CI:  .github/workflows/ci-cross-tenant-test.yml
// =============================================================================

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const PROJECT_ID = 'yugma-dukaan-rules-test';
const RULES_PATH = resolve(__dirname, '../../firestore.rules');

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // Seed shop_0 and shop_1 with one document of every entity type via the
  // privileged "withSecurityRulesDisabled" context.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    for (const shopId of ['shop_0', 'shop_1']) {
      // SAD v1.0.4 ADR-013: shopLifecycle = 'active' is the default state.
      await db.collection('shops').doc(shopId).set({
        shopId,
        brandName: `Synthetic Shop ${shopId}`,
        ownerUid: `op-${shopId}-owner`,
        shopLifecycle: 'active',
        shopLifecycleChangedAt: new Date(),
      });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('themeTokens')
        .doc('active')
        .set({ shopId, primaryColor: '#000', version: 1 });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('udhaarLedger')
        .doc('udh-1')
        .set({
          shopId,
          customerId: 'cust-1',
          recordedAmount: 10000,
          runningBalance: 10000,
          // SAD v1.0.4 RBI guardrail fields
          reminderOptInByBhaiya: false,
          reminderCountLifetime: 0,
          reminderCadenceDays: 14,
        });

      // SAD v1.0.4 §5 feedback sub-collection (S4.17 NPS + burnout).
      await db
        .collection('shops')
        .doc(shopId)
        .collection('feedback')
        .doc('fb-seed-nps')
        .set({
          feedbackId: 'fb-seed-nps',
          shopId,
          type: 'customer_nps',
          authorUid: `cust-${shopId}-uid`,
          authorRole: 'customer',
          score: 9,
          createdAt: new Date(),
        });

      await db.collection('operators').doc(`op-${shopId}-owner`).set({
        uid: `op-${shopId}-owner`,
        shopId,
        role: 'shopkeeper',
      });
    }
  });
});

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function ctxAsShopOperator(shopId: string) {
  return testEnv.authenticatedContext(`op-${shopId}-owner`, {
    shopId,
    role: 'shopkeeper',
    firebase: { sign_in_provider: 'google.com' },
  });
}

function ctxAsCustomer(shopId: string, uid = `cust-${shopId}-uid`) {
  return testEnv.authenticatedContext(uid, {
    shopId,
    firebase: { sign_in_provider: 'phone' },
  });
}

async function setShopLifecycle(
  shopId: string,
  lifecycle: 'active' | 'deactivating' | 'purge_scheduled' | 'purged',
): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection('shops')
      .doc(shopId)
      .update({ shopLifecycle: lifecycle });
  });
}

const ALL_SUB_COLLECTIONS = [
  'themeTokens',
  'featureFlags',
  'udhaarLedger',
  'feedback',
];

// -----------------------------------------------------------------------------
// Test cases — PRD I6.4 ACs #5–#7
// -----------------------------------------------------------------------------

describe('Cross-tenant integrity (rules.test)', () => {
  // ---- AC #5: cross-tenant READ rejection ----

  describe('shop_1 operator → shop_0 reads', () => {
    test.each(ALL_SUB_COLLECTIONS)(
      'shop_1 operator cannot read /shops/shop_0/%s/active',
      async (collection) => {
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertFails(
          db.collection('shops').doc('shop_0').collection(collection).get(),
        );
      },
    );

    test('shop_1 operator cannot read /shops/shop_0', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(db.collection('shops').doc('shop_0').get());
    });
  });

  // ---- AC #6: cross-tenant WRITE rejection ----

  describe('shop_1 operator → shop_0 writes', () => {
    test('shop_1 operator cannot create a doc in shop_0/udhaarLedger', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('udhaarLedger')
          .add({
            shopId: 'shop_0',
            customerId: 'malicious',
            recordedAmount: 999,
            runningBalance: 999,
          }),
      );
    });

    test('shop_1 operator cannot update shop_0/themeTokens/active', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('themeTokens')
          .doc('active')
          .update({ primaryColor: '#FF0000' }),
      );
    });
  });

  // ---- Sanity: same-shop reads/writes succeed (no false positives) ----

  describe('shop_1 operator → shop_1 reads (must succeed)', () => {
    test('shop_1 operator can read /shops/shop_1', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(db.collection('shops').doc('shop_1').get());
    });

    test('shop_1 operator can read /shops/shop_1/themeTokens/active', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('themeTokens')
          .doc('active')
          .get(),
      );
    });
  });

  // ---- AC #7: udhaar forbidden vocabulary (ADR-010) ----

  describe('udhaar ledger forbidden vocabulary (ADR-010)', () => {
    const FORBIDDEN_FIELDS = [
      'interest',
      'interestRate',
      'overdueFee',
      'dueDate',
      'lendingTerms',
      'borrowerObligation',
      'defaultStatus',
      'collectionAttempt',
    ];

    test.each(FORBIDDEN_FIELDS)(
      'rejects udhaar write containing forbidden field: %s',
      async (forbiddenField) => {
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertFails(
          db
            .collection('shops')
            .doc('shop_1')
            .collection('udhaarLedger')
            .add({
              shopId: 'shop_1',
              customerId: 'cust-1',
              recordedAmount: 10000,
              runningBalance: 10000,
              [forbiddenField]: 'malicious-value',
            }),
        );
      },
    );

    test('allows udhaar write with only permitted fields', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('udhaarLedger')
          .add({
            shopId: 'shop_1',
            customerId: 'cust-1',
            recordedAmount: 5000,
            runningBalance: 5000,
            acknowledgedAt: new Date(),
            partialPaymentReferences: [],
          }),
      );
    });
  });

  // ---- Default deny ----

  describe('catch-all default deny', () => {
    test('unknown top-level collection is denied for any user', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(db.collection('martian_data').doc('any').get());
    });

    test('unauthenticated user cannot read any shop', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(db.collection('shops').doc('shop_1').get());
    });
  });

  // -------------------------------------------------------------------------
  // SAD v1.0.4 ADR-013 — Shop lifecycle write-freeze (R16 / DPDP Act)
  // -------------------------------------------------------------------------

  describe('shop lifecycle write-freeze (ADR-013)', () => {
    test.each(['deactivating', 'purge_scheduled', 'purged'] as const)(
      'shopLifecycle=%s rejects operator writes to udhaarLedger',
      async (lifecycle) => {
        await setShopLifecycle('shop_1', lifecycle);
        const db = ctxAsShopOperator('shop_1').firestore();

        await assertFails(
          db
            .collection('shops')
            .doc('shop_1')
            .collection('udhaarLedger')
            .add({
              shopId: 'shop_1',
              customerId: 'cust-1',
              recordedAmount: 5000,
              runningBalance: 5000,
            }),
        );
      },
    );

    test('shopLifecycle=active allows operator writes to udhaarLedger', async () => {
      // Sanity: with active state, same write succeeds (no false positive)
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('udhaarLedger')
          .add({
            shopId: 'shop_1',
            customerId: 'cust-1',
            recordedAmount: 5000,
            runningBalance: 5000,
          }),
      );
    });

    test('shopLifecycle=deactivating rejects themeTokens writes', async () => {
      await setShopLifecycle('shop_1', 'deactivating');
      const db = ctxAsShopOperator('shop_1').firestore();

      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('themeTokens')
          .doc('active')
          .update({ primaryColor: '#FF0000' }),
      );
    });

    test('shopLifecycle=deactivating still allows reads (DPDP retention window)', async () => {
      await setShopLifecycle('shop_1', 'deactivating');
      const db = ctxAsShopOperator('shop_1').firestore();

      await assertSucceeds(db.collection('shops').doc('shop_1').get());
    });
  });

  // -------------------------------------------------------------------------
  // SAD v1.0.4 §5 feedback sub-collection (S4.17 NPS + burnout)
  // -------------------------------------------------------------------------

  describe('feedback collection (S4.17, SAD v1.0.4)', () => {
    test('shop_1 operator cannot read shop_0 feedback (cross-tenant)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_0').collection('feedback').get(),
      );
    });

    test('shop_1 operator can read own shop_1 feedback', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db.collection('shops').doc('shop_1').collection('feedback').get(),
      );
    });

    test('customer can create own customer_nps feedback', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();

      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('feedback')
          .add({
            feedbackId: 'fb-new-1',
            shopId: 'shop_1',
            type: 'customer_nps',
            authorUid: uid,
            authorRole: 'customer',
            score: 8,
            createdAt: new Date(),
          }),
      );
    });

    test('customer cannot create shopkeeper_burnout_self_report (wrong role)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();

      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('feedback')
          .add({
            feedbackId: 'fb-spoofed',
            shopId: 'shop_1',
            type: 'shopkeeper_burnout_self_report',
            authorUid: uid,
            authorRole: 'customer',
            score: 10,
            createdAt: new Date(),
          }),
      );
    });

    test('customer cannot spoof authorUid as another user', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();

      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('feedback')
          .add({
            feedbackId: 'fb-spoof-uid',
            shopId: 'shop_1',
            type: 'customer_nps',
            authorUid: 'someone-else',
            authorRole: 'customer',
            score: 5,
            createdAt: new Date(),
          }),
      );
    });

    test('feedback is immutable after create (no update)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('feedback')
          .doc('fb-seed-nps')
          .update({ score: 1 }),
      );
    });

    test('feedback is not deletable', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('feedback')
          .doc('fb-seed-nps')
          .delete(),
      );
    });
  });
});
