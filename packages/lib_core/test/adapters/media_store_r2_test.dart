// =============================================================================
// MediaStoreR2 stub tests — PRD I6.6 AC #4.
//
// Asserts every method throws UnimplementedError so accidental production
// swap to the r2 strategy before the real implementation lands fails loudly.
// The stub's only purpose is to validate the interface contract against a
// second implementation at compile time. Its behavior is fail-fast.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/adapters/media_store.dart';
import 'package:lib_core/src/adapters/media_store_r2.dart';

void main() {
  group('MediaStoreR2 stub', () {
    const adapter = MediaStoreR2();

    test('uploadCatalogImage throws UnimplementedError', () {
      expect(
        () => adapter.uploadCatalogImage(
          bytes: <int>[1, 2, 3],
          shopId: 'sunil-trading-company',
          type: CatalogMediaType.skuPrimary,
        ),
        throwsUnimplementedError,
      );
    });

    test('getCatalogUrl throws UnimplementedError', () {
      expect(
        () => adapter.getCatalogUrl('anything'),
        throwsUnimplementedError,
      );
    });

    test('uploadVoiceNote throws UnimplementedError', () {
      expect(
        () => adapter.uploadVoiceNote(
          bytes: <int>[1, 2, 3],
          shopId: 'sunil-trading-company',
          voiceNoteId: 'vn_01HXYZ',
        ),
        throwsUnimplementedError,
      );
    });

    test('getVoiceNoteUrl throws UnimplementedError', () {
      expect(
        () => adapter.getVoiceNoteUrl(
          shopId: 'sunil-trading-company',
          voiceNoteId: 'vn_01HXYZ',
        ),
        throwsUnimplementedError,
      );
    });
  });
}
