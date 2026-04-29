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

import { seedShopDoc } from './lib/seed_shop_doc';

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
  seedShopDoc(batch, db, {
    shopId: SHOP_ID,
    brandName: 'Sunil Trading Company',
    brandNameDevanagari: 'सुनील ट्रेडिंग कंपनी',
    ownerUid: '', // no operator linked in customer-only context
    market: 'Harringtonganj, Ayodhya',
    activeFromDay: new Date('2003-01-01'),
  });
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
      name: 'Godrej Slimline 2-Door with Locker',
      nameDevanagari: 'गोदरेज स्लिमलाइन 2 दरवाज़े लॉकर वाली',
      description: 'गोदरेज की सबसे ज़्यादा बिकने वाली अलमारी — अंदर लॉकर, 4 शेल्फ़, पाउडर कोटेड फ़िनिश। 10 साल की वारंटी।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 195, widthCm: 90, depthCm: 50 },
      basePrice: 24190,
      negotiableDownTo: 21500,
      occasionTags: ['shaadi', 'naya_ghar', 'replacement'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/9/v/r/-original-imahh5k8nmfpvhgz.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/m/d/n/no-carbon-steel-900-29-6-30161803sd01741-blue-godrej-interio-450-original-imahh7qgttusfzwm.jpeg',
      ],
    },
    {
      skuId: SKU_STEEL_3DOOR_MIRROR,
      name: 'Godrej Interio Slimline 3-Door with Mirror',
      nameDevanagari: 'गोदरेज 3 दरवाज़े आईना वाली अलमारी',
      description: 'बीच में पूरे कद का आईना, दोनों तरफ़ शेल्फ़। बेटी की विदाई के लिए सबसे ज़्यादा बिकती है। सॉफ़्ट क्लोज़ हिंज।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 195, widthCm: 122, depthCm: 50 },
      basePrice: 29990,
      negotiableDownTo: 26500,
      occasionTags: ['shaadi', 'beti_ka_ghar'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/x/6/o/no-carbon-steel-900-78-30161803sd00983-red-godrej-interio-1985-original-imahfw7edzpcvyzh.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/d/0/m/no-carbon-steel-90-71-3-slim00782-green-godrej-interio-195-body-original-imahk7f7qatd2ejf.jpeg',
      ],
    },
    {
      skuId: SKU_STEEL_LOCKER,
      name: 'Godrej Storofix Heavy Duty Locker',
      nameDevanagari: 'गोदरेज हैवी ड्यूटी लॉकर अलमारी',
      description: 'डबल लॉकिंग सिस्टम, 18 गेज स्टील, ज़ेवर और ज़रूरी कागज़ात रखने के लिए। दीवार में फ़िक्स हो जाती है।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 91, widthCm: 48, depthCm: 46 },
      basePrice: 10990,
      negotiableDownTo: 9500,
      occasionTags: ['naya_ghar', 'replacement'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/y/k/5/no-carbon-steel-914-25-48-30161803sd01749-grey-godrej-interio-original-imahk7f7pgytksbr.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/9/v/r/-original-imahh5k8nmfpvhgz.jpeg',
      ],
    },
    {
      skuId: SKU_STEEL_PREMIUM_6DOOR,
      name: 'Godrej Interio Aceline 6-Door Premium',
      nameDevanagari: 'गोदरेज एसलाइन 6 दरवाज़े प्रीमियम',
      description: 'छह दरवाज़ों वाला बड़ा वॉर्डरोब — ऊपर तीन, नीचे तीन। शादी के सारे कपड़े और बिस्तर आ जाएँ। प्रीमियम मैट फ़िनिश।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 198, widthCm: 180, depthCm: 56 },
      basePrice: 35999,
      negotiableDownTo: 31000,
      occasionTags: ['shaadi', 'beti_ka_ghar'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/o/1/l/no-carbon-steel-900-66-slim00242f-brown-godrej-interio-1950-original-imahfw7gjsxmeahw.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/x/6/o/no-carbon-steel-900-78-30161803sd00983-red-godrej-interio-1985-original-imahfw7edzpcvyzh.jpeg',
      ],
    },
    {
      skuId: SKU_STEEL_DRESSING,
      name: 'Godrej StorEase 2-Door Compact',
      nameDevanagari: 'गोदरेज स्टोरईज़ 2 दरवाज़े कॉम्पैक्ट',
      description: 'छोटे कमरे के लिए कॉम्पैक्ट डिज़ाइन। 4 शेल्फ़, पाउडर कोटेड स्टील, लॉक के साथ। कलर ऑप्शन में उपलब्ध।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 145, widthCm: 90, depthCm: 46 },
      basePrice: 12790,
      negotiableDownTo: 11000,
      occasionTags: ['budget', 'naya_ghar'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/m/d/n/no-carbon-steel-900-29-6-30161803sd01741-blue-godrej-interio-450-original-imahh7qgttusfzwm.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/d/0/m/no-carbon-steel-90-71-3-slim00782-green-godrej-interio-195-body-original-imahk7f7qatd2ejf.jpeg',
      ],
    },
    {
      skuId: SKU_BUDGET_STEEL,
      name: 'Budget Single-Door Steel Almirah',
      nameDevanagari: 'बजट सिंगल दरवाज़ा स्टील अलमारी',
      description: 'किफ़ायती एक दरवाज़े वाली स्टील अलमारी — किराए के मकान या एक्स्ट्रा स्टोरेज के लिए बढ़िया। 5 शेल्फ़, लॉक के साथ।',
      category: 'steel_almirah',
      material: 'steel',
      dimensions: { heightCm: 170, widthCm: 60, depthCm: 46 },
      basePrice: 5841,
      negotiableDownTo: 5000,
      occasionTags: ['budget', 'replacement'],
      fallbackPhotoUrls: [
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/y/k/5/no-carbon-steel-914-25-48-30161803sd01749-grey-godrej-interio-original-imahk7f7pgytksbr.jpeg',
        'https://rukminim2.flixcart.com/image/832/832/xif0q/cupboard-almirah/o/1/l/no-carbon-steel-900-66-slim00242f-brown-godrej-interio-1950-original-imahfw7gjsxmeahw.jpeg',
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
