// =============================================================================
// seed_flagship.ts — Populate the flagship `sunil-trading-company` tenant.
//
// Seeds realistic demo data so the customer app shows content on first launch:
// - 1 shop doc + 1 theme doc
// - 6 inventory SKUs (almirahs across categories/materials/price points)
// - 6 curated shortlists (one per occasion, each referencing 3-6 SKUs)
//
// Run against dev:
//   GCLOUD_PROJECT=yugma-dukaan-dev \
//   GOOGLE_APPLICATION_CREDENTIALS=path/to/sa.json \
//   npm run seed:flagship
//
// Run against emulator:
//   GCLOUD_PROJECT=yugma-dukaan-dev \
//   FIRESTORE_EMULATOR_HOST=localhost:8080 \
//   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
//   npm run seed:flagship
// =============================================================================

import {
  applicationDefault,
  cert,
  initializeApp as initializeAdminApp,
  getApps,
} from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

const PROJECT_ID = process.env.GCLOUD_PROJECT ?? 'yugma-dukaan-dev';
const USING_EMULATOR = !!process.env.FIRESTORE_EMULATOR_HOST;

if (getApps().length === 0) {
  if (USING_EMULATOR) {
    initializeAdminApp({ projectId: PROJECT_ID });
    console.log(`[seed:flagship] Emulator mode (${PROJECT_ID})`);
  } else {
    const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (saPath && saPath.endsWith('.json')) {
      // Service account JSON file
      initializeAdminApp({
        credential: cert(saPath),
        projectId: PROJECT_ID,
      });
    } else {
      // Application Default Credentials (gcloud auth application-default login)
      initializeAdminApp({
        credential: applicationDefault(),
        projectId: PROJECT_ID,
      });
    }
    console.log(`[seed:flagship] Production mode (${PROJECT_ID})`);
  }
}

const db = getFirestore();

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

const SHOP_ID = 'sunil-trading-company';
const shopRef = db.collection('shops').doc(SHOP_ID);

// SKU IDs
const SKU_GODREJ_4DOOR = 'sku-godrej-4door';
const SKU_STEEL_3DOOR_MIRROR = 'sku-steel-3door-mirror';
const SKU_STEEL_LOCKER = 'sku-steel-locker';
const SKU_STEEL_PREMIUM_6DOOR = 'sku-steel-premium-6door';
const SKU_STEEL_DRESSING = 'sku-steel-dressing';
const SKU_BUDGET_STEEL = 'sku-budget-steel';

// -----------------------------------------------------------------------------
// Seed
// -----------------------------------------------------------------------------

