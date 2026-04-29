// =============================================================================
// seed_synthetic_shop_0.ts
//
// Populates the synthetic `shop_0` and `shop_1` tenants in the Firestore
// emulator. The cross-tenant integrity test
// (packages/lib_core/test/cross_tenant_integrity_test.dart) authenticates as
// a `shop_1` operator and asserts EVERY read and write against shop_0
// fails with permission-denied.
//
// This script ALSO seeds shop_1 with one matching document of every entity
// type so we can prove that same-shop operations succeed (the test must
// not be a false positive that rejects ALL operations).
//
// PRD I6.4 AC #3 — populates one document of every entity type.
// PRD I6.4 AC #5 — provides the test surface for cross-tenant rejection.
// PRD I6.4 AC #7 — provides the surface for the udhaar forbidden-field test.
//
// Run: FIRESTORE_EMULATOR_HOST=localhost:8080 npm run seed:synthetic
//
// **Canonicalization note (Sprint 2.3 cleanup per code review Agent A ❓):**
// There are currently two seed paths:
//   1. This script — invoked via `npm run seed:synthetic`, used for local
//      dev + manual emulator seeding
//   2. The `beforeEach()` hook in cross_tenant_integrity.test.ts — used
//      by CI to seed fresh emulator state for each test run
//
// The TWO seed paths must stay in sync manually. When you add or modify
// a field here, check the test's beforeEach and update both. A full
// refactor to have the test import this script's seed helpers is deferred
// to Sprint 3+ when it's worth the refactor cost (for Sprint 1+2, both
// paths are small and stable). The canonical source of truth for the
// schema is SAD v1.0.4 §5 — if these two paths disagree with the SAD,
// the SAD wins.
// =============================================================================

import {
  cert,
  initializeApp as initializeAdminApp,
  getApps,
} from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'yugma-dukaan-test';
const USING_EMULATOR =
  !!process.env.FIRESTORE_EMULATOR_HOST &&
  !!process.env.FIREBASE_AUTH_EMULATOR_HOST;

if (getApps().length === 0) {
  if (USING_EMULATOR) {
    // Emulator mode — no service account needed.
    initializeAdminApp({ projectId: PROJECT_ID });
    console.log(`[seed] Initialized admin SDK against emulator (${PROJECT_ID})`);
  } else {
    // Production mode — load service account from env.
    const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (!saPath) {
      throw new Error(
        'GOOGLE_APPLICATION_CREDENTIALS env var required for production seed',
      );
    }
    initializeAdminApp({
      credential: cert(saPath),
      projectId: PROJECT_ID,
    });
    console.log(`[seed] Initialized admin SDK against production (${PROJECT_ID})`);
  }
}

const db = getFirestore();
const auth = getAuth();

// -----------------------------------------------------------------------------
// Synthetic data per SAD §5 §7 — one of each entity type per shop
// -----------------------------------------------------------------------------

interface SyntheticShop {
  shopId: string;
  brandName: string;
  brandNameDevanagari: string;
  ownerUid: string;
  ownerEmail: string;
  uglyColors: boolean;
}

const SHOP_0: SyntheticShop = {
  shopId: 'shop_0',
  brandName: 'Synthetic Shop Zero',
  brandNameDevanagari: 'सिंथेटिक दुकान शून्य',
  ownerUid: 'op-shop-0-owner',
  ownerEmail: 'owner-shop-0@yugma-dukaan-test.local',
  uglyColors: true,
};

const SHOP_1: SyntheticShop = {
  shopId: 'shop_1',
  brandName: 'Synthetic Shop One',
  brandNameDevanagari: 'सिंथेटिक दुकान एक',
  ownerUid: 'op-shop-1-owner',
  ownerEmail: 'owner-shop-1@yugma-dukaan-test.local',
  uglyColors: false,
};

// -----------------------------------------------------------------------------
// Seed routine
// -----------------------------------------------------------------------------

