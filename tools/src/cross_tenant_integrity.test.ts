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

    for (const shopId of ['shop_0', 'shop_1', 'shop_2']) {
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
        .collection('theme')
        .doc('current')
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

      // WS5.5 seeds — additional subcollections for expanded cross-tenant coverage.

      await db
        .collection('shops')
        .doc(shopId)
        .collection('projects')
        .doc('proj-seed')
        .set({
          shopId,
          projectId: 'proj-seed',
          customerId: `cust-${shopId}-uid`,
          customerUid: `cust-${shopId}-uid`,
          state: 'draft',
          totalAmount: 25000,
          amountReceivedByShop: 0,
          lineItems: [],
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .doc(`cust-${shopId}-uid`)
        .set({
          shopId,
          customerId: `cust-${shopId}-uid`,
          isPhoneVerified: false,
          previousProjectIds: [],
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('customer_memory')
        .doc(`cust-${shopId}-uid`)
        .set({
          shopId,
          uid: `cust-${shopId}-uid`,
          notes: 'Test note',
          updatedAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('inventory')
        .doc('sku-seed')
        .set({
          shopId,
          skuId: 'sku-seed',
          nameHindi: 'अलमारी',
          isActive: true,
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('voiceNotes')
        .doc('vn-seed')
        .set({
          shopId,
          voiceNoteId: 'vn-seed',
          authorUid: `op-${shopId}-owner`,
          storageRef: `gs://placeholder/${shopId}/vn-seed.m4a`,
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('curatedShortlists')
        .doc('cs-seed')
        .set({
          shopId,
          shortlistId: 'cs-seed',
          occasion: 'shaadi',
          skuIdsInOrder: [],
          isActive: true,
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('golden_hour_photos')
        .doc('gh-seed')
        .set({
          shopId,
          photoId: 'gh-seed',
          operatorUid: `op-${shopId}-owner`,
          cloudinaryUrl: `https://res.cloudinary.com/placeholder/${shopId}/gh-seed.jpg`,
          createdAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('telemetry')
        .doc('media-seed')
        .set({
          shopId,
          period: '2026-04',
          voiceNoteMinutes: 0,
          imageCount: 0,
          updatedAt: new Date(),
        });

      await db
        .collection('shops')
        .doc(shopId)
        .collection('today_tasks')
        .doc('task-seed')
        .set({
          shopId,
          taskId: 'task-seed',
          operatorUid: `op-${shopId}-owner`,
          completed: false,
          createdAt: new Date(),
        });

      // /shops/{shopId}/operators — shop-scoped subcollection (distinct from
      // the top-level /operators/{uid} collection seeded above).
      await db
        .collection('shops')
        .doc(shopId)
        .collection('operators')
        .doc(`op-${shopId}-owner`)
        .set({
          uid: `op-${shopId}-owner`,
          shopId,
          role: 'bhaiya',
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
// WS5.5: expanded from 4 to 10 — covers all shop-scoped subcollections
// whose read rules gate on isShopOperator/isShopMember/isCustomerOf rather
// than bare isSignedIn(). inventory/voiceNotes/curatedShortlists/
// golden_hour_photos all use isSignedIn() and are intentionally public.
const PRIVATE_SUB_COLLECTIONS = [
  'udhaarLedger',
  'feedback',
  'projects',
  'customers',
  'customer_memory',
  'chatThreads',
  'decision_circles',
  'telemetry',
  'today_tasks',
  'operators',
];

// Sub-collections that are intentionally readable by any signed-in user
// (the marketing site + customer apps need them for branding, catalog
// browsing, and runtime flags). Cross-tenant read here is DESIGN, not a leak.
// WS5.5: expanded with inventory/voiceNotes/curatedShortlists/golden_hour_photos
// — all use `allow read: if isSignedIn()`.
const PUBLIC_SUB_COLLECTIONS = [
  'theme',
  'featureFlags',
  'inventory',
  'voiceNotes',
  'curatedShortlists',
  'golden_hour_photos',
];

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

    test('shop_1 operator cannot update shop_0/theme/current', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('theme')
          .doc('current')
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

    test('shop_1 operator can read /shops/shop_1/theme/current', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('theme')
          .doc('current')
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

    test('shopLifecycle=deactivating rejects theme/current writes', async () => {
      await setShopLifecycle('shop_1', 'deactivating');
      const db = ctxAsShopOperator('shop_1').firestore();

      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('theme')
          .doc('current')
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
      'theme/current writes are operator-only (customer partition rejection)',
      async () => {
        const db = ctxAsCustomer('shop_1').firestore();
        await assertFails(
          db
            .collection('shops')
            .doc('shop_1')
            .collection('theme')
            .doc('current')
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
            customerId: `cust-${shopId}-uid`,
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

  // -------------------------------------------------------------------------
  // WS5.5 — 3-way isolation (shop_2 operator cannot read shop_0 or shop_1)
  // Verifies that cross-tenant denial is not a 2-shop coincidence but holds
  // for any N-th tenant. shop_2 is seeded identically to shop_0/shop_1 in
  // beforeEach so all private subcollections have at least one document.
  // -------------------------------------------------------------------------

  describe('WS5.5 — 3-way isolation (shop_2 → shop_0 and shop_1)', () => {
    test.each(PRIVATE_SUB_COLLECTIONS)(
      'shop_2 operator cannot read /shops/shop_0/%s',
      async (collection) => {
        const db = ctxAsShopOperator('shop_2').firestore();
        await assertFails(
          db.collection('shops').doc('shop_0').collection(collection).get(),
        );
      },
    );

    test.each(PRIVATE_SUB_COLLECTIONS)(
      'shop_2 operator cannot read /shops/shop_1/%s',
      async (collection) => {
        const db = ctxAsShopOperator('shop_2').firestore();
        await assertFails(
          db.collection('shops').doc('shop_1').collection(collection).get(),
        );
      },
    );

    test('shop_2 operator can read own /shops/shop_2 doc (no false positive)', async () => {
      const db = ctxAsShopOperator('shop_2').firestore();
      await assertSucceeds(db.collection('shops').doc('shop_2').get());
    });
  });

  // -------------------------------------------------------------------------
  // Phase 1 — cross-tenant write hardening
  // These tests are RED against the pre-Phase-1 rules. Each asserts a write
  // that must be denied but was previously allowed due to missing guards.
  // -------------------------------------------------------------------------

  describe('Phase 1 — projects: cross-tenant create + ownership immutability', () => {
    test('shop_1 operator cannot create project under shop_0 (missing callerShopId check)', async () => {
      // shop_1 op has shopId:'shop_1' claim — they must not be able to write
      // into another shop's projects namespace even by setting shopId in data.
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_0').collection('projects').add({
          shopId: 'shop_0',
          customerUid: 'op-shop_1-owner',
          state: 'draft',
          totalAmount: 0,
          amountReceivedByShop: 0,
          lineItems: [],
          createdAt: new Date(),
        }),
      );
    });

    test('operator cannot mutate shopId on own project (ownership immutability)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ shopId: 'shop_1', updatedAt: new Date() }),
      );
    });

    test('operator cannot mutate customerUid on own project (ownership immutability)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ customerUid: 'op-shop_0-owner', updatedAt: new Date() }),
      );
    });

    // -------------------------------------------------------------------------
    // Phase 5B — /projects create identity + money-state allowlist
    //
    // Adds three negative tests (customerId mismatch, amountReceivedByShop
    // pre-pollution, settlement-field pre-set) and two green-path tests
    // (amountReceivedByShop == 0 minimal body, full ProjectRepo.createDraft
    // body — guards against the rule accidentally rejecting the live customer
    // flow). See docs/superpowers/plans/2026-05-01-enterprise-hardening-...
    // -------------------------------------------------------------------------

    test('Phase 5B — project create rejects customerId mismatch', async () => {
      const ctx = testEnv.authenticatedContext('alice', {
        firebase: { sign_in_provider: 'anonymous' },
      });
      const db = ctx.firestore();
      await assertFails(
        db.doc('shops/shop_1/projects/p1').set({
          projectId: 'p1',
          shopId: 'shop_1',
          customerUid: 'alice', // matches caller
          customerId: 'mallory', // does NOT match caller — should be rejected
          state: 'draft',
          totalAmount: 0,
          lineItems: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    });

    test('Phase 5B — project create rejects amountReceivedByShop != 0', async () => {
      // The Phase 5B rule allows amountReceivedByShop in the keys allowlist
      // (it is part of the existing ProjectRepo.createDraft body) but
      // constrains the value to == 0. Any non-zero value at create is
      // money-state pre-pollution.
      const ctx = testEnv.authenticatedContext('alice', {
        firebase: { sign_in_provider: 'anonymous' },
      });
      const db = ctx.firestore();
      await assertFails(
        db.doc('shops/shop_1/projects/p2').set({
          projectId: 'p2',
          shopId: 'shop_1',
          customerUid: 'alice',
          customerId: 'alice',
          state: 'draft',
          totalAmount: 0,
          amountReceivedByShop: 99999, // non-zero pre-pollution — rejected
          lineItemsCount: 0,
          lineItems: [],
          unreadCountForCustomer: 0,
          unreadCountForShopkeeper: 0,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    });

    test('Phase 5B — project create accepts amountReceivedByShop == 0 (matches existing createDraft)', async () => {
      // Guards against accidentally tightening the rule to exclude
      // amountReceivedByShop entirely, which would break the existing
      // ProjectRepo.createDraft body (which writes 0).
      const ctx = testEnv.authenticatedContext('alice', {
        firebase: { sign_in_provider: 'anonymous' },
      });
      const db = ctx.firestore();
      await assertSucceeds(
        db.doc('shops/shop_1/projects/p2b').set({
          projectId: 'p2b',
          shopId: 'shop_1',
          customerUid: 'alice',
          customerId: 'alice',
          state: 'draft',
          totalAmount: 0,
          amountReceivedByShop: 0, // explicitly 0 — must be allowed
          lineItemsCount: 0,
          lineItems: [],
          unreadCountForCustomer: 0,
          unreadCountForShopkeeper: 0,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    });

    test('Phase 5B — project create rejects pre-set paidAt', async () => {
      const ctx = testEnv.authenticatedContext('alice', {
        firebase: { sign_in_provider: 'anonymous' },
      });
      const db = ctx.firestore();
      await assertFails(
        db.doc('shops/shop_1/projects/p3').set({
          projectId: 'p3',
          shopId: 'shop_1',
          customerUid: 'alice',
          customerId: 'alice',
          state: 'draft',
          totalAmount: 0,
          paidAt: new Date(), // settlement field — should be rejected at create
          lineItems: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    });

    test('Phase 5B — project create succeeds with full ProjectRepo.createDraft body (no false positive)', async () => {
      // Mirrors the EXACT body that ProjectRepo.createDraft writes
      // (apps/customer_app + packages/lib_core project_repo.dart). If this
      // test fails, customer draft creation is broken in production.
      const ctx = testEnv.authenticatedContext('alice', {
        firebase: { sign_in_provider: 'anonymous' },
      });
      const db = ctx.firestore();
      await assertSucceeds(
        db.doc('shops/shop_1/projects/p4').set({
          projectId: 'p4',
          shopId: 'shop_1',
          customerId: 'alice',
          customerUid: 'alice',
          state: 'draft',
          totalAmount: 0,
          amountReceivedByShop: 0,
          lineItemsCount: 0,
          lineItems: [],
          unreadCountForCustomer: 0,
          unreadCountForShopkeeper: 0,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    });
  });

  describe('Phase 1 — chatThreads: cross-tenant create + field allowlist + lifecycle', () => {
    test('shop_1 operator cannot create chatThread under shop_0 (cross-tenant)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_0').collection('chatThreads').add({
          shopId: 'shop_0',
          customerUid: 'op-shop_1-owner',
          participantUids: [],
          createdAt: new Date(),
        }),
      );
    });

    test('chatThread create requires customerUid to match caller uid', async () => {
      const db = ctxAsCustomer('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_1').collection('chatThreads').add({
          shopId: 'shop_1',
          customerUid: 'some-other-user',
          participantUids: [],
          createdAt: new Date(),
        }),
      );
    });

    test('chatThread create is frozen when shop is deactivating', async () => {
      await setShopLifecycle('shop_1', 'deactivating');
      const db = ctxAsCustomer('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_1').collection('chatThreads').add({
          shopId: 'shop_1',
          customerUid: 'cust-shop_1-uid',
          participantUids: [],
          createdAt: new Date(),
        }),
      );
    });

    test('chatThread update cannot mutate shopId (field allowlist)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('chatThreads')
          .doc('thread-p1')
          .update({ shopId: 'shop_1' }),
      );
    });

    test('chatThread update cannot mutate customerUid (field allowlist)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('chatThreads')
          .doc('thread-p1')
          .update({ customerUid: 'attacker-uid' }),
      );
    });

    test('chatThread update is frozen when shop is deactivating', async () => {
      await setShopLifecycle('shop_1', 'deactivating');
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .update({ unreadCountForOperator: 0 }),
      );
    });

    test('chatThread update of allowed field succeeds (no false positive)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .update({ unreadCountForOperator: 0, updatedAt: new Date() }),
      );
    });
  });

  describe('Phase 1 — messages: cross-tenant create + thread membership', () => {
    test('shop_1 operator cannot create message in shop_0 thread (cross-tenant)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .add({
            authorUid: 'op-shop_1-owner',
            text: 'Intruder message',
            createdAt: new Date(),
          }),
      );
    });

    test('non-member (wrong uid, same shop) cannot send message in a thread they do not own', async () => {
      // stranger-uid has shopId:'shop_1' claim but is NOT thread-p1's customerUid
      // and is not an operator (phone sign-in). Must be denied.
      const db = testEnv
        .authenticatedContext('stranger-uid', {
          shopId: 'shop_1',
          firebase: { sign_in_provider: 'phone' },
        })
        .firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .add({
            authorUid: 'stranger-uid',
            text: 'Sneaking in',
            createdAt: new Date(),
          }),
      );
    });

    test('thread owner can send message (no false positive)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .add({
            authorUid: uid,
            text: 'Hello from the owner',
            createdAt: new Date(),
          }),
      );
    });
  });

  describe('Phase 1 — customers: ownership field immutability', () => {
    test('customer cannot mutate own shopId field', async () => {
      const uid = 'cust-shop_0-uid';
      const db = ctxAsCustomer('shop_0', uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('customers')
          .doc(uid)
          .update({ shopId: 'shop_1' }),
      );
    });

    test('customer cannot mutate own customerId field', async () => {
      const uid = 'cust-shop_0-uid';
      const db = ctxAsCustomer('shop_0', uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('customers')
          .doc(uid)
          .update({ customerId: 'attacker-uid' }),
      );
    });

    test('customer can update own allowed profile fields (no false positive)', async () => {
      // isPhoneVerified is NOT a safe self-update field — only safe fields in
      // the customer branch allowlist (displayName, updatedAt) should pass.
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('customers')
          .doc(uid)
          .update({ displayName: 'Ramesh Kumar', updatedAt: new Date() }),
      );
    });
  });

  describe('Phase 1 — decision_circles: cross-tenant create + field allowlist', () => {
    test('shop_1 authenticated user cannot create DC in shop_0 (callerShopId mismatch)', async () => {
      // phone-verified shop_1 customer has shopId:'shop_1' claim — must not
      // be able to pollute shop_0's decision_circles namespace.
      const db = ctxAsCustomer('shop_1').firestore();
      await assertFails(
        db.collection('shops').doc('shop_0').collection('decision_circles').add({
          shopId: 'shop_0',
          creatorUid: 'cust-shop_1-uid',
          personas: [],
          createdAt: new Date(),
        }),
      );
    });

    test('same-shop customer can create DC (no false positive)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db.collection('shops').doc('shop_1').collection('decision_circles').add({
          shopId: 'shop_1',
          creatorUid: uid,
          personas: [],
          createdAt: new Date(),
        }),
      );
    });

    test('DC update cannot mutate creatorUid (ownership immutability)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('decision_circles')
          .doc('dc-p1')
          .update({ creatorUid: 'attacker', shopId: 'shop_0' }),
      );
    });

    test('DC update cannot mutate shopId (ownership immutability)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('decision_circles')
          .doc('dc-p1')
          .update({ shopId: 'shop_1', personas: [] }),
      );
    });

    test('DC update of personas succeeds (no false positive)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('decision_circles')
          .doc('dc-p1')
          .update({ personas: [{ role: 'mummy-ji', uid }], updatedAt: new Date() }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Phase 1 correction A — messages: update must verify thread membership
  // The original message update rule only checked isSignedIn + shopIsWritable
  // + readByUids allowlist. Any signed-in user who knew a message path could
  // update readByUids cross-tenant.
  // -------------------------------------------------------------------------

  describe('Phase 1 correction A — messages: update requires thread membership', () => {
    const MESSAGE_ID = 'msg-seed-1';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        for (const shopId of ['shop_0', 'shop_1']) {
          await ctx
            .firestore()
            .collection('shops')
            .doc(shopId)
            .collection('chatThreads')
            .doc('thread-p1')
            .collection('messages')
            .doc(MESSAGE_ID)
            .set({
              shopId,
              messageId: MESSAGE_ID,
              threadId: 'thread-p1',
              authorUid: `cust-${shopId}-uid`,
              text: 'नमस्ते',
              readByUids: [],
              createdAt: new Date(),
            });
        }
      });
    });

    test('shop_1 operator cannot update readByUids on shop_0 message (cross-tenant)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .doc(MESSAGE_ID)
          .update({ readByUids: ['op-shop_1-owner'] }),
      );
    });

    test('same-shop stranger (not thread owner, not operator) cannot update readByUids', async () => {
      // stranger-uid has shopId:'shop_1' claim but is not thread-p1's customerUid
      // and is not a shop operator (phone sign-in).
      const db = testEnv
        .authenticatedContext('stranger-uid', {
          shopId: 'shop_1',
          firebase: { sign_in_provider: 'phone' },
        })
        .firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .doc(MESSAGE_ID)
          .update({ readByUids: ['stranger-uid'] }),
      );
    });

    test('thread owner (customerUid) can update readByUids (no false positive)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .doc(MESSAGE_ID)
          .update({ readByUids: [uid] }),
      );
    });

    test('same-shop operator can update readByUids (no false positive)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('chatThreads')
          .doc('thread-p1')
          .collection('messages')
          .doc(MESSAGE_ID)
          .update({ readByUids: ['op-shop_1-owner'] }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Phase 1 correction B — customers: field allowlist
  // The original customer update rule protected shopId/customerId but allowed
  // arbitrary field mutation — including isPhoneVerified and previousProjectIds
  // which must only be managed by Cloud Functions (Admin SDK).
  // -------------------------------------------------------------------------

  describe('Phase 1 correction B — customers: field allowlist enforcement', () => {
    test('customer cannot self-set isPhoneVerified (CF-only field)', async () => {
      const uid = 'cust-shop_0-uid';
      const db = ctxAsCustomer('shop_0', uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('customers')
          .doc(uid)
          .update({ isPhoneVerified: true }),
      );
    });

    test('customer cannot self-mutate previousProjectIds (CF-only field)', async () => {
      const uid = 'cust-shop_0-uid';
      const db = ctxAsCustomer('shop_0', uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('customers')
          .doc(uid)
          .update({ previousProjectIds: ['proj-injected'] }),
      );
    });

    test('customer can update displayName and updatedAt (no false positive)', async () => {
      const uid = 'cust-shop_1-uid';
      const db = ctxAsCustomer('shop_1', uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('customers')
          .doc(uid)
          .update({ displayName: 'Sunita Devi', updatedAt: new Date() }),
      );
    });

    test('operator can update customer displayName (no false positive)', async () => {
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('customers')
          .doc('cust-shop_1-uid')
          .update({ displayName: 'Sunita ji', updatedAt: new Date() }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Phase 2 — customer same-state lineItems gate: draft-only
  // lineItems and totalAmount must only be customer-writable in draft state.
  // Committed/paid/delivering projects must not accept customer line-item edits
  // even when the customer matches and state does not change.
  // -------------------------------------------------------------------------

  describe('Phase 2 — customer lineItems/totalAmount: draft-only gate', () => {
    async function seedCustomerProject(
      shopId: string,
      projectId: string,
      state: string,
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
            customerId: `cust-${shopId}-uid`,
            customerUid: `cust-${shopId}-uid`,
            state,
            totalAmount: 15000,
            amountReceivedByShop: state === 'draft' ? 0 : 15000,
            lineItems: [{ lineItemId: 'li-1', skuId: 'sku-1', quantity: 1, unitPriceInr: 15000 }],
            createdAt: new Date(),
          });
      });
    }

    test('customer can update lineItems and totalAmount on own draft project', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p-li-draft', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p-li-draft')
          .update({
            lineItems: [{ lineItemId: 'li-2', skuId: 'sku-2', quantity: 2, unitPriceInr: 8000 }],
            totalAmount: 16000,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer cannot update lineItems/totalAmount on own committed project', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p-li-committed', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p-li-committed')
          .update({
            lineItems: [],
            totalAmount: 0,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer cannot update lineItems/totalAmount on own paid project', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p-li-paid', 'paid');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p-li-paid')
          .update({
            lineItems: [],
            totalAmount: 0,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer cannot update lineItems/totalAmount on own delivering project', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p-li-delivering', 'delivering');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p-li-delivering')
          .update({
            lineItems: [],
            totalAmount: 0,
            updatedAt: new Date(),
          }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Phase 2 — operator allowlist: identity immutability + system-field fence
  // + committed→draft revert transition
  // -------------------------------------------------------------------------

  describe('Phase 2 — operator branch: identity + allowlist + revert', () => {
    test('operator cannot mutate projectId (identity field)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ projectId: 'injected-id', state: 'draft' }),
      );
    });

    test('operator cannot mutate customerId (identity field)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertFails(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ customerId: 'attacker-uid', state: 'draft' }),
      );
    });

    test('operator CAN write lastMessagePreview (transitional — Phase 3 CF target)', async () => {
      // shopkeeper_chat_screen.dart writes this client-side after voice-note send.
      // Included in allowlist until Phase 3 CF migration. This assertSucceeds
      // documents the current intentional policy.
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ lastMessagePreview: '🎤 आवाज़ नोट', updatedAt: new Date() }),
      );
    });

    test('operator CAN write lastMessageAt (transitional — Phase 3 CF target)', async () => {
      const db = ctxAsShopOperator('shop_0').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_0')
          .collection('projects')
          .doc('proj-seed')
          .update({ lastMessageAt: new Date(), updatedAt: new Date() }),
      );
    });

    test('operator can update state + paidAt + updatedAt (no false positive)', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p2-committed')
          .set({
            shopId: 'shop_1',
            projectId: 'p2-committed',
            customerId: 'cust-shop_1-uid',
            customerUid: 'cust-shop_1-uid',
            state: 'committed',
            totalAmount: 15000,
            amountReceivedByShop: 15000,
            lineItems: [],
            createdAt: new Date(),
          });
      });
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p2-committed')
          .update({ state: 'paid', paidAt: new Date(), updatedAt: new Date() }),
      );
    });

    test('operator can revert committed project to draft (ProjectOperatorRevertPatch)', async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p2-revert')
          .set({
            shopId: 'shop_1',
            projectId: 'p2-revert',
            customerId: 'cust-shop_1-uid',
            customerUid: 'cust-shop_1-uid',
            state: 'committed',
            totalAmount: 15000,
            amountReceivedByShop: 15000,
            committedAt: new Date(),
            lineItems: [],
            createdAt: new Date(),
          });
      });
      const db = ctxAsShopOperator('shop_1').firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc('shop_1')
          .collection('projects')
          .doc('p2-revert')
          .update({
            state: 'draft',
            committedAt: null,
            paidAt: null,
            deliveredAt: null,
            closedAt: null,
            amountReceivedByShop: 0,
            revertedByUid: 'op-shop_1-owner',
            revertReason: 'Customer changed mind',
            updatedAt: new Date(),
          }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Phase 3 — payment correctness: customer cannot write state=paid/delivering/
  // closed, cannot mutate amountReceivedByShop or paidAt; operator paid/closed
  // require Triple Zero in same write; D.2 four-branch transition isolation;
  // explicit source-state check on price-acceptance; COD same-state branch.
  // -------------------------------------------------------------------------

  describe('Phase 3 — payment-state hardening', () => {
    async function seedCustomerProject(
      shopId: string,
      projectId: string,
      state: string,
      overrides: Record<string, unknown> = {},
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
            customerId: `cust-${shopId}-uid`,
            customerUid: `cust-${shopId}-uid`,
            state,
            totalAmount: 15000,
            amountReceivedByShop: 0,
            lineItems: [],
            createdAt: new Date(),
            ...overrides,
          });
      });
    }

    test('customer cannot write state=paid via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-paid', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-paid')
          .update({ state: 'paid', updatedAt: new Date() }),
      );
    });

    test('customer cannot write state=delivering via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-deliver', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-deliver')
          .update({ state: 'delivering', updatedAt: new Date() }),
      );
    });

    test('customer cannot write state=closed via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-close', 'committed', {
        amountReceivedByShop: 15000,
      });
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-close')
          .update({ state: 'closed', updatedAt: new Date() }),
      );
    });

    test('customer cannot move awaiting_verification → paid via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-av-paid', 'awaiting_verification');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-paid')
          .update({
            state: 'paid',
            amountReceivedByShop: 15000,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer cannot mutate amountReceivedByShop via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-arc', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-arc')
          .update({ amountReceivedByShop: 15000, updatedAt: new Date() }),
      );
    });

    test('customer cannot mutate paidAt via REST', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-pa', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-pa')
          .update({ paidAt: new Date(), updatedAt: new Date() }),
      );
    });

    test('customer CAN move committed → awaiting_verification (UPI claim)',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-upi', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-upi')
          .update({
            state: 'awaiting_verification',
            paymentMethod: 'upi',
            customerVpa: 'sunita@okicici',
            updatedAt: new Date(),
          }),
      );
    });

    test('customer COD: paymentMethod-only update succeeds while in committed',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-cod', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-cod')
          .update({ paymentMethod: 'cod', updatedAt: new Date() }),
      );
    });

    test('customer COD: paymentMethod="upi" same-state write is REJECTED',
        async () => {
      // The same-state COD branch only allows paymentMethod == 'cod'. A
      // customer cannot self-tag UPI without going through the
      // committed → awaiting_verification transition.
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-cod-upi', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-cod-upi')
          .update({ paymentMethod: 'upi', updatedAt: new Date() }),
      );
    });

    test('customer COD same-state write REJECTED on paid project', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-cod-paid', 'paid', {
        amountReceivedByShop: 15000,
        paymentMethod: 'cash',
      });
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-cod-paid')
          .update({ paymentMethod: 'cod', updatedAt: new Date() }),
      );
    });

    // ----- Price acceptance: explicit source-state branch -----

    test('customer price acceptance: draft → negotiating succeeds', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-price-draft', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-price-draft')
          .update({
            state: 'negotiating',
            lineItems: [
              { lineItemId: 'li-1', skuId: 'sku-1', quantity: 1, unitPriceInr: 14000, finalPrice: 14000 },
            ],
            totalAmount: 14000,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer price acceptance: negotiating → negotiating (re-propose) succeeds',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-price-neg', 'negotiating');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-price-neg')
          .update({
            state: 'negotiating',
            lineItems: [
              { lineItemId: 'li-1', skuId: 'sku-1', quantity: 1, unitPriceInr: 14000, finalPrice: 13500 },
            ],
            totalAmount: 13500,
            updatedAt: new Date(),
          }),
      );
    });

    test('customer price acceptance: committed → negotiating REJECTED', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-price-committed', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-price-committed')
          .update({
            state: 'negotiating',
            lineItems: [
              { lineItemId: 'li-1', skuId: 'sku-1', quantity: 1, unitPriceInr: 1000 },
            ],
            totalAmount: 1000,
            updatedAt: new Date(),
          }),
      );
    });

    // ----- customerVpa scoping: write only with the awaiting_verification move -----

    test('customer cannot mutate customerVpa same-state on paid project',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-vpa-paid', 'paid', {
        amountReceivedByShop: 15000,
        paymentMethod: 'cash',
      });
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-vpa-paid')
          .update({ customerVpa: 'attacker@okhdfc', updatedAt: new Date() }),
      );
    });

    test('customer cannot mutate customerVpa same-state on committed project',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-vpa-committed', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-vpa-committed')
          .update({ customerVpa: 'sunita@okicici', updatedAt: new Date() }),
      );
    });

    // ----- Branch-isolation: each target's allowlist is narrow -----

    test('committed → awaiting_verification cannot mutate lineItems', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-av-li', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-li')
          .update({
            state: 'awaiting_verification',
            paymentMethod: 'upi',
            customerVpa: 'sunita@okicici',
            // smuggled — must trip the hasOnly check
            lineItems: [{ lineItemId: 'l1', skuId: 's1', quantity: 1, unitPriceInr: 1 }],
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → awaiting_verification cannot mutate totalAmount', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-av-total', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-total')
          .update({
            state: 'awaiting_verification',
            paymentMethod: 'upi',
            totalAmount: 100, // smuggled
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → awaiting_verification SUCCEEDS with paymentMethod + customerVpa only',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-av-min', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-min')
          .update({
            state: 'awaiting_verification',
            paymentMethod: 'upi',
            customerVpa: 'sunita@okicici',
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → awaiting_verification REJECTED if paymentMethod is cod',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-av-cod', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-cod')
          .update({
            state: 'awaiting_verification',
            paymentMethod: 'cod',
            updatedAt: new Date(),
          }),
      );
    });

    test('draft → committed cannot mutate paymentMethod', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-c-pm', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-c-pm')
          .update({
            state: 'committed',
            totalAmount: 15000,
            customerPhone: '+919876543210',
            paymentMethod: 'upi', // smuggled — not in commit branch allowlist
            updatedAt: new Date(),
          }),
      );
    });

    test('draft → committed cannot mutate customerVpa', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-c-vpa', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-c-vpa')
          .update({
            state: 'committed',
            totalAmount: 15000,
            customerVpa: 'sunita@okicici', // smuggled
            updatedAt: new Date(),
          }),
      );
    });

    test('draft → committed cannot mutate lineItems (server-authoritative on commit)',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-c-li', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-c-li')
          .update({
            state: 'committed',
            lineItems: [{ lineItemId: 'l1', skuId: 's1', quantity: 1, unitPriceInr: 1 }],
            totalAmount: 1,
            customerPhone: '+919876543210',
            updatedAt: new Date(),
          }),
      );
    });

    test('draft → committed SUCCEEDS with the commit-branch allowlist exactly',
        async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-c-ok', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-c-ok')
          .update({
            state: 'committed',
            totalAmount: 15000,
            customerPhone: '+919876543210',
            customerDisplayName: 'Sunita',
            committedAt: new Date(),
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → cancelled cannot mutate lineItems', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      // Seed a non-empty lineItems so the smuggled update is a real diff.
      await seedCustomerProject(shopId, 'p3-x-li', 'committed', {
        lineItems: [{ lineItemId: 'l0', skuId: 's0', quantity: 1, unitPriceInr: 1000 }],
      });
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-x-li')
          .update({
            state: 'cancelled',
            lineItems: [], // smuggled — not in cancel branch allowlist
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → cancelled cannot mutate totalAmount', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-x-total', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-x-total')
          .update({
            state: 'cancelled',
            totalAmount: 0, // smuggled
            updatedAt: new Date(),
          }),
      );
    });

    test('committed → cancelled cannot mutate paymentMethod', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-x-pm', 'committed');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-x-pm')
          .update({
            state: 'cancelled',
            paymentMethod: 'upi', // smuggled
            updatedAt: new Date(),
          }),
      );
    });

    test('draft → cancelled SUCCEEDS with state-only write', async () => {
      const shopId = 'shop_1';
      const uid = `cust-${shopId}-uid`;
      await seedCustomerProject(shopId, 'p3-x-ok', 'draft');
      const db = ctxAsCustomer(shopId, uid).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-x-ok')
          .update({
            state: 'cancelled',
            updatedAt: new Date(),
          }),
      );
    });

    // ----- Operator paid path Triple Zero gating -----

    test('operator mark-paid REJECTED if amountReceivedByShop != totalAmount',
        async () => {
      const shopId = 'shop_1';
      await seedCustomerProject(shopId, 'p3-op-paid-bad', 'committed');
      const db = ctxAsShopOperator(shopId).firestore();
      await assertFails(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-op-paid-bad')
          .update({
            state: 'paid',
            amountReceivedByShop: 14000, // != totalAmount 15000
            paidAt: new Date(),
            paymentMethod: 'cash',
            updatedAt: new Date(),
          }),
      );
    });

    test('operator mark-paid SUCCEEDS with matched Triple Zero', async () => {
      const shopId = 'shop_1';
      await seedCustomerProject(shopId, 'p3-op-paid-ok', 'committed');
      const db = ctxAsShopOperator(shopId).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-op-paid-ok')
          .update({
            state: 'paid',
            amountReceivedByShop: 15000,
            paidAt: new Date(),
            paymentMethod: 'cash',
            updatedAt: new Date(),
          }),
      );
    });

    test('operator mark-paid from awaiting_verification succeeds', async () => {
      const shopId = 'shop_1';
      await seedCustomerProject(shopId, 'p3-av-confirm', 'awaiting_verification');
      const db = ctxAsShopOperator(shopId).firestore();
      await assertSucceeds(
        db
          .collection('shops')
          .doc(shopId)
          .collection('projects')
          .doc('p3-av-confirm')
          .update({
            state: 'paid',
            amountReceivedByShop: 15000,
            paidAt: new Date(),
            paymentMethod: 'upi',
            updatedAt: new Date(),
          }),
      );
    });
  });
});
