// =============================================================================
// generateWaMeLink — I6.5 companion, WhatsApp deep-link generator.
//
// HTTPS Callable (onCall). Reads the shop's WhatsApp number from the theme
// document and constructs a wa.me deep link with an optional pre-filled
// Hindi message template including the project ID.
//
// Input: { shopId, projectId, messageText? }
// Returns: { url: string }
// =============================================================================

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

/// Default Hindi message template. The {projectId} placeholder is replaced
/// at runtime. This is the greeting a customer sees pre-filled in WhatsApp
/// when they tap "Chat on WhatsApp" from the app.
const DEFAULT_MESSAGE_TEMPLATE =
  'Namaste! Mujhe Project #{projectId} ke baare mein baat karni hai.';

interface GenerateWaMeLinkRequest {
  shopId: string;
  projectId: string;
  messageText?: string;
}

export const generateWaMeLink = onCall(
  {
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
    // §15.1.C — server-side App Check enforcement. Rejects calls that
    // arrive without a valid App Check token; prevents cross-tenant
    // phone number disclosure via unattested clients.
    enforceAppCheck: true,
  },
  async (request) => {
    // ── Auth check ──
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const data = request.data as GenerateWaMeLinkRequest;

    // ── Input validation ──
    if (!data.shopId || typeof data.shopId !== 'string') {
      throw new HttpsError('invalid-argument', 'shopId is required.');
    }
    if (!data.projectId || typeof data.projectId !== 'string') {
      throw new HttpsError('invalid-argument', 'projectId is required.');
    }

    const { shopId, projectId } = data;

    // BE001 fix: validate caller's shopId token matches the provided shopId.
    // Prevents cross-tenant phone number disclosure.
    const callerShopId = request.auth.token?.shopId;
    if (callerShopId !== shopId) {
      throw new HttpsError(
        'permission-denied',
        'Shop mismatch: caller does not belong to this shop.',
      );
    }

    const db = admin.firestore();

    // Read shop's WhatsApp number from theme document.
    const themeRef = db
      .collection('shops')
      .doc(shopId)
      .collection('theme')
      .doc('current');
    const themeSnap = await themeRef.get();

    if (!themeSnap.exists) {
      throw new HttpsError(
        'not-found',
        `Theme document not found for shop '${shopId}'.`,
      );
    }

    const themeData = themeSnap.data();
    const whatsappNumberE164 = themeData?.whatsappNumberE164;

    if (!whatsappNumberE164 || typeof whatsappNumberE164 !== 'string') {
      throw new HttpsError(
        'failed-precondition',
        `Shop '${shopId}' does not have a WhatsApp number configured.`,
      );
    }

    // Strip the leading '+' for wa.me URL format.
    const phone = whatsappNumberE164.replace(/^\+/, '');

    // Build the message text.
    const messageText =
      data.messageText && typeof data.messageText === 'string'
        ? data.messageText
        : DEFAULT_MESSAGE_TEMPLATE.replace('{projectId}', projectId);

    const url = `https://wa.me/${phone}?text=${encodeURIComponent(messageText)}`;

    logger.info('generateWaMeLink: link generated', {
      shopId,
      projectId,
      callerUid: request.auth.uid,
    });

    return { url };
  },
);
