// =============================================================================
// fetch_shop_content.ts — Build-time Firestore content fetch (M5.3 + M5.5).
//
// Per ADR-011 + SAD §10 Q4: this runs during `astro build`, NOT in the
// browser. Output is baked into static HTML. Zero runtime Firestore reads.
//
// Security: uses Firebase admin SDK with a READ-ONLY service account scoped to:
//   - shops/{shopId}/theme/current
//   - shops/{shopId}/voice_notes/{greetingVoiceNoteId}
//   - shops/{shopId}/curatedShortlists (top 6 picks for catalog preview)
//
// Credential: FIREBASE_MARKETING_READONLY_SA_JSON env var (GitHub Actions
// secret). Local dev falls back to hardcoded flagship shop data — no
// credentials needed for `astro dev`.
//
// Adapted from: _bmad-output/planning-artifacts/frontend-design-bundle/
//               marketing-site/fetch_shop_content.ts
// =============================================================================

// ─── Types matching ShopThemeTokens schema ───

export interface ShopContent {
  shopId: string;
  brandName: string;
  brandNameEnglish: string;
  ownerName: string;
  taglineDevanagari: string;
  taglineEnglish: string;
  city: string;
  marketArea: string;
  establishedYear: number;
  whatsappNumberE164: string;
  upiVpa: string;
  gstNumber: string | null;
  shopkeeperFaceUrl: string;
  greetingVoiceNoteUrl: string;
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

// ─── Hardcoded fallback for local dev (no Firebase creds) ───

const FALLBACK_SHOP: ShopContent = {
  shopId: 'sunil-trading-company',
  brandName: 'सुनील ट्रेडिंग कंपनी',
  brandNameEnglish: 'Sunil Trading Company',
  ownerName: 'सुनील भैया',
  taglineDevanagari: 'हैरिंगटनगंज, अयोध्या की भरोसेमंद अलमारी दुकान',
  taglineEnglish: 'The trusted almirah shop in Harringtonganj, Ayodhya',
  city: 'अयोध्या',
  marketArea: 'हैरिंगटनगंज बाज़ार',
  establishedYear: 2003,
  whatsappNumberE164: '+919876543210',
  upiVpa: 'sunil@oksbi',
  gstNumber: 'GST: 09AXXXX1234X1ZX',
  shopkeeperFaceUrl: '',
  greetingVoiceNoteUrl: '',
  curatedPreview: [
    {
      skuId: 'placeholder-godrej-2d',
      nameDevanagari: 'गोदरेज स्टील अलमारी (2 दरवाज़ा)',
      nameEnglish: 'Godrej Steel Almirah — 2 Door',
      priceInr: 14500,
      thumbnailUrl: '',
    },
    {
      skuId: 'placeholder-godrej-4d',
      nameDevanagari: 'गोदरेज स्टील अलमारी (4 दरवाज़ा)',
      nameEnglish: 'Godrej Steel Almirah — 4 Door',
      priceInr: 28000,
      thumbnailUrl: '',
    },
    {
      skuId: 'placeholder-triveni',
      nameDevanagari: 'त्रिवेणी लोहे की अलमारी',
      nameEnglish: 'Triveni Iron Almirah',
      priceInr: 11000,
      thumbnailUrl: '',
    },
    {
      skuId: 'placeholder-local-single',
      nameDevanagari: 'लोकल लोहे की अलमारी (सिंगल)',
      nameEnglish: 'Local Iron Almirah — Single',
      priceInr: 6500,
      thumbnailUrl: '',
    },
    {
      skuId: 'placeholder-local-double',
      nameDevanagari: 'लोकल लोहे की अलमारी (डबल)',
      nameEnglish: 'Local Iron Almirah — Double',
      priceInr: 12000,
      thumbnailUrl: '',
    },
    {
      skuId: 'placeholder-dressing',
      nameDevanagari: 'लोहे की ड्रेसिंग टेबल',
      nameEnglish: 'Iron Dressing Table',
      priceInr: 5500,
      thumbnailUrl: '',
    },
  ],
  primaryColor: '#1B3A4B',
  accentColor: '#B8860B',
};

// ─── Main fetch function ───

/**
 * Fetches shop content from Firestore at build time. Falls back to hardcoded
 * data when credentials are unavailable (local dev, CI without secrets).
 *
 * M5.3 ACs:
 *   #1: Top 6 SKUs from most recent curated shortlist baked at build time
 *   #2: Each preview shows Golden Hour photo, Devanagari name, price
 *   #4: "पूरा कैटलॉग देखिए" CTA links into customer app
 */
export async function fetchShopContent(
  shopId: string,
): Promise<ShopContent> {
  const saJson = import.meta.env.FIREBASE_MARKETING_READONLY_SA_JSON
    ?? process.env.FIREBASE_MARKETING_READONLY_SA_JSON
    ?? '';

  if (!saJson) {
    console.warn(
      '[fetch_shop_content] No FIREBASE_MARKETING_READONLY_SA_JSON — using fallback data.',
    );
    return { ...FALLBACK_SHOP, shopId };
  }

  // Dynamic import to avoid bundling firebase-admin in the static output.
  // Astro tree-shakes server-only imports from the client bundle.
  const { initializeApp, cert, getApps } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  const { getStorage } = await import('firebase-admin/storage');

  // Initialize admin SDK once
  const serviceAccount = JSON.parse(saJson);
  const app =
    getApps().length > 0
      ? getApps()[0]
      : initializeApp({
          credential: cert(serviceAccount),
          storageBucket:
            import.meta.env.FIREBASE_STORAGE_BUCKET
            ?? process.env.FIREBASE_STORAGE_BUCKET
            ?? 'yugma-dukaan-dev.firebasestorage.app',
        });

  const db = getFirestore(app);
  const storage = getStorage(app);

  // 1. Fetch shop theme tokens
  const themeDoc = await db
    .collection('shops')
    .doc(shopId)
    .collection('theme')
    .doc('current')
    .get();

  if (!themeDoc.exists) {
    console.warn(
      `[fetch_shop_content] No theme at shops/${shopId}/theme/current — using fallback.`,
    );
    return { ...FALLBACK_SHOP, shopId };
  }

  const theme = themeDoc.data()!;

  // 2. Fetch greeting voice note signed URL (7-day expiry)
  let greetingVoiceNoteUrl = '';
  if (theme.greetingVoiceNoteId) {
    try {
      const voiceFile = storage
        .bucket()
        .file(`shops/${shopId}/voice_notes/${theme.greetingVoiceNoteId}.m4a`);
      const [signedUrl] = await voiceFile.getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
      });
      greetingVoiceNoteUrl = signedUrl;
    } catch (e) {
      console.warn(
        `[fetch_shop_content] Voice note unavailable for ${shopId}:`,
        e,
      );
    }
  }

  // 3. Fetch top curated shortlist for catalog preview (M5.3 AC #1)
  const curatedPreview: SkuPreview[] = [];

  try {
    const shortlistsSnap = await db
      .collection('shops')
      .doc(shopId)
      .collection('curatedShortlists')
      .where('isActive', '==', true)
      .where('occasion', '==', 'shaadi')
      .limit(1)
      .get();

    if (!shortlistsSnap.empty) {
      const shortlist = shortlistsSnap.docs[0].data();
      const skuIds = (shortlist.skuIdsInOrder as string[]).slice(0, 6);

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
  } catch (e) {
    console.warn(
      `[fetch_shop_content] Shortlist fetch failed for ${shopId}:`,
      e,
    );
  }

  // M5.3 Edge #1: No curated shortlist → empty array (template shows "जल्द ही")

  return {
    shopId: theme.shopId ?? shopId,
    brandName: theme.brandName ?? FALLBACK_SHOP.brandName,
    brandNameEnglish: theme.brandNameEnglish ?? FALLBACK_SHOP.brandNameEnglish,
    ownerName: theme.ownerName ?? FALLBACK_SHOP.ownerName,
    taglineDevanagari:
      theme.taglineDevanagari ?? FALLBACK_SHOP.taglineDevanagari,
    taglineEnglish: theme.taglineEnglish ?? FALLBACK_SHOP.taglineEnglish,
    city: theme.city ?? FALLBACK_SHOP.city,
    marketArea: theme.marketArea ?? FALLBACK_SHOP.marketArea,
    establishedYear: theme.establishedYear ?? FALLBACK_SHOP.establishedYear,
    whatsappNumberE164:
      theme.whatsappNumberE164 ?? FALLBACK_SHOP.whatsappNumberE164,
    upiVpa: theme.upiVpa ?? FALLBACK_SHOP.upiVpa,
    gstNumber: theme.gstNumber ?? null,
    shopkeeperFaceUrl: theme.shopkeeperFaceUrl ?? '',
    greetingVoiceNoteUrl,
    curatedPreview,
    primaryColor: theme.primaryColorHex ?? FALLBACK_SHOP.primaryColor,
    accentColor: theme.accentColorHex ?? FALLBACK_SHOP.accentColor,
  };
}
