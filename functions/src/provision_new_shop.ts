// =============================================================================
// provisionNewShop — Admin callable to create a new tenant from scratch.
//
// HTTPS Callable (onCall). Idempotent: if /shops/{slug} already exists,
// returns { exists: true, shopId: slug } without writing.
//
// Auth: caller must have request.auth.token.yugmaAdmin == true.
//       This claim is issued manually by the Yugma Labs team only.
//
// Input: { slug, brandName, brandNameDevanagari, ownerUid, ownerEmail,
//          whatsappNumberE164?, upiVpa? }
//
// Steps (on success):
//   (a) /shops/{slug}
//   (b) /shops/{slug}/theme/current
//   (c) /shops/{slug}/operators/{ownerUid}
//   (d) Custom claims: { shopId: slug, role: 'bhaiya' } on ownerUid
//   (e) Audit: /system/shop_provisioning_log/{slug}/{auto-id}
//
// Returns: { success: true, shopId: slug }
// =============================================================================

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

const SLUG_REGEX = /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/;

interface ProvisionNewShopRequest {
  slug: string;
  brandName: string;
  brandNameDevanagari: string;
  ownerUid: string;
  ownerEmail: string;
  whatsappNumberE164?: string;
  upiVpa?: string;
}

export const provisionNewShop = onCall(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 60,
    enforceAppCheck: true,
    secrets: ['JOIN_TOKEN_HMAC_SECRET'],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    if (!request.auth.token?.yugmaAdmin) {
      throw new HttpsError(
        'permission-denied',
        'Only Yugma admins may provision new shops.',
      );
    }

    const data = request.data as ProvisionNewShopRequest;

    if (!data.slug || typeof data.slug !== 'string') {
      throw new HttpsError('invalid-argument', 'slug is required.');
    }
    if (!SLUG_REGEX.test(data.slug)) {
      throw new HttpsError(
        'invalid-argument',
        `slug must match /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/.`,
      );
    }
    if (!data.brandName || typeof data.brandName !== 'string') {
      throw new HttpsError('invalid-argument', 'brandName is required.');
    }
    if (!data.brandNameDevanagari || typeof data.brandNameDevanagari !== 'string') {
      throw new HttpsError('invalid-argument', 'brandNameDevanagari is required.');
    }
    if (!data.ownerUid || typeof data.ownerUid !== 'string') {
      throw new HttpsError('invalid-argument', 'ownerUid is required.');
    }
    if (!data.ownerEmail || typeof data.ownerEmail !== 'string') {
      throw new HttpsError('invalid-argument', 'ownerEmail is required.');
    }

    const { slug, brandName, brandNameDevanagari, ownerUid, ownerEmail } = data;
    const whatsappNumberE164 = data.whatsappNumberE164 ?? null;
    const upiVpa = data.upiVpa ?? null;

    const db = admin.firestore();
    const shopRef = db.collection('shops').doc(slug);

    const existingSnap = await shopRef.get();
    if (existingSnap.exists) {
      logger.info('provisionNewShop: idempotent return — shop already exists', {
        slug,
        callerUid: request.auth.uid,
      });
      return { exists: true, shopId: slug };
    }

    logger.info('provisionNewShop: provisioning new shop', {
      slug,
      ownerUid,
      callerUid: request.auth.uid,
    });

    const batch = db.batch();

    // (a) /shops/{slug}
    batch.set(shopRef, {
      shopId: slug,
      brandName,
      brandNameDevanagari,
      ownerUid,
      ownerEmail,
      shopLifecycle: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // (b) /shops/{slug}/theme/current
    batch.set(shopRef.collection('theme').doc('current'), {
      primaryColor: '#6B3410',
      accentColor: '#A0522D',
      whatsappNumberE164,
      upiVpa,
      brandName,
      brandNameDevanagari,
      version: 1,
    });

    // (c) /shops/{slug}/operators/{ownerUid}
    batch.set(shopRef.collection('operators').doc(ownerUid), {
      uid: ownerUid,
      shopId: slug,
      role: 'bhaiya',
      displayName: brandName,
      email: ownerEmail,
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // (d) Custom claims
    await admin.auth().setCustomUserClaims(ownerUid, {
      shopId: slug,
      role: 'bhaiya',
    });

    // (e) Audit trail — best-effort, never blocks the success return.
    try {
      await db
        .collection('system')
        .doc('shop_provisioning_log')
        .collection(slug)
        .add({
          provisionedAt: admin.firestore.FieldValue.serverTimestamp(),
          slug,
          ownerUid,
          ownerEmail,
          brandName,
          callerUid: request.auth.uid,
        });
    } catch (err) {
      logger.error('provisionNewShop: audit log write failed (non-fatal)', {
        slug,
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('provisionNewShop: done', { slug, ownerUid });

    return { success: true, shopId: slug };
  },
);
