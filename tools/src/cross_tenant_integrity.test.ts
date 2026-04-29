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
        // Canonical role per Dart enum (bhaiya/beta/munshi). The
        // firestore.rules `isShopOperator` helper expects these names —
        // earlier 'shopkeeper' value was stale (drift §15.2.C resolved
        // on the rule side; the test seed lagged).
        role: 'bhaiya',
      });

      // WS5.1 seed — chatThread for cross-tenant isolation tests.
      await db
        .collection('shops')
        .doc(shopId)
        .collection('chatThreads')
        .doc('thread-p1')
        .set({
          shopId,
          threadId: 'thread-p1',
          customerUid: `cust-${shopId}-uid`,
          participantUids: [`cust-${shopId}-uid`, `op-${shopId}-owner`],
          unreadCountForCustomer: 0,
          unreadCountForOperator: 1,
          lastMessagePreview: 'नमस्ते',
          createdAt: new Date(),
        });

      // WS5.2 seed — decision_circle for cross-tenant isolation tests.
      await db
        .collection('shops')
        .doc(shopId)
        .collection('decision_circles')
        .doc('dc-p1')
        .set({
          shopId,
          dcId: 'dc-p1',
          creatorUid: `cust-${shopId}-uid`,
          personas: [],
          createdAt: new Date(),
        });
    }

    // WS5.3 seed — global system doc. Written via Admin SDK (rules-disabled)
    // to mirror how Cloud Functions write it. Client reads are gated by
    // isYugmaAdmin() — shop operators and customers must never reach this.
    await db.collection('system').doc('audit_results').set({
      createdAt: new Date(),
      summary: { flagged: 0, checked: 0 },
    });
  });
});

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

