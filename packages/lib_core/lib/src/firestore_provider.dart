// =============================================================================
// firestoreProvider + projectRepoProvider — Phase 4 G3 dependency-injection.
//
// `firestoreProvider` returns FirebaseFirestore.instance by default. Tests
// override it with a FakeFirebaseFirestore via ProviderScope.overrides so
// the screen's stream providers + the typed-patch writes all see the same
// fake.
//
// `projectRepoProvider` constructs a ProjectRepo from `firestoreProvider`
// and `shopIdProviderProvider`. Replaces inline
// `ProjectRepo(firestore: FirebaseFirestore.instance, shopIdProvider: ...)`
// constructions on the screen.
//
// Phase 4 scope: only consumed by `apps/shopkeeper_app/lib/features/orders/
// project_detail_screen.dart`. The 20 other shopkeeper_app callsites that
// read FirebaseFirestore.instance directly are NOT touched in Phase 4 —
// they migrate when their next refactor lands.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories/project_repo.dart';
import 'shop_id_provider.dart';

/// Riverpod provider for the active FirebaseFirestore instance.
///
/// Production: returns `FirebaseFirestore.instance`.
/// Tests: override with `firestoreProvider.overrideWithValue(fakeFirestore)`.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Riverpod provider for a ProjectRepo wired to the active firestore +
/// shop-id providers.
///
/// Tests: override `firestoreProvider` to a FakeFirebaseFirestore and
/// `shopIdProviderProvider` to a `ShopIdProvider('test-shop')`. The repo
/// constructed by this provider then reads/writes through the fake.
final projectRepoProvider = Provider<ProjectRepo>((ref) {
  return ProjectRepo(
    firestore: ref.watch(firestoreProvider),
    shopIdProvider: ref.watch(shopIdProviderProvider),
  );
});