async function seedFlagship(): Promise<void> {
  console.log(`[seed:flagship] Seeding ${SHOP_ID}...`);

  const batch = db.batch();

  // ---- 1. Shop doc ----
  batch.set(
    shopRef,
    {
      shopId: SHOP_ID,
      brandName: 'Sunil Trading Company',
      brandNameDevanagari: 'सुनील ट्रेडिंग कंपनी',
      ownerUid: '', // no operator linked in customer-only context
      market: 'Harringtonganj, Ayodhya',
      createdAt: new Date(),
      activeFromDay: new Date('2003-01-01'),
      shopLifecycle: 'active',
      shopLifecycleChangedAt: new Date(),
      shopLifecycleReason: null,
      dpdpRetentionUntil: null,
    },
    { merge: true },
  );
  console.log('  + shop doc');

  // ---- 2. Theme doc (matches ShopThemeTokens.sunilTradingCompanyDefault) ----
  batch.set(
    shopRef.collection('theme').doc('current'),
    {
      shopId: SHOP_ID,
      brandName: 'सुनील ट्रेडिंग कंपनी',
      brandNameEnglish: 'Sunil Trading Company',
      ownerName: 'सुनील भैया',
      taglineDevanagari: 'पीढ़ियों का भरोसा, आज भी',
      taglineEnglish: 'Generations of trust, even today',
      primaryColorHex: '#6B3410',
      primaryDeepColorHex: '#4A2308',
      secondaryColorHex: '#8B4513',
      accentColorHex: '#B8860B',
      accentGlowColorHex: '#D4A547',
      commitColorHex: '#7B1F1F',
      backgroundColorHex: '#FAF3E7',
      surfaceColorHex: '#FFFAF0',
      textPrimaryColorHex: '#1F1611',
      textOnPrimaryColorHex: '#FAF3E7',
      fontFamilyDevanagariDisplay: 'Tiro Devanagari Hindi',
      fontFamilyDevanagariBody: 'Mukta',
      fontFamilyEnglishDisplay: 'Fraunces',
      fontFamilyEnglishBody: 'EB Garamond',
      shopkeeperFaceUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
      greetingVoiceNoteId: '', // no audio file uploaded yet
      city: 'Ayodhya',
      marketArea: 'Harringtonganj',
      establishedYear: 2003,
      whatsappNumberE164: '+919876543210',
      upiVpa: 'sunil@oksbi',
      gstNumber: null,
      bankAccountNumber: null,
      bankIfsc: null,
      bankAccountHolderName: null,
      bankBranch: null,
      version: 1,
      updatedAt: new Date(),
    },
    { merge: true },
  );
  console.log('  + theme/current');

  // ---- 3. Inventory: 6 SKUs (mostly iron/steel — Sunil bhaiya's specialty) ----
  const skus = [
    {
      skuId: SKU_GODREJ_4DOOR,
      name: 'Godrej-style 4-door Steel Almirah',
      nameDevanagari: 'गोदरेज स्टाइल 4 दरवाज़े स्टील अलमारी',
      description: 'चार दरवाज़ों वाली मज़बूत स्टील अलमारी — पूरे परिवार का सामान आराम से आ जाए। पाउडर कोटेड फ़िनिश, ज़ंग नहीं लगता। लॉक के साथ।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 182, widthCm: 122, depthCm: 56 },
      basePrice: 18500,
      negotiableDownTo: 16000,
      occasionTags: ['shaadi', 'naya_ghar', 'replacement'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=800&q=80',
        'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=80',
      ],
    },
    {
      skuId: SKU_STEEL_3DOOR_MIRROR,
      name: '3-door Steel Almirah with Full Mirror',
      nameDevanagari: '3 दरवाज़े स्टील अलमारी — फ़ुल आईना',
      description: 'तीन दरवाज़ों वाली स्टील अलमारी, बीच में पूरे कद का आईना। बेटी की विदाई के लिए सबसे ज़्यादा बिकती है। मज़बूत हैंडल, सॉफ़्ट क्लोज़।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 190, widthCm: 152, depthCm: 58 },
      basePrice: 24000,
      negotiableDownTo: 21000,
      occasionTags: ['shaadi', 'beti_ka_ghar', 'ladies'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80',
        'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=800&q=80',
      ],
    },
    {
      skuId: SKU_STEEL_LOCKER,
      name: 'Heavy-duty Steel Locker Almirah',
      nameDevanagari: 'हैवी ड्यूटी स्टील लॉकर अलमारी',
      description: 'डबल लॉकिंग सिस्टम, 18 गेज स्टील, ज़ेवर और ज़रूरी कागज़ात रखने के लिए। दीवार में फ़िक्स हो जाती है।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 165, widthCm: 85, depthCm: 50 },
      basePrice: 14000,
      negotiableDownTo: 12000,
      occasionTags: ['naya_ghar', 'replacement'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80',
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&q=80',
      ],
    },
    {
      skuId: SKU_STEEL_PREMIUM_6DOOR,
      name: 'Premium 6-door Steel Wardrobe',
      nameDevanagari: 'प्रीमियम 6 दरवाज़े स्टील वॉर्डरोब',
      description: 'छह दरवाज़ों वाला बड़ा वॉर्डरोब — ऊपर तीन, नीचे तीन। शादी के सारे कपड़े और बिस्तर आ जाएँ। प्रीमियम मैट फ़िनिश।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 200, widthCm: 180, depthCm: 60 },
      basePrice: 32000,
      negotiableDownTo: 28000,
      occasionTags: ['shaadi', 'beti_ka_ghar'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=800&q=80',
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&q=80',
      ],
    },
    {
      skuId: SKU_STEEL_DRESSING,
      name: 'Steel Dressing Table with Mirror',
      nameDevanagari: 'स्टील ड्रेसिंग टेबल आईने वाली',
      description: 'स्टील फ़्रेम, बड़ा आईना, तीन दराज़ — मेकअप का सारा सामान सेट। पाउडर कोटेड, कलर ऑप्शन में उपलब्ध।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 150, widthCm: 90, depthCm: 45 },
      basePrice: 8500,
      negotiableDownTo: 7000,
      occasionTags: ['shaadi', 'beti_ka_ghar', 'ladies'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=800&q=80',
        'https://images.unsplash.com/photo-1631679706909-1844bbd07221?w=800&q=80',
      ],
    },
    {
      skuId: SKU_BUDGET_STEEL,
      name: 'Budget 2-door Steel Almirah',
      nameDevanagari: 'बजट 2 दरवाज़े स्टील अलमारी',
      description: 'किफ़ायती दो दरवाज़ों वाली स्टील अलमारी — किराए के मकान या एक्स्ट्रा स्टोरेज के लिए बढ़िया। हल्की लेकिन मज़बूत।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 170, widthCm: 90, depthCm: 50 },
      basePrice: 6500,
      negotiableDownTo: 5500,
      occasionTags: ['budget', 'replacement'],
      fallbackPhotoUrls: [
        'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=80',
        'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=800&q=80',
      ],
    },
  ];

  for (const sku of skus) {
    batch.set(
      shopRef.collection('inventory').doc(sku.skuId),
      {
        skuId: sku.skuId,
        shopId: SHOP_ID,
        name: sku.name,
        nameDevanagari: sku.nameDevanagari,
        description: sku.description,
        category: sku.category,
        material: sku.material,
        dimensions: sku.dimensions,
        basePrice: sku.basePrice,
        negotiableDownTo: sku.negotiableDownTo,
        inStock: true,
        isActive: true,
        occasionTags: sku.occasionTags,
        goldenHourPhotoIds: [],
        fallbackPhotoUrls: sku.fallbackPhotoUrls,
        voiceNoteIds: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true },
    );
  }
  console.log(`  + ${skus.length} inventory SKUs`);

  // ---- 4. Curated shortlists: 5 occasions (all steel/iron products) ----
  const shortlists = [
    {
      id: 'shaadi',
      occasion: 'shaadi',
      titleDevanagari: 'शादी के लिए',
      titleEnglish: 'For a wedding',
      heroImageUrl: 'https://images.unsplash.com/photo-1595428774223-ef52624120d2?w=800&q=80',
      skuIdsInOrder: [
        SKU_STEEL_PREMIUM_6DOOR,
        SKU_STEEL_3DOOR_MIRROR,
        SKU_STEEL_DRESSING,
        SKU_GODREJ_4DOOR,
      ],
    },
    {
      id: 'naya_ghar',
      occasion: 'naya_ghar',
      titleDevanagari: 'नए घर के लिए',
      titleEnglish: 'For the new home',
      heroImageUrl: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80',
      skuIdsInOrder: [
        SKU_GODREJ_4DOOR,
        SKU_STEEL_LOCKER,
        SKU_STEEL_3DOOR_MIRROR,
      ],
    },
    {
      id: 'beti_ka_ghar',
      occasion: 'beti_ka_ghar',
      titleDevanagari: 'बेटी का नया घर',
      titleEnglish: "For daughter's new home",
      heroImageUrl: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=800&q=80',
      skuIdsInOrder: [
        SKU_STEEL_PREMIUM_6DOOR,
        SKU_STEEL_3DOOR_MIRROR,
        SKU_STEEL_DRESSING,
      ],
    },
    {
      id: 'replacement',
      occasion: 'replacement',
      titleDevanagari: 'पुराना बदलना है',
      titleEnglish: 'Replace the old one',
      heroImageUrl: 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=80',
      skuIdsInOrder: [
        SKU_BUDGET_STEEL,
        SKU_GODREJ_4DOOR,
        SKU_STEEL_LOCKER,
      ],
    },
    {
      id: 'budget',
      occasion: 'budget',
      titleDevanagari: 'बजट में बढ़िया',
      titleEnglish: 'Best in budget',
      heroImageUrl: 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=80',
      skuIdsInOrder: [SKU_BUDGET_STEEL, SKU_STEEL_DRESSING, SKU_STEEL_LOCKER],
    },
  ];

  for (const sl of shortlists) {
    batch.set(
      shopRef.collection('curatedShortlists').doc(sl.id),
      {
        shortlistId: sl.id,
        shopId: SHOP_ID,
        occasion: sl.occasion,
        titleDevanagari: sl.titleDevanagari,
        titleEnglish: sl.titleEnglish,
        heroImageUrl: sl.heroImageUrl,
        skuIdsInOrder: sl.skuIdsInOrder,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true },
    );
  }
  console.log(`  + ${shortlists.length} curated shortlists`);

  // ---- Commit ----
  await batch.commit();
  console.log(`[seed:flagship] Done. ${SHOP_ID} seeded with 1 shop + 1 theme + ${skus.length} SKUs + ${shortlists.length} shortlists.`);
}

seedFlagship().catch((err) => {
  console.error('[seed:flagship] FAILED:', err);
  process.exit(1);
});