function ctxAsShopOperator(shopId: string) {
  return testEnv.authenticatedContext(`op-${shopId}-owner`, {
    shopId,
    // Canonical role per Dart enum + rule helper (drift §15.2.C).
    role: 'bhaiya',
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

// Sub-collections under /shops/{shopId} that contain PII / shop-private
// data and must NOT be readable across tenants.
const PRIVATE_SUB_COLLECTIONS = ['udhaarLedger', 'feedback'];

// Sub-collections that are intentionally readable by any signed-in user
// (the marketing site + customer apps need them for branding / runtime
// flags). Cross-tenant read here is DESIGN, not a leak.
const PUBLIC_SUB_COLLECTIONS = ['themeTokens', 'featureFlags'];

// -----------------------------------------------------------------------------
// Test cases — PRD I6.4 ACs #5–#7
// -----------------------------------------------------------------------------

describe('Cross-tenant integrity (rules.test)', () => {
  // ---- AC #5: cross-tenant READ rejection ----

  describe('shop_1 operator → shop_0 reads', () => {
    test.each(PRIVATE_SUB_COLLECTIONS)(
      'shop_1 operator cannot read /shops/shop_0/%s (private)',
      async (collection) => {
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertFails(
          db.collection('shops').doc('shop_0').collection(collection).get(),
        );
      },
    );

    test.each(PUBLIC_SUB_COLLECTIONS)(
      'shop_1 operator CAN read /shops/shop_0/%s (public by design)',
      async (collection) => {
        // Theme + feature-flag mirrors are intentionally signed-in-readable
        // so the marketing site and customer apps can render any shop's
        // branding without per-shop auth. Cross-tenant READ here is design,
        // not a leak — write paths remain shop-scoped (see operator write
        // rejection tests below).
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertSucceeds(
          db.collection('shops').doc('shop_0').collection(collection).get(),
        );
      },
    );

    test('shop_1 operator CAN read /shops/shop_0 doc (public by design)',
      async () => {
        // The shop doc itself (brandName, ownerUid, lifecycle) is public
        // for marketing site discovery. PII lives under shop-scoped
        // sub-collections (customers/, customer_memory/, udhaarLedger/)
        // which are tenant-private — see PRIVATE_SUB_COLLECTIONS tests.
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertSucceeds(db.collection('shops').doc('shop_0').get());
      },
    );
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
  // PRD I6.12 AC #5(b) + #5(c) + #6 — partition-discipline rule enforcement
  // -------------------------------------------------------------------------
  //
  // These tests verify that the Firestore security rule layer (not just the
  // Dart type system) rejects cross-partition writes. This is critical
  // because a malicious customer_app build could bypass the Dart sealed-union
  // partition and write raw Maps directly to Firestore — the rule layer is
  // the last line of defense.
  //
  // Added in Sprint 2.3 cleanup per code review finding Agent B 🟡 #4.
  // Note: the v1 firestore.rules does NOT yet have Project/ChatThread/
  // UdhaarLedger sub-collection rules because those stories land in Sprint
  // 4+ (C3.1, P2.4, P2.5). These tests use the existing `udhaarLedger`
  // sub-collection as the partition test surface because it's the only
  // rule that ships with Sprint 1 and has forbidden-vocabulary discipline.
  // Sprint 4+ will add Project + ChatThread partition tests when those
  // rules exist.

  describe('partition discipline at rule layer (PRD I6.12 AC #5(b)/#6)', () => {
    test(
      'udhaar forbidden-field write is rejected at rule layer even from ' +
        'authenticated operator (PRD I6.12 AC #6 + ADR-010)',
      async () => {
        const db = ctxAsShopOperator('shop_1').firestore();
        // Walk through every forbidden field individually — confirms that
        // the rule's hasForbiddenUdhaarFields() helper is exhaustive AND
        // that the rule layer rejects regardless of the operator's tier.
        // This is the multi-day offline replay invariant: even if a
        // compromised client construction bypasses the Dart partition
        // patches and builds a raw Map with forbidden fields, the rule
        // layer blocks it.
        for (const field of [
          'interest',
          'interestRate',
          'overdueFee',
          'dueDate',
          'lendingTerms',
          'borrowerObligation',
          'defaultStatus',
          'collectionAttempt',
        ]) {
          await assertFails(
            db
              .collection('shops')
              .doc('shop_1')
              .collection('udhaarLedger')
              .add({
                shopId: 'shop_1',
                customerId: 'cust-1',
                recordedAmount: 1000,
                runningBalance: 1000,
                [field]: 'any-value',
              }),
          );
        }
      },
    );

    test(
      'udhaar operator write with only allowed fields succeeds ' +
        '(no false positives)',
      async () => {
        const db = ctxAsShopOperator('shop_1').firestore();
        await assertSucceeds(
          db
            .collection('shops')
            .doc('shop_1')
            .collection('udhaarLedger')
            .add({
              shopId: 'shop_1',
              customerId: 'cust-1',
              recordedAmount: 10000,
              runningBalance: 7500,
              acknowledgedAt: new Date(),
              partialPaymentReferences: ['txn-1', 'txn-2'],
              // SAD v1.0.4 RBI guardrail fields (not forbidden)
              reminderOptInByBhaiya: true,
              reminderCountLifetime: 1,
              reminderCadenceDays: 14,
            }),
        );
      },
    );

    test(
      'customer cannot write to udhaarLedger at all (ADR-010 ' +
        'shopkeeper-initiated only)',
      async () => {
        const db = ctxAsCustomer('shop_1').firestore();
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

    test(
      'themeTokens writes are operator-only (customer partition rejection)',
      async () => {
        const db = ctxAsCustomer('shop_1').firestore();
        await assertFails(
          db
            .collection('shops')
            .doc('shop_1')
            .collection('themeTokens')
            .doc('active')
            .update({ primaryColor: '#FFFFFF' }),
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // SAD v1.0.4 §5 feedback sub-collection (S4.17 NPS + burnout)
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // §15.1.B Triple Zero invariant — server-side rule enforcement
  // -------------------------------------------------------------------------

  describe('Triple Zero invariant at project close (§15.1.B)', () => {
    async function seedProjectInDelivering(
      shopId: string,
      projectId: string,
      totalAmount: number,
      amountReceivedByShop: number,
    ): Promise<void> {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc(projectId)
          .set({
            shopId,
            projectId,
            customerUid: `cust-${shopId}-uid`,
            state: 'delivering',
            totalAmount,
            amountReceivedByShop,
            lineItems: [],
            createdAt: new Date(),
          });
      });
    }

    test('operator close with matched Triple Zero succeeds', async () => {
      await seedProjectInDelivering('shop_1', 'p-tz-ok', 25000, 25000);
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p-tz-ok')
          .update({ state: 'closed', updatedAt: new Date() }),
      );
    });

    test('operator close with mismatched amounts is REJECTED', async () => {
      await seedProjectInDelivering('shop_1', 'p-tz-bad', 25000, 24000);
      const db = ctxAsShopOperator('shop_1').firestore();
      // The threat model: a REST client bypassing the Dart typed patches
      // tries to close while the shop received less than totalAmount.
      // Dart-side `Project.zeroCommissionSatisfied` would catch this in
      // the in-process patch path; this assertion proves the rule layer
      // catches it independently.
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p-tz-bad')
          .update({ state: 'closed', updatedAt: new Date() }),
      );
    });

    test('operator close where mismatch is repaired in same write succeeds', async () => {
      await seedProjectInDelivering('shop_1', 'p-tz-fix', 25000, 24000);
      const db = ctxAsShopOperator('shop_1').firestore();
      // Same write that closes also corrects amountReceivedByShop to
      // match totalAmount → invariant satisfied at write time.
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p-tz-fix')
          .update({
            state: 'closed',
            amountReceivedByShop: 25000,
            updatedAt: new Date(),
          }),
      );
    });

    test('non-close state transitions still allow transient mismatch', async () => {
      // Earlier states (draft → negotiating, etc.) are allowed to have
      // amountReceivedByShop != totalAmount. The invariant is only
      // enforced AT close.
      await seedProjectInDelivering('shop_1', 'p-tz-draft', 25000, 0);
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p-tz-draft')
          .update({ totalAmount: 26000, updatedAt: new Date() }),
      );
    });
  });

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

  // -------------------------------------------------------------------------
  // WS5.1 — chatThreads cross-tenant isolation (PR gate for shop #2)
  // Verifies that the bare `isSignedIn()` read rule has been replaced with
  // a tenant-scoped predicate (customerUid match OR isShopOperator(shopId)).
  // -------------------------------------------------------------------------

  describe('WS5.1 — chatThreads cross-tenant isolation', () => {
    test('shop_1 operator cannot read /shops/shop_0/chatThreads (cross-tenant leak)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_0').collection('chatThreads').get(),
      );
    });

    test('shop_1 operator can read /shops/shop_1/chatThreads (own shop — no false positive)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db.collection('shops').doc('shop_1').collection('chatThreads').get(),
      );
    });

    test('shop_0 customer can read their own chatThread doc without shopId claim (anonymous path)', async () => {
      // Simulates an anonymous customer (pre-OTP) who has no shopId token
      // claim but whose UID matches the customerUid stored on the thread.
      const uid = 'cust-shop_0-uid';
      const db = testEnv
        .authenticatedContext(uid, {
          firebase: { sign_in_provider: 'anonymous' },
          // Intentionally no shopId claim — anonymous users don't have it.
        })
        .firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('chatThreads')
          .doc('thread-p1')
          .get(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // WS5.2 — decision_circles cross-tenant isolation (PR gate for shop #2)
  // Verifies that the bare `isSignedIn()` read rule has been replaced with
  // isShopMember(shopId), which checks the shopId token claim.
  // -------------------------------------------------------------------------

  describe('WS5.2 — decision_circles cross-tenant isolation', () => {
    test('shop_1 operator cannot read /shops/shop_0/decision_circles (cross-tenant leak)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('decision_circles')
          .get(),
      );
    });

    test('shop_1 operator can read /shops/shop_1/decision_circles (own shop — no false positive)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('decision_circles')
          .get(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // WS5.3 — /system/* reads restricted to isYugmaAdmin (PR gate for shop #2)
  // Any bhaiya from any shop could previously read all of /system/* because
  // the rule checked `callerRole() == 'bhaiya'` without requiring the
  // yugmaAdmin custom claim. Now only Yugma Labs admins (claim yugmaAdmin==true)
  // may client-read these docs. Cloud Functions use Admin SDK and are unaffected.
  // -------------------------------------------------------------------------

  describe('WS5.3 — /system/* reads restricted to isYugmaAdmin', () => {
    test('shop_1 operator cannot read /system/audit_results (bhaiya claim, not yugmaAdmin)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db.collection('system').doc('audit_results').get(),
      );
    });

    test('anonymous customer cannot read /system/audit_results', async () => {
      const db = testEnv
        .authenticatedContext('anon-cust-1', {
          firebase: { sign_in_provider: 'anonymous' },
          // No shopId, no yugmaAdmin — anonymous customers have neither.
        })
        .firestore();
      await assertFails(
        db.collection('system').doc('audit_results').get(),
      );
    });
  });

  // -------------------------------------------------------------------------
  // WS5.4 — multiTenantAudit missing-shopId detection
  // The CF's violation-detection condition must flag docs whose shopId field
  // is entirely absent (undefined), not only docs with a wrong shopId value.
  // The scheduled CF is not directly invocable from the emulator context, so
  // we verify the condition logic: once by running it against a seeded doc,
  // once as a pure-logic regression to document the old-vs-new behaviour.
  // -------------------------------------------------------------------------

  describe('WS5.4 — multiTenantAudit missing-shopId detection', () => {
    test('doc without shopId field is flagged by the fixed audit condition', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection('shops')
          .doc('shop_1')
          .collection('udhaarLedger')
          .doc('udh-missing-shopid')
          .set({
            customerId: 'cust-x',
            recordedAmount: 5000,
            runningBalance: 5000,
            // shopId intentionally omitted — the silent-bug scenario
          });
      });

      const violations: string[] = [];
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        const snap = await ctx
          .firestore()
          .collection('shops')
          .doc('shop_1')
          .collection('udhaarLedger')
          .get();

        const shopId = 'shop_1';
        for (const doc of snap.docs) {
          const data = doc.data();
          // Fixed condition: undefined !== shopId → violation flagged
          if (data.shopId !== shopId) {
            violations.push(doc.id);
          }
        }
      });

      expect(violations).toContain('udh-missing-shopid');
    });

    test('old broken condition silently misses docs with no shopId field', () => {
      // Pure logic regression — no emulator I/O needed.
      const data: Record<string, unknown> = {
        customerId: 'cust-x',
        recordedAmount: 5000,
        runningBalance: 5000,
        // shopId absent → data.shopId === undefined
      };
      const shopId = 'shop_1';

      const brokenCondition =
        data.shopId !== undefined && data.shopId !== shopId;
      const fixedCondition = data.shopId !== shopId;

      expect(brokenCondition).toBe(false); // bug: violation silently missed
      expect(fixedCondition).toBe(true);   // fix: violation correctly detected
    });
  });
});