async function seedShop(shop: SyntheticShop): Promise<void> {
  console.log(`[seed] Seeding ${shop.shopId}...`);

  // 1. Create the operator user in Firebase Auth with custom claims.
  try {
    await auth.createUser({
      uid: shop.ownerUid,
      email: shop.ownerEmail,
      emailVerified: true,
      displayName: `${shop.brandName} Owner`,
    });
  } catch (e: unknown) {
    if (e instanceof Error && e.message.includes('already exists')) {
      // OK — re-runnable.
    } else {
      throw e;
    }
  }
  await auth.setCustomUserClaims(shop.ownerUid, {
    shopId: shop.shopId,
    role: 'bhaiya',
  });

  const shopRef = db.collection('shops').doc(shop.shopId);
  const batch = db.batch();

  // 2. /shops/{shopId}
  // SAD v1.0.4 ADR-013 + §5 Shop lifecycle fields added:
  //   shopLifecycle, shopLifecycleChangedAt, shopLifecycleReason,
  //   dpdpRetentionUntil. "active" is the normal state; other states
  //   freeze client writes via the shopIsWritable() rule helper.
  batch.set(shopRef, {
    shopId: shop.shopId,
    brandName: shop.brandName,
    brandNameDevanagari: shop.brandNameDevanagari,
    ownerUid: shop.ownerUid,
    market: 'Synthetic Market, Test City',
    createdAt: new Date(),
    activeFromDay: new Date(),
    // ---- SAD v1.0.4 ADR-013 lifecycle fields ----
    shopLifecycle: 'active',
    shopLifecycleChangedAt: new Date(),
    shopLifecycleReason: null,
    dpdpRetentionUntil: null,
  });

  // 3. /shops/{shopId}/themeTokens/active
  batch.set(shopRef.collection('themeTokens').doc('active'), {
    shopId: shop.shopId,
    primaryColor: shop.uglyColors ? '#FF00FF' : '#6B3410',
    secondaryColor: shop.uglyColors ? '#00FFFF' : '#B8860B',
    accentColor: shop.uglyColors ? '#FFFF00' : '#7B1F1F',
    backgroundColor: shop.uglyColors ? '#000000' : '#FAF3E7',
    textColor: shop.uglyColors ? '#FFFFFF' : '#2C1810',
    fontFamilyDevanagari: 'Tiro Devanagari Hindi',
    fontFamilyEnglish: 'Fraunces',
    version: 1,
  });

  // 4. /operators/{uid}
  batch.set(db.collection('operators').doc(shop.ownerUid), {
    uid: shop.ownerUid,
    shopId: shop.shopId,
    role: 'bhaiya',
    displayName: `${shop.brandName} Owner`,
    email: shop.ownerEmail,
    createdAt: new Date(),
  });

  // 5. /shops/{shopId}/customers/{custId}
  // SAD v1.0.4 §5 Customer schema: previousProjectIds capped array (S4.18)
  batch.set(shopRef.collection('customers').doc('cust-1'), {
    shopId: shop.shopId,
    displayName: 'Test Customer 1',
    phoneNumber: '+919999900001',
    isPhoneVerified: true,
    previousProjectIds: [], // S4.18 repeat-customer event tracking
    createdAt: new Date(),
  });

  // 6. /shops/{shopId}/projects/{projId}
  // SAD v1.0.4 §5 Project schema: amountReceivedByShop invariant (Triple Zero,
  // zero-commission math testability per C3.4 AC #4 + C3.5 AC #8).
  batch.set(shopRef.collection('projects').doc('proj-1'), {
    shopId: shop.shopId,
    customerId: 'cust-1',
    state: 'draft',
    occasion: 'shaadi',
    lineItemIds: ['li-1'],
    totalAmount: 25000,
    amountReceivedByShop: 0, // zero until commit+payment; must == totalAmount at paid state
    unreadCountForCustomer: 0,
    unreadCountForShopkeeper: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  // 7. /shops/{shopId}/inventory/{skuId}
  batch.set(shopRef.collection('inventory').doc('sku-1'), {
    shopId: shop.shopId,
    name: 'Test Almirah 4-door',
    nameDevanagari: 'टेस्ट अलमारी 4-दरवाज़े',
    priceInr: 25000,
    inStock: true,
    createdAt: new Date(),
  });

  // 8. /shops/{shopId}/curatedShortlists/{shortlistId}
  batch.set(shopRef.collection('curatedShortlists').doc('shaadi'), {
    shopId: shop.shopId,
    occasion: 'shaadi',
    title: 'Sunil-bhaiya ki pasand for शादी',
    skuIds: ['sku-1'],
    isFinite: true,
    maxSize: 6,
    createdAt: new Date(),
  });

  // 9. /shops/{shopId}/chatThreads/{threadId}
  batch.set(shopRef.collection('chatThreads').doc('thread-1'), {
    shopId: shop.shopId,
    customerId: 'cust-1',
    participantUids: [shop.ownerUid],
    createdAt: new Date(),
    lastMessageAt: new Date(),
  });

  // 10. /shops/{shopId}/chatThreads/{threadId}/messages/{msgId}
  batch.set(
    shopRef.collection('chatThreads').doc('thread-1').collection('messages').doc('msg-1'),
    {
      shopId: shop.shopId,
      threadId: 'thread-1',
      senderUid: shop.ownerUid,
      type: 'text',
      text: 'Test message 1',
      createdAt: new Date(),
    },
  );

  // 11. /shops/{shopId}/voiceNotes/{noteId}
  batch.set(shopRef.collection('voiceNotes').doc('vn-1'), {
    shopId: shop.shopId,
    storagePath: `shops/${shop.shopId}/voice_notes/vn-1.aac`,
    durationMs: 1000,
    createdAt: new Date(),
  });

  // 12. /shops/{shopId}/udhaarLedger/{ledgerId}  (accounting mirror, ADR-010)
  // Deliberately uses ONLY allowed field names — no `interest`, no `dueDate`.
  // SAD v1.0.4 Fn 3 RBI guardrails: reminderOptInByBhaiya (explicit opt-in,
  // default false), reminderCountLifetime (capped at 3), reminderCadenceDays
  // (7–30 day range, default 14). Per PRD S4.10 AC #7/#8/#9.
  batch.set(shopRef.collection('udhaarLedger').doc('udh-1'), {
    shopId: shop.shopId,
    customerId: 'cust-1',
    recordedAmount: 10000,
    runningBalance: 10000,
    acknowledgedAt: new Date(),
    partialPaymentReferences: [],
    // ---- SAD v1.0.4 RBI guardrails ----
    reminderOptInByBhaiya: false, // MUST be explicitly opted in by operator
    reminderCountLifetime: 0, // incremented by sendUdhaarReminder, capped at 3
    reminderCadenceDays: 14, // default; operator adjustable 7–30
  });

  // 13. /shops/{shopId}/customerMemory/{memId}
  batch.set(shopRef.collection('customerMemory').doc('mem-1'), {
    shopId: shop.shopId,
    customerId: 'cust-1',
    note: 'Daughter pursuing MBBS, family from Lucknow originally',
    createdBy: shop.ownerUid,
    createdAt: new Date(),
  });

  // 14. /shops/{shopId}/goldenHourPhotos/{photoId}
  batch.set(shopRef.collection('goldenHourPhotos').doc('gh-1'), {
    shopId: shop.shopId,
    skuId: 'sku-1',
    cloudinaryPublicId: `synthetic/${shop.shopId}/gh-1`,
    capturedAt: new Date(),
  });

  // 15. /shops/{shopId}/featureFlags/active
  // SAD v1.0.4 §5 adds default_locale for Brief Constraint 15 fallback.
  batch.set(shopRef.collection('featureFlags').doc('active'), {
    shopId: shop.shopId,
    default_locale: 'hi', // Constraint 4 honored; flipped to 'en' only as END STATE B fallback
    decision_circle_enabled: false,
    otp_at_commit_enabled: true,
    in_app_chat_enabled: true,
    elder_tier_enabled: true,
    golden_hour_photo_enabled: true,
  });

  // 16. /shops/{shopId}/feedback/{feedbackId}  (SAD v1.0.4 §5 + S4.17)
  // One customer_nps doc + one shopkeeper_burnout_self_report doc per shop.
  // Feedback is append-only / immutable after create (security rule).
  batch.set(shopRef.collection('feedback').doc('fb-seed-customer-nps'), {
    feedbackId: 'fb-seed-customer-nps',
    shopId: shop.shopId,
    type: 'customer_nps',
    authorUid: 'cust-1-uid-placeholder',
    authorRole: 'customer',
    score: 9,
    comment: null,
    createdAt: new Date(),
  });
  batch.set(shopRef.collection('feedback').doc('fb-seed-shopkeeper-burnout'), {
    feedbackId: 'fb-seed-shopkeeper-burnout',
    shopId: shop.shopId,
    type: 'shopkeeper_burnout_self_report',
    authorUid: shop.ownerUid,
    authorRole: 'shopkeeper',
    score: 8,
    comment: null,
    createdAt: new Date(),
  });

  await batch.commit();
  console.log(`[seed] ${shop.shopId} seeded`);
}

async function main(): Promise<void> {
  await seedShop(SHOP_0);
  await seedShop(SHOP_1);
  console.log('[seed] Done.');
}

main().catch((err: unknown) => {
  console.error('[seed] FAILED:', err);
  process.exit(1);
});
