// =============================================================================
// triggerMarketingRebuild — PRD M5.5 + SAD v1.0.4 §7 Function 6.
//
// Watches writes to `shops/{shopId}/theme/current` and triggers a GitHub
// Actions workflow_dispatch to rebuild the Astro marketing site for that shop.
//
// Per M5.5 ACs:
//   AC #1: Cloud Function triggered by writes to shops/{shopId}/theme/current
//   AC #2: Calls GitHub Actions workflow_dispatch on ci-marketing.yml
//   AC #3: CI workflow runs Astro build for affected shop only (shop_id input)
//   AC #6: Nightly cron also rebuilds (configured in ci-marketing.yml, not here)
//   AC #7: Failed builds notify ops via email (configured in ci-marketing.yml)
//
// Edge cases:
//   #1: Multiple theme updates within 60s → debounce via lastRebuildTriggeredAt
//   #2: Build fails → previous version stays deployed (Firebase Hosting default)
//   #3: GitHub PAT rotation → update via `firebase functions:secrets:set GITHUB_PAT`
//
// Security: GitHub PAT is stored as a Firebase Functions secret (defineSecret).
// The PAT needs `actions:write` scope on the target repo only.
//
// Free-tier: GitHub Actions free for public repos / 2000 min/month private.
// Cloud Functions free tier covers this easily at one-shop scale.
// =============================================================================

import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

// ─── Secrets ───

const githubPat = defineSecret('GITHUB_PAT');

// ─── Constants ───

/// GitHub repo coordinates for workflow_dispatch.
const GITHUB_OWNER = 'aloktiwarigit';
const GITHUB_REPO = 'sunil_trading_comp';
const GITHUB_WORKFLOW_FILE = 'ci-marketing.yml';

/// Debounce tracking document path.
const REBUILD_STATUS_COLLECTION = 'system';
const REBUILD_STATUS_DOC = 'marketing_builds';

/// Minimum interval between rebuilds in milliseconds (60 seconds per Edge #1).
const DEBOUNCE_MS = 60_000;

// ─── Cloud Function ───

/// Triggered whenever any field in `shops/{shopId}/theme/current` is written.
/// Debounces rapid updates (Edge #1) and dispatches a GitHub Actions workflow
/// to rebuild + deploy the marketing site for the affected shop.
export const triggerMarketingRebuild = onDocumentWritten(
  {
    document: 'shops/{shopId}/theme/current',
    region: 'asia-south1',
    memory: '256MiB',
    timeoutSeconds: 30,
    secrets: [githubPat],
  },
  async (event) => {
    const shopId = event.params.shopId;

    logger.info('Theme update detected', { shopId });

    // ── Debounce check ──
    // Read the last rebuild timestamp from system/marketing_builds.
    // If a rebuild was triggered less than 60s ago for this shop, skip.
    const db = admin.firestore();
    const statusRef = db
      .collection(REBUILD_STATUS_COLLECTION)
      .doc(REBUILD_STATUS_DOC);

    const statusDoc = await statusRef.get();
    const statusData = statusDoc.data() ?? {};
    const lastTriggeredField = `lastTriggeredAt_${shopId}`;
    const lastTriggered = statusData[lastTriggeredField];

    if (lastTriggered) {
      const lastTriggeredMs =
        lastTriggered instanceof admin.firestore.Timestamp
          ? lastTriggered.toMillis()
          : typeof lastTriggered === 'number'
            ? lastTriggered
            : 0;

      const elapsed = Date.now() - lastTriggeredMs;
      if (elapsed < DEBOUNCE_MS) {
        logger.info('Debounced — rebuild already triggered recently', {
          shopId,
          elapsedMs: elapsed,
          debounceMs: DEBOUNCE_MS,
        });
        return;
      }
    }

    // ── Dispatch GitHub Actions workflow ──
    const pat = githubPat.value();
    if (!pat) {
      logger.error(
        'GITHUB_PAT secret is empty — cannot trigger workflow_dispatch. ' +
          'Run: firebase functions:secrets:set GITHUB_PAT',
      );
      return;
    }

    const dispatchUrl =
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}` +
      `/actions/workflows/${GITHUB_WORKFLOW_FILE}/dispatches`;

    try {
      const response = await fetch(dispatchUrl, {
        method: 'POST',
        headers: {
          Accept: 'application/vnd.github.v3+json',
          Authorization: `Bearer ${pat}`,
          'Content-Type': 'application/json',
          'User-Agent': 'yugma-dukaan-cloud-function',
        },
        body: JSON.stringify({
          ref: 'main',
          inputs: {
            shop_id: shopId,
          },
        }),
      });

      if (response.status === 204) {
        logger.info('GitHub Actions workflow_dispatch successful', {
          shopId,
          dispatchUrl,
        });
      } else {
        const body = await response.text();
        logger.error('GitHub Actions workflow_dispatch failed', {
          shopId,
          status: response.status,
          body,
        });
        // Do not throw — failed dispatch should not retry. The nightly cron
        // (AC #6) acts as a safety net. The error is logged for ops visibility.
        return;
      }
    } catch (err) {
      logger.error('Network error calling GitHub Actions', {
        shopId,
        error: err instanceof Error ? err.message : String(err),
      });
      return;
    }

    // ── Update debounce timestamp ──
    // Only update after successful dispatch so failed attempts can be retried.
    try {
      await statusRef.set(
        {
          [lastTriggeredField]:
            admin.firestore.FieldValue.serverTimestamp(),
          lastShopId: shopId,
        },
        { merge: true },
      );
    } catch (err) {
      // Non-critical — debounce state is best-effort. Next trigger may
      // fire a duplicate build, which is harmless (idempotent deploy).
      logger.warn('Failed to update rebuild debounce timestamp', {
        shopId,
        error: err instanceof Error ? err.message : String(err),
      });
    }

    logger.info('Marketing rebuild triggered successfully', { shopId });
  },
);
