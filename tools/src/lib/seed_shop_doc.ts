// =============================================================================
// seed_shop_doc.ts — Shared helper for writing a /shops/{shopId} document.
//
// Both seed_flagship.ts and seed_synthetic_shop_0.ts write the same top-level
// shop document shape. This helper owns that canonical shape so changes to the
// SAD §5 Shop schema only need to be made in one place.
//
// Usage:
//   seedShopDoc(batch, db, { shopId, brandName, brandNameDevanagari,
//                            ownerUid, market, activeFromDay });
//   // then call batch.commit() after your own additional writes
// =============================================================================

import type { Firestore, WriteBatch } from 'firebase-admin/firestore';

export interface ShopDocParams {
  shopId: string;
  brandName: string;
  brandNameDevanagari: string;
  ownerUid: string;
  market: string;
  activeFromDay: Date;
}

export function seedShopDoc(
  batch: WriteBatch,
  db: Firestore,
  params: ShopDocParams,
): void {
  const shopRef = db.collection('shops').doc(params.shopId);
  batch.set(
    shopRef,
    {
      shopId: params.shopId,
      brandName: params.brandName,
      brandNameDevanagari: params.brandNameDevanagari,
      ownerUid: params.ownerUid,
      market: params.market,
      createdAt: new Date(),
      activeFromDay: params.activeFromDay,
      shopLifecycle: 'active',
      shopLifecycleChangedAt: new Date(),
      shopLifecycleReason: null,
      dpdpRetentionUntil: null,
    },
    { merge: true },
  );
}
