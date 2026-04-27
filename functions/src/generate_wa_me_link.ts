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

import { mintJoinToken } from './lib/hmac_join_token';

/// Default Hindi message template. The {projectId} placeholder is replaced
/// at runtime. This is the greeting a customer sees pre-filled in WhatsApp
/// when they tap "Chat on WhatsApp" from the app.
const DEFAULT_MESSAGE_TEMPLATE =
  'Namaste! Mujhe Project #{projectId} ke baare mein baat karni hai.';

/// Per-shop subdomain pattern used in the join deep link
/// (https://{shopId}.yugmalabs.ai/join?token=...). The marketing site
/// catches `/join?token=...` and forwards into the customer app via
/// Android App Links / iOS Universal Links — Phase 1 multi-tenant work
/// per docs/architecture-source-of-truth.md §15. Until that infra ships,
/// the URL still goes out and is signature-verifiable; the recipient
/// just sees the marketing site instead of the app.
const JOIN_DEEP_LINK_HOST_TEMPLATE = 'https://{shopId}.yugmalabs.ai/join';

interface GenerateWaMeLinkRequest {
  shopId: string;
  projectId: string;
  messageText?: string;
  /**
   * Opt-in flag — when `true`, the response wa.me text includes a
   * Decision-Circle join deep link signed with an HMAC-SHA256 token (ADR-009
   * v1.0.3 / drift §15.1.A). The token's `originalCustomerUid` is the
   * caller's `request.auth.uid` — never trust a caller-supplied value.
   */
  includeJoinLink?: boolean;
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
    // §15.1.A — HMAC join token signing. Wired via Firebase Secret
    // Manager: set with `firebase functions:secrets:set
    // JOIN_TOKEN_HMAC_SECRET` per docs/runbook/staging-setup.md.
    secrets: ['JOIN_TOKEN_HMAC_SECRET'],
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
    let messageText =
      data.messageText && typeof data.messageText === 'string'
        ? data.messageText
        : DEFAULT_MESSAGE_TEMPLATE.replace('{projectId}', projectId);

    // §15.1.A — append a signed Decision-Circle join deep link if the
    // caller asked for one. The token binds {shopId, projectId,
    // originalCustomerUid: callerUid, expiresAt: now+7d} and is verified
    // by `joinDecisionCircle` before the actual merge. The caller's
    // `originalCustomerUid` is the auth.uid — caller-supplied UIDs are
    // ignored to prevent spoofing.
    if (data.includeJoinLink === true) {
      const joinToken = mintJoinToken({
        shopId,
        projectId,
        originalCustomerUid: request.auth.uid,
      });
      const joinUrl =
        JOIN_DEEP_LINK_HOST_TEMPLATE.replace('{shopId}', shopId) +
        `?token=${encodeURIComponent(joinToken)}`;
      messageText = `${messageText}\n\n${joinUrl}`;
    }

    const url = `https://wa.me/${phone}?text=${encodeURIComponent(messageText)}`;

    logger.info('generateWaMeLink: link generated', {
      shopId,
      projectId,
      callerUid: request.auth.uid,
      includeJoinLink: data.includeJoinLink === true,
    });

    return { url };
  },
);
