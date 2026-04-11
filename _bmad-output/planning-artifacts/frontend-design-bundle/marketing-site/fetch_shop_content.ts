// sites/marketing/scripts/fetch_shop_content.ts
//
// Build-time Firestore content fetch for the Astro marketing site.
// Per locked PQ4 + ADR-011 + SAD §10 Q4 lockup: this script runs
// during `astro build`, NOT in the browser. The output is baked
// into static HTML.
//
// Security: uses Firebase admin SDK with a READ-ONLY service account
// scoped to:
//   - shops/{shopId}/theme/current
//   - shops/{shopId}/voice_notes/{greetingVoiceNoteId}
//   - shops/{shopId}/curated_shortlists (top 6 picks for catalog preview)
// Nothing else. Minimum-privilege blast radius per Winston's lockup.
//
// The credential is a GitHub Actions secret (FIREBASE_MARKETING_READONLY_SA_JSON).
// Local dev uses a separate dev-only service account file in .gitignore.
//
// Trigger paths:
//   1. Automatic rebuild via Cloud Function watching theme/current writes
//      (calls workflow_dispatch on ci-marketing.yml)
//   2. Nightly cron rebuild as safety net
//   3. Manual trigger via `gh workflow run ci-marketing.yml`

import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

// ─── Types matching ShopThemeTokens schema ───

export interface ShopContent {
  shopId: string;
  brandName: string; // Devanagari
  brandNameEnglish: string;
  ownerName: string; // "सुनील भैया"
  taglineDevanagari: string;
  taglineEnglish: string;
  city: string;
  marketArea: string;
  establishedYear: number;
  whatsappNumberE164: string;
  upiVpa: string;
  gstNumber: string | null;
  shopkeeperFaceUrl: string;
  greetingVoiceNoteUrl: string; // signed URL fetched at build time
  curatedPreview: SkuPreview[];
  primaryColor: string;
  accentColor: string;
}

export interface SkuPreview {
  skuId: string;
  nameDevanagari: string;
  nameEnglish: string;
  priceInr: number;
  thumbnailUrl: string;
}

// ─── Initialize Firebase admin once ───

function getAdminApp() {
  if (getApps().length > 0) return getApps()[0];

  const serviceAccount = JSON.parse(
    process.env.FIREBASE_MARKETING_READONLY_SA_JSON ??
      '{}'
  );

  return initializeApp({
    credential: cert(serviceAccount),
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
}

// ─── Main fetch function ───

export async function fetchShopContent(shopId: string): Promise<ShopContent> {
  const app = getAdminApp();
  const db = getFirestore(app);
  const storage = getStorage(app);

  // 1. Fetch the shop's theme tokens
  const themeDoc = await db
    .collection('shops')
    .doc(shopId)
    .collection('theme')
    .doc('current')
    .get();

  if (!themeDoc.exists) {
    throw new Error(
      `[fetch_shop_content] No theme document at shops/${shopId}/theme/current — run shop onboarding first.`
    );
  }

  const theme = themeDoc.data()!;

  // 2. Fetch the greeting voice note (signed URL)
  let greetingVoiceNoteUrl = '';
  if (theme.greetingVoiceNoteId) {
    try {
      const voiceNoteFile = storage
        .bucket()
        .file(`shops/${shopId}/voice_notes/${theme.greetingVoiceNoteId}.m4a`);

      const [signedUrl] = await voiceNoteFile.getSignedUrl({
        action: 'read',
        // 7-day expiry — long enough for the marketing site to be cached
        // by the CDN, short enough to rotate if needed.
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
      });
      greetingVoiceNoteUrl = signedUrl;
    } catch (e) {
      console.warn(
        `[fetch_shop_content] Greeting voice note unavailable for ${shopId}:`,
        e
      );
    }
  }

  // 3. Fetch the top curated shortlist for catalog preview
  const shortlistsSnapshot = await db
    .collection('shops')
    .doc(shopId)
    .collection('curated_shortlists')
    .where('isActive', '==', true)
    .where('occasion', '==', 'shaadi') // wedding shortlist as the marketing default
    .limit(1)
    .get();

  const curatedPreview: SkuPreview[] = [];

  if (!shortlistsSnapshot.empty) {
    const shortlist = shortlistsSnapshot.docs[0].data();
    const skuIds = (shortlist.skuIdsInOrder as string[]).slice(0, 6);

    // Fetch each SKU
    for (const skuId of skuIds) {
      const skuDoc = await db
        .collection('shops')
        .doc(shopId)
        .collection('inventory')
        .doc(skuId)
        .get();

      if (skuDoc.exists) {
        const sku = skuDoc.data()!;
        curatedPreview.push({
          skuId,
          nameDevanagari: sku.nameDevanagari ?? sku.name ?? '',
          nameEnglish: sku.nameEnglish ?? sku.name ?? '',
          priceInr: sku.basePrice ?? 0,
          thumbnailUrl: sku.fallbackPhotoUrls?.[0] ?? '',
        });
      }
    }
  }

  // 4. Build and return
  return {
    shopId: theme.shopId,
    brandName: theme.brandName,
    brandNameEnglish: theme.brandNameEnglish,
    ownerName: theme.ownerName,
    taglineDevanagari: theme.taglineDevanagari,
    taglineEnglish: theme.taglineEnglish,
    city: theme.city,
    marketArea: theme.marketArea,
    establishedYear: theme.establishedYear,
    whatsappNumberE164: theme.whatsappNumberE164,
    upiVpa: theme.upiVpa,
    gstNumber: theme.gstNumber ?? null,
    shopkeeperFaceUrl: theme.shopkeeperFaceUrl ?? '',
    greetingVoiceNoteUrl,
    curatedPreview,
    primaryColor: theme.primaryColorHex,
    accentColor: theme.accentColorHex,
  };
}
