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
const SKU_SHEESHAM_WARDROBE = 'sku-sheesham-wardrobe';
const SKU_MODULAR_SLIDING = 'sku-modular-sliding';
const SKU_TEAK_WARDROBE = 'sku-teak-wardrobe';
const SKU_DRESSING_TABLE = 'sku-dressing-table';
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
      shopkeeperFaceUrl: '',
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

  // ---- 3. Inventory: 6 SKUs ----
  const skus = [
    {
      skuId: SKU_GODREJ_4DOOR,
      name: 'Godrej-style 4-door Steel Almirah',
      nameDevanagari: 'गोदरेज स्टाइल 4 दरवाज़े स्टील अलमारी',
      description: 'चार दरवाज़ों वाली मज़बूत स्टील अलमारी, पूरे परिवार के लिए',
      category: 'steelAlmirah',
      material: 'steel',
      dimensions: { heightCm: 182, widthCm: 122, depthCm: 56 },
      basePrice: 18500,
      negotiableDownTo: 16000,
      occasionTags: ['shaadi', 'naya_ghar', 'replacement'],
    },
    {
      skuId: SKU_SHEESHAM_WARDROBE,
      name: 'Sheesham 3-door Wardrobe',
      nameDevanagari: 'शीशम 3 दरवाज़े अलमारी',
      description: 'शीशम की लकड़ी, तीन दरवाज़े, आईना अंदर',
      category: 'woodenWardrobe',
      material: 'woodSheesham',
      dimensions: { heightCm: 198, widthCm: 152, depthCm: 60 },
      basePrice: 35000,
      negotiableDownTo: 30000,
      occasionTags: ['shaadi', 'dahej', 'ladies'],
    },
    {
      skuId: SKU_MODULAR_SLIDING,
      name: 'Modular Sliding Wardrobe',
      nameDevanagari: 'मॉड्यूलर स्लाइडिंग अलमारी',
      description: 'स्लाइडिंग दरवाज़े, लैमिनेट फ़िनिश, आधुनिक डिज़ाइन',
      category: 'modular',
      material: 'plyLaminate',
      dimensions: { heightCm: 210, widthCm: 180, depthCm: 62 },
      basePrice: 22000,
      negotiableDownTo: 19000,
      occasionTags: ['naya_ghar', 'replacement', 'budget', 'ladies'],
    },
    {
      skuId: SKU_TEAK_WARDROBE,
      name: 'Teak 3-door Premium Wardrobe',
      nameDevanagari: 'सागौन 3 दरवाज़े प्रीमियम अलमारी',
      description: 'सागौन की लकड़ी, हाथ की नक्काशी, पीढ़ियों तक चले',
      category: 'woodenWardrobe',
      material: 'woodTeak',
      dimensions: { heightCm: 200, widthCm: 160, depthCm: 58 },
      basePrice: 45000,
      negotiableDownTo: 40000,
      occasionTags: ['shaadi', 'dahej'],
    },
    {
      skuId: SKU_DRESSING_TABLE,
      name: 'Sheesham Dressing Table with Mirror',
      nameDevanagari: 'शीशम ड्रेसिंग टेबल आईने वाली',
      description: 'शीशम की लकड़ी, बड़ा आईना, तीन दराज़',
      category: 'dressing',
      material: 'woodSheesham',
      dimensions: { heightCm: 150, widthCm: 90, depthCm: 45 },
      basePrice: 12000,
      negotiableDownTo: 10000,
      occasionTags: ['shaadi', 'dahej', 'ladies'],
    },
    {
      skuId: SKU_BUDGET_STEEL,
      name: 'Budget 2-door Steel Almirah',
      nameDevanagari: 'बजट 2 दरवाज़े स्टील अलमारी',
      description: 'दो दरवाज़ों वाली किफ़ायती स्टील अलमारी',
      category: 'steelAlmirah',
      material: 'steel',
      dimensions: { heightCm: 170, widthCm: 90, depthCm: 50 },
      basePrice: 8500,
      negotiableDownTo: 7500,
      occasionTags: ['budget', 'replacement'],
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
        fallbackPhotoUrls: [],
        voiceNoteIds: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      },
      { merge: true },
    );
  }
  console.log(`  + ${skus.length} inventory SKUs`);

  // ---- 4. Curated shortlists: 6 occasions ----
  const shortlists = [
    {
      id: 'shaadi',
      occasion: 'shaadi',
      titleDevanagari: 'शादी के लिए',
      titleEnglish: 'For a wedding',
      skuIdsInOrder: [
        SKU_SHEESHAM_WARDROBE,
        SKU_TEAK_WARDROBE,
        SKU_DRESSING_TABLE,
        SKU_GODREJ_4DOOR,
      ],
    },
    {
      id: 'naya_ghar',
      occasion: 'nayaGhar',
      titleDevanagari: 'नए घर के लिए',
      titleEnglish: 'For the new home',
      skuIdsInOrder: [
        SKU_MODULAR_SLIDING,
        SKU_GODREJ_4DOOR,
        SKU_SHEESHAM_WARDROBE,
      ],
    },
    {
      id: 'dahej',
      occasion: 'dahej',
      titleDevanagari: 'दहेज के लिए',
      titleEnglish: 'For dahej',
      skuIdsInOrder: [
        SKU_TEAK_WARDROBE,
        SKU_SHEESHAM_WARDROBE,
        SKU_DRESSING_TABLE,
      ],
    },
    {
      id: 'replacement',
      occasion: 'replacement',
      titleDevanagari: 'पुराना बदलने के लिए',
      titleEnglish: 'To replace the old one',
      skuIdsInOrder: [
        SKU_BUDGET_STEEL,
        SKU_GODREJ_4DOOR,
        SKU_MODULAR_SLIDING,
      ],
    },
    {
      id: 'budget',
      occasion: 'budget',
      titleDevanagari: 'बजट के अनुसार',
      titleEnglish: 'Budget picks',
      skuIdsInOrder: [SKU_BUDGET_STEEL, SKU_MODULAR_SLIDING],
    },
    {
      id: 'ladies',
      occasion: 'ladies',
      titleDevanagari: 'लेडीज़ के लिए',
      titleEnglish: 'For ladies',
      skuIdsInOrder: [
        SKU_DRESSING_TABLE,
        SKU_MODULAR_SLIDING,
        SKU_SHEESHAM_WARDROBE,
      ],
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
