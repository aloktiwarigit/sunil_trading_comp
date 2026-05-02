// =============================================================================
// cross_tenant_storage.test.ts
//
// Storage security rules test (Phase 1 hardening).
//
// Tests storage.rules for:
//   1. Cross-tenant write rejection (shop_1 op → shop_0 paths)
//   2. Non-operator rejection (customer cannot write voice notes / branding)
//   3. Lifecycle freeze — deactivated shop blocks uploads
//   4. Valid same-shop operator upload succeeds (green path)
//
// NOTE: storage.rules uses firestore.get() inside shopIsWritable(), which
// requires both the Firestore and Storage emulators to be running and the
// shop documents to be seeded. The auth context from the storage request is
// forwarded to the Firestore lookup, so `allow read: if isSignedIn()` on the
// /shops/{shopId} doc is satisfied for all authenticated callers here.
//
// Run: firebase emulators:exec --only firestore,storage \
//        --project yugma-dukaan-rules-test \
//        "cd tools && npm run test:rules"
// =============================================================================

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/storage';
import { readFileSync } from 'fs';
import { resolve } from 'path';

const PROJECT_ID = 'yugma-dukaan-rules-test';
const FIRESTORE_RULES_PATH = resolve(__dirname, '../../firestore.rules');
const STORAGE_RULES_PATH = resolve(__dirname, '../../storage.rules');

// Small buffers — the rules only check contentType metadata, not file content.
const AUDIO_BYTES = new Uint8Array([0xFF, 0xF1, 0x50, 0x80, 0x00, 0x1F, 0x00, 0x00]);
const IMAGE_BYTES = new Uint8Array([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

// The compat Storage SDK's put() returns an UploadTask (not a plain Promise).
// assertFails/assertSucceeds require a Promise, so we wrap with .then().
function upload(
  ref: firebase.storage.Reference,
  bytes: Uint8Array,
  meta: { contentType: string },
): Promise<void> {
  return ref.put(bytes, meta).then(() => undefined);
}

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(FIRESTORE_RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: readFileSync(STORAGE_RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();

  // Seed shop docs so shopIsWritable() lookups in storage rules succeed.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const shopId of ['shop_0', 'shop_1']) {
      await db.collection('shops').doc(shopId).set({
        shopId,
        shopLifecycle: 'active',
        brandName: `Synthetic Shop ${shopId}`,
      });
    }
  });
});

// Helper: authenticated operator context
function ctxAsOperator(shopId: string) {
  return testEnv.authenticatedContext(`op-${shopId}-owner`, {
    shopId,
    role: 'bhaiya',
    firebase: { sign_in_provider: 'google.com' },
  });
}

// Helper: authenticated customer context (phone sign-in — NOT an operator)
function ctxAsCustomer(shopId: string) {
  return testEnv.authenticatedContext(`cust-${shopId}-uid`, {
    shopId,
    firebase: { sign_in_provider: 'phone' },
  });
}

async function setShopLifecycle(
  shopId: string,
  lifecycle: 'active' | 'deactivating' | 'purge_scheduled' | 'purged',
): Promise<void> {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection('shops').doc(shopId).update({ shopLifecycle: lifecycle });
  });
}

// =============================================================================
// Storage rules tests — voice_notes
// =============================================================================

describe('Storage rules — voice_notes', () => {
  test('shop_1 operator cannot upload voice note to shop_0 path (cross-tenant)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_0/voice_notes/intruder.aac');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('customer (phone sign-in) cannot upload voice note (operator-only path)', async () => {
    const storage = ctxAsCustomer('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/voice_notes/cust-attempt.aac');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('upload to deactivated shop is rejected (lifecycle freeze)', async () => {
    await setShopLifecycle('shop_1', 'deactivating');
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/voice_notes/post-deactivate.aac');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('upload with wrong content type is rejected (must be audio/*)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/voice_notes/wrong-type.aac');
    await assertFails(upload(fileRef, IMAGE_BYTES, { contentType: 'image/png' }));
  });

  test('same-shop operator can upload valid voice note (no false positive)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/voice_notes/valid.aac');
    await assertSucceeds(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });
});

// =============================================================================
// Storage rules tests — branding
// =============================================================================

describe('Storage rules — branding', () => {
  test('shop_1 operator cannot upload branding to shop_0 path (cross-tenant)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_0/branding/logo.png');
    await assertFails(upload(fileRef, IMAGE_BYTES, { contentType: 'image/png' }));
  });

  test('customer (phone sign-in) cannot upload branding (operator-only path)', async () => {
    const storage = ctxAsCustomer('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/branding/cust-attempt.png');
    await assertFails(upload(fileRef, IMAGE_BYTES, { contentType: 'image/png' }));
  });

  test('upload to deactivated shop is rejected (lifecycle freeze)', async () => {
    await setShopLifecycle('shop_1', 'deactivating');
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/branding/post-deactivate.png');
    await assertFails(upload(fileRef, IMAGE_BYTES, { contentType: 'image/png' }));
  });

  test('upload with wrong content type is rejected (must be image/*)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/branding/wrong-type.png');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('same-shop operator can upload valid branding image (no false positive)', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('shops/shop_1/branding/logo.png');
    await assertSucceeds(upload(fileRef, IMAGE_BYTES, { contentType: 'image/png' }));
  });
});

// =============================================================================
// Storage rules tests — unauthenticated and catch-all
// =============================================================================

describe('Storage rules — unauthenticated and catch-all', () => {
  test('unauthenticated upload is rejected', async () => {
    const storage = testEnv.unauthenticatedContext().storage();
    const fileRef = storage.ref('shops/shop_1/voice_notes/anon.aac');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('path outside /shops/* is denied', async () => {
    const storage = ctxAsOperator('shop_1').storage();
    const fileRef = storage.ref('random/path/file.aac');
    await assertFails(upload(fileRef, AUDIO_BYTES, { contentType: 'audio/aac' }));
  });

  test('branding read is public (marketing site path)', async () => {
    // First upload via rules-disabled context, then read as unauthenticated.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const fileRef = ctx.storage().ref('shops/shop_1/branding/logo.png');
      await fileRef.put(IMAGE_BYTES, { contentType: 'image/png' });
    });
    const storage = testEnv.unauthenticatedContext().storage();
    const fileRef = storage.ref('shops/shop_1/branding/logo.png');
    await assertSucceeds(fileRef.getDownloadURL());
  });
});
