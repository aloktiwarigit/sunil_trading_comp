// =============================================================================
// MediaStoreCloudinaryFirebase tests — PRD I6.6 AC #6.
//
// Coverage:
//   - getCatalogUrl: pure-function URL builder (default transform + custom)
//   - uploadCatalogImage: kill-switch short-circuit + notYetWired Phase 1 state
//   - uploadVoiceNote: shop-scoped path validation + error normalization
//   - getVoiceNoteUrl: object-not-found mapping to MediaStoreErrorCode.notFound
//   - Validation: empty / path-traversal shopId + voiceNoteId rejection
// =============================================================================

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/media_store.dart';
import 'package:lib_core/src/adapters/media_store_cloudinary_firebase.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseStorage extends Mock implements FirebaseStorage {}

class _MockReference extends Mock implements Reference {}

class _FakeSettableMetadata extends Fake implements SettableMetadata {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSettableMetadata());
    // Uint8List is a final class and cannot be Fake-implemented. We register
    // a real empty Uint8List as the fallback — mocktail's `any()` matcher
    // uses the fallback only as a type hint, never as a value to match against.
    registerFallbackValue(Uint8List(0));
  });

  group('MediaStoreCloudinaryFirebase', () {
    late _MockFirebaseStorage mockStorage;
    late _MockReference mockRef;
    late MediaStoreCloudinaryFirebase adapter;

    setUp(() {
      mockStorage = _MockFirebaseStorage();
      mockRef = _MockReference();
      when(() => mockStorage.ref(any())).thenReturn(mockRef);

      adapter = MediaStoreCloudinaryFirebase(
        firebaseStorage: mockStorage,
        cloudinaryCloudName: 'yugma-test',
      );
    });

    // -------------------------------------------------------------------------
    // getCatalogUrl — pure function
    // -------------------------------------------------------------------------

    group('getCatalogUrl', () {
      test('builds URL with default transform when none is provided', () {
        final url = adapter.getCatalogUrl(
          'shops/sunil-trading-company/catalog/sku_primary/abc123',
        );

        expect(
          url,
          equals(
            'https://res.cloudinary.com/yugma-test/image/upload/'
            'q_auto,f_auto/'
            'shops/sunil-trading-company/catalog/sku_primary/abc123',
          ),
        );
      });

      test('uses custom transform when provided', () {
        final url = adapter.getCatalogUrl(
          'shops/sunil-trading-company/catalog/sku_primary/abc123',
          transform: 'q_auto,f_auto,w_400,h_300,c_fill',
        );

        expect(url, contains('q_auto,f_auto,w_400,h_300,c_fill'));
        expect(
          url,
          endsWith('shops/sunil-trading-company/catalog/sku_primary/abc123'),
        );
      });

      test('treats empty transform as default transform', () {
        final defaultUrl = adapter.getCatalogUrl('abc', transform: '');
        final explicitUrl = adapter.getCatalogUrl('abc');
        expect(defaultUrl, equals(explicitUrl));
      });
    });

    // -------------------------------------------------------------------------
    // uploadCatalogImage — Phase 1 notYetWired + kill-switch
    // -------------------------------------------------------------------------

    group('uploadCatalogImage', () {
      test(
        'throws MediaStoreErrorCode.notYetWired in Phase 1 default state',
        () async {
          await expectLater(
            adapter.uploadCatalogImage(
              bytes: <int>[1, 2, 3],
              shopId: 'sunil-trading-company',
              type: CatalogMediaType.skuPrimary,
            ),
            throwsA(
              isA<MediaStoreException>().having(
                (e) => e.code,
                'code',
                MediaStoreErrorCode.notYetWired,
              ),
            ),
          );
        },
      );

      test(
        'throws MediaStoreErrorCode.killSwitchActive when kill-switch probe returns true',
        () async {
          final killedAdapter = MediaStoreCloudinaryFirebase(
            firebaseStorage: mockStorage,
            cloudinaryCloudName: 'yugma-test',
            isUploadKillSwitchActive: () async => true,
          );

          await expectLater(
            killedAdapter.uploadCatalogImage(
              bytes: <int>[1, 2, 3],
              shopId: 'sunil-trading-company',
              type: CatalogMediaType.skuPrimary,
            ),
            throwsA(
              isA<MediaStoreException>().having(
                (e) => e.code,
                'code',
                MediaStoreErrorCode.killSwitchActive,
              ),
            ),
          );
        },
      );

      test(
        'kill-switch check precedes notYetWired — kill-switch active wins',
        () async {
          // This ordering matters: if the kill-switch is active, we must
          // refuse BEFORE hitting the notYetWired path, because an active
          // kill-switch means the operator has explicitly blocked uploads
          // for cost reasons. The notYetWired message would be misleading.
          final killedAdapter = MediaStoreCloudinaryFirebase(
            firebaseStorage: mockStorage,
            cloudinaryCloudName: 'yugma-test',
            isUploadKillSwitchActive: () async => true,
          );

          try {
            await killedAdapter.uploadCatalogImage(
              bytes: <int>[1, 2, 3],
              shopId: 'sunil-trading-company',
              type: CatalogMediaType.skuPrimary,
            );
            fail('Expected MediaStoreException');
          } on MediaStoreException catch (e) {
            expect(e.code, MediaStoreErrorCode.killSwitchActive);
          }
        },
      );
    });

    // -------------------------------------------------------------------------
    // uploadVoiceNote — shop-scoped path + success + error mapping
    // -------------------------------------------------------------------------

    group('uploadVoiceNote', () {
      test(
        'uses canonical shop-scoped Cloud Storage path when building the ref',
        () async {
          // We don't try to mock UploadTask's Future-subtype behavior
          // directly — it's fragile. Instead, throw a known FirebaseException
          // from putData, catch the normalized MediaStoreException, and then
          // verify the ref was built with the canonical shop-scoped path.
          // This covers both the path-construction contract (PRD I6.6 AC #6)
          // and the error-normalization contract without fighting mocktail.
          when(() => mockRef.putData(any(), any())).thenThrow(
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'retry-limit-exceeded',
              message: 'Upload failed after retries',
            ),
          );

          try {
            await adapter.uploadVoiceNote(
              bytes: <int>[1, 2, 3, 4],
              shopId: 'sunil-trading-company',
              voiceNoteId: 'vn_01HXYZ',
            );
            fail('Expected MediaStoreException');
          } on MediaStoreException catch (e) {
            // retry-limit-exceeded maps to network per the error table
            expect(e.code, MediaStoreErrorCode.network);
          }

          // Path contract verification — the most important assertion.
          verify(
            () => mockStorage.ref(
              'shops/sunil-trading-company/voice_notes/vn_01HXYZ.m4a',
            ),
          ).called(1);
        },
      );

      test('rejects empty shopId with unauthorized error', () async {
        await expectLater(
          adapter.uploadVoiceNote(
            bytes: <int>[1, 2, 3],
            shopId: '',
            voiceNoteId: 'vn_01HXYZ',
          ),
          throwsA(
            isA<MediaStoreException>().having(
              (e) => e.code,
              'code',
              MediaStoreErrorCode.unauthorized,
            ),
          ),
        );
      });

      test('rejects shopId containing path-traversal characters', () async {
        await expectLater(
          adapter.uploadVoiceNote(
            bytes: <int>[1, 2, 3],
            shopId: '../other-shop',
            voiceNoteId: 'vn_01HXYZ',
          ),
          throwsA(
            isA<MediaStoreException>().having(
              (e) => e.code,
              'code',
              MediaStoreErrorCode.unauthorized,
            ),
          ),
        );
      });

      test('rejects shopId containing forward slash', () async {
        await expectLater(
          adapter.uploadVoiceNote(
            bytes: <int>[1, 2, 3],
            shopId: 'sunil/evil',
            voiceNoteId: 'vn_01HXYZ',
          ),
          throwsA(
            isA<MediaStoreException>().having(
              (e) => e.code,
              'code',
              MediaStoreErrorCode.unauthorized,
            ),
          ),
        );
      });

      test('rejects empty voiceNoteId', () async {
        await expectLater(
          adapter.uploadVoiceNote(
            bytes: <int>[1, 2, 3],
            shopId: 'sunil-trading-company',
            voiceNoteId: '',
          ),
          throwsA(
            isA<MediaStoreException>().having(
              (e) => e.code,
              'code',
              MediaStoreErrorCode.uploadFailed,
            ),
          ),
        );
      });

      test('rejects voiceNoteId with path-traversal', () async {
        await expectLater(
          adapter.uploadVoiceNote(
            bytes: <int>[1, 2, 3],
            shopId: 'sunil-trading-company',
            voiceNoteId: '../../../etc/passwd',
          ),
          throwsA(
            isA<MediaStoreException>().having(
              (e) => e.code,
              'code',
              MediaStoreErrorCode.uploadFailed,
            ),
          ),
        );
      });

      test(
        'maps FirebaseException(object-not-found) to notFound on getVoiceNoteUrl',
        () async {
          when(() => mockRef.getDownloadURL()).thenThrow(
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'object-not-found',
              message: 'No object at this path',
            ),
          );

          await expectLater(
            adapter.getVoiceNoteUrl(
              shopId: 'sunil-trading-company',
              voiceNoteId: 'vn_01HXYZ',
            ),
            throwsA(
              isA<MediaStoreException>().having(
                (e) => e.code,
                'code',
                MediaStoreErrorCode.notFound,
              ),
            ),
          );
        },
      );

      test(
        'maps FirebaseException(unauthorized) to unauthorized on getVoiceNoteUrl',
        () async {
          when(() => mockRef.getDownloadURL()).thenThrow(
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'unauthorized',
              message: 'Not allowed',
            ),
          );

          await expectLater(
            adapter.getVoiceNoteUrl(
              shopId: 'sunil-trading-company',
              voiceNoteId: 'vn_01HXYZ',
            ),
            throwsA(
              isA<MediaStoreException>().having(
                (e) => e.code,
                'code',
                MediaStoreErrorCode.unauthorized,
              ),
            ),
          );
        },
      );

      test(
        'maps FirebaseException(quota-exceeded) to quotaExhausted',
        () async {
          when(() => mockRef.getDownloadURL()).thenThrow(
            FirebaseException(
              plugin: 'firebase_storage',
              code: 'quota-exceeded',
              message: 'Storage quota reached',
            ),
          );

          await expectLater(
            adapter.getVoiceNoteUrl(
              shopId: 'sunil-trading-company',
              voiceNoteId: 'vn_01HXYZ',
            ),
            throwsA(
              isA<MediaStoreException>().having(
                (e) => e.code,
                'code',
                MediaStoreErrorCode.quotaExhausted,
              ),
            ),
          );
        },
      );

      test('returns URL from Firebase Storage on success', () async {
        when(() => mockRef.getDownloadURL()).thenAnswer(
          (_) async => 'https://firebasestorage.googleapis.com/abc/voice.m4a',
        );

        final url = await adapter.getVoiceNoteUrl(
          shopId: 'sunil-trading-company',
          voiceNoteId: 'vn_01HXYZ',
        );

        expect(url,
            equals('https://firebasestorage.googleapis.com/abc/voice.m4a'));
        verify(
          () => mockStorage.ref(
            'shops/sunil-trading-company/voice_notes/vn_01HXYZ.m4a',
          ),
        ).called(1);
      });
    });
  });
}
