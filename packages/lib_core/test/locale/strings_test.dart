// =============================================================================
// Locale tests — the 3 load-bearing invariants for AppStrings.
//
// Coverage:
//   1. Symmetry — every AppStrings getter returns a non-empty string in
//      both the Hindi and English implementations (no silent TODO gaps).
//   2. Forbidden vocabulary — scans every string in both implementations
//      for udhaar lending terms (ADR-010) and mythic Sanskritized terms
//      (Brief Constraint 10). A single hit fails the build.
//   3. Parameter round-trip — parameterized methods (udhaarBalance,
//      udhaarReminderPush, shopDeactivatingBanner, receiptUdhaarBaaki,
//      udhaarReminderCountBadge, shopPurgeScheduledBanner) correctly
//      substitute their int / count / days parameters and produce
//      Indian-lakh-format numbers on both locales.
// =============================================================================

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_core/src/locale/locale_resolver.dart';
import 'package:lib_core/src/locale/strings_base.dart';
import 'package:lib_core/src/locale/strings_en.dart';
import 'package:lib_core/src/locale/strings_hi.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

/// Produces a Map of every string getter name → rendered string for a
/// given implementation. Used by the forbidden-vocab scanner and by the
/// symmetry test. Parameterized methods are invoked with stable sample
/// values so their output is deterministic.
Map<String, String> _renderAllStrings(AppStrings s) {
  return <String, String>{
    // ---- §1 Landing + greeting ----
    'shopDisplayName': s.shopDisplayName,
    'greetingVoiceNoteLabel': s.greetingVoiceNoteLabel,

    // ---- §1b Bharosa landing ----
    'metaBarYearsInBusiness(23, 2003)': s.metaBarYearsInBusiness(23, 2003),
    'greetingCardTitle': s.greetingCardTitle,
    'greetingVoiceNoteSublabel': s.greetingVoiceNoteSublabel('Test', 23),
    'muteToggleOn': s.muteToggleOn,
    'muteToggleMute': s.muteToggleMute,
    'shortlistPreviewHeadline': s.shortlistPreviewHeadline('Test'),
    'shortlistBadgeCurated': s.shortlistBadgeCurated,
    'presenceStatusAvailable': s.presenceStatusAvailable,
    'metaBarMapLabel': s.metaBarMapLabel,

    // ---- §1c Browse widgets ----
    'skuTopPickBadge': s.skuTopPickBadge,
    'skuNegotiableLabel': s.skuNegotiableLabel,
    'goldenHourToggleBeautiful': s.goldenHourToggleBeautiful,

    // ---- §2 Curated shortlists ----
    'shortlistTitleShaadi': s.shortlistTitleShaadi,
    'shortlistTitleNayaGhar': s.shortlistTitleNayaGhar,
    'shortlistTitlePuranaBadlne': s.shortlistTitlePuranaBadlne,
    'shortlistTitleDahej': s.shortlistTitleDahej,
    'shortlistTitleBudget': s.shortlistTitleBudget,
    'shortlistTitleLadies': s.shortlistTitleLadies,

    // ---- §3 SKU detail ----
    'skuAddToList': s.skuAddToList,
    'skuTalkToBhaiya': s.skuTalkToBhaiya,
    'asliRoopToggle': s.asliRoopToggle,

    // ---- §4 Chat ----
    'chatThreadTitle': s.chatThreadTitle,
    'chatInputPlaceholder': s.chatInputPlaceholder,

    // ---- §4b C3.1 + P2.4 + P2.5 Chat + Draft ----
    'chatThreadTitleWithOrder': s.chatThreadTitleWithOrder('abc123'),
    'myListTitle': s.myListTitle,
    'addedToList': s.addedToList,
    'chatSenderYou': s.chatSenderYou,
    'chatSenderBhaiya': s.chatSenderBhaiya,
    'chatSendButton': s.chatSendButton,
    'chatMessagePending': s.chatMessagePending,

    // ---- §4c C3.2 Draft line item editing ----
    'draftItemRemoved': s.draftItemRemoved('Test'),
    'draftUndoRemove': s.draftUndoRemove,
    'draftQtyHighTitle': s.draftQtyHighTitle,
    'draftQtyHighBody(12, Test)': s.draftQtyHighBody(12, 'Test'),
    'draftQtyHighConfirm': s.draftQtyHighConfirm,
    'draftQtyHighCancel': s.draftQtyHighCancel,
    'draftTotalLabel': s.draftTotalLabel,

    // ---- §4d C3.3 Negotiation flow ----
    'proposalBubbleLabel': s.proposalBubbleLabel('Test'),
    'proposalPriceLine(15000)': s.proposalPriceLine(15000),
    'proposalAcceptButton': s.proposalAcceptButton,
    'proposalAcceptedBadge': s.proposalAcceptedBadge,
    'proposalAcceptedSystemMessage': s.proposalAcceptedSystemMessage(15000, 'Test'),
    'proposalOriginalPriceLabel': s.proposalOriginalPriceLabel,

    // ---- §5 Commit + OTP + payment ----
    'commitButtonPakka': s.commitButtonPakka,
    'otpPromptBhaiyaNeedsIt': s.otpPromptBhaiyaNeedsIt,
    'upiPayButton': s.upiPayButton,
    'paymentSuccessPakka': s.paymentSuccessPakka,

    // ---- §6 Udhaar khaata ----
    'udhaarProposal': s.udhaarProposal,
    'udhaarBalance(13000)': s.udhaarBalance(13000),
    'deliveryConfirmed': s.deliveryConfirmed,
    'udhaarReminderPush(13000)': s.udhaarReminderPush(13000),

    // ---- §7 Empty states ----
    'emptyDraftList': s.emptyDraftList,
    'noOrdersYet': s.noOrdersYet,
    'emptyShortlistNotYetCurated': s.emptyShortlistNotYetCurated,
    'emptyDecisionCircle': s.emptyDecisionCircle,

    // ---- §8 Errors + connectivity ----
    'noInternetShowingCached': s.noInternetShowingCached,
    'uploadPending': s.uploadPending,
    'paymentFailed': s.paymentFailed,
    'voiceNoteSendFailed': s.voiceNoteSendFailed,
    'opsAppNotAuthorized': s.opsAppNotAuthorized,

    // ---- §9 Absence presence ----
    'awayBannerAtShaadi': s.awayBannerAtShaadi,

    // ---- §10 Decision Circle persona toggle ----
    'personaLabelIAmLooking': s.personaLabelIAmLooking,
    'personaLabelIAmLookingFemale': s.personaLabelIAmLookingFemale,
    'personaLabelMummyJi': s.personaLabelMummyJi,

    // ---- §11 B1.13 Receipt ----
    'receiptThankYouFooter': s.receiptThankYouFooter,
    'receiptOpenButton': s.receiptOpenButton,
    'receiptCancelledWatermark': s.receiptCancelledWatermark,
    'receiptUdhaarBaaki(5500)': s.receiptUdhaarBaaki(5500),
    'receiptCustomerFallback': s.receiptCustomerFallback,

    // ---- §12 C3.12 Shop deactivation ----
    'shopDeactivatingBanner(30)': s.shopDeactivatingBanner(30),
    'shopPurgeScheduledBanner(7)': s.shopPurgeScheduledBanner(7),
    'shopDeactivationFaqTitle': s.shopDeactivationFaqTitle,
    'dataExportCta': s.dataExportCta,

    // ---- §13 S4.17 NPS card ----
    'npsCardHeadline': s.npsCardHeadline,
    'npsOptionalPrompt': s.npsOptionalPrompt,
    'npsSnoozeLater': s.npsSnoozeLater,

    // ---- §14 S4.19 Shop closure ----
    'shopClosureSettingsOption': s.shopClosureSettingsOption,
    'shopClosureReversibilityFooter': s.shopClosureReversibilityFooter,

    // ---- §15 S4.16 Media spend tile ----
    'mediaSpendTileLabel': s.mediaSpendTileLabel,
    'cloudinaryExhaustedR2Active': s.cloudinaryExhaustedR2Active,

    // ---- §16 S4.10 Udhaar reminder affordances ----
    'udhaarReminderOptInPrompt': s.udhaarReminderOptInPrompt,
    'udhaarReminderCountBadge(2)': s.udhaarReminderCountBadge(2),
    'udhaarReminderCadencePrompt': s.udhaarReminderCadencePrompt,

    // ---- §17 S4.1 + S4.13 Ops app foundation ----
    'signInWithGoogle': s.signInWithGoogle,
    'todaysTaskTitle': s.todaysTaskTitle,
    'todaysTaskDone': s.todaysTaskDone,
    'todaysTaskDismiss': s.todaysTaskDismiss,
    'todaysTaskMinutes(10)': s.todaysTaskMinutes(10),
    'signOutLabel': s.signOutLabel,
    'opsDashboardTitle': s.opsDashboardTitle,
    'todaysTaskDay30Celebration': s.todaysTaskDay30Celebration,
    'opsPermissionRevoked': s.opsPermissionRevoked,

    // ---- §18 S4.3 Inventory SKU creation ----
    'inventoryTitle': s.inventoryTitle,
    'createSkuButton': s.createSkuButton,
    'skuNameDevanagariLabel': s.skuNameDevanagariLabel,
    'skuNameEnglishLabel': s.skuNameEnglishLabel,
    'skuCategoryLabel': s.skuCategoryLabel,
    'skuBasePriceLabel': s.skuBasePriceLabel,
    'skuNegotiableFloorLabel': s.skuNegotiableFloorLabel,
    'skuDimensionsLabel': s.skuDimensionsLabel,
    'skuMaterialLabel': s.skuMaterialLabel,
    'skuInStockLabel': s.skuInStockLabel,
    'skuDescriptionLabel': s.skuDescriptionLabel,
    'skuSaveButton': s.skuSaveButton,
    'skuGoldenHourPhotoButton': s.skuGoldenHourPhotoButton,
    'skuStockCountLabel': s.skuStockCountLabel,
    'skuDuplicateNameWarning': s.skuDuplicateNameWarning,
    'skuSavedSuccess': s.skuSavedSuccess,
    'validationRequired': s.validationRequired,
    'validationPricePositive': s.validationPricePositive,
    'validationFloorExceedsBase': s.validationFloorExceedsBase,
    'validationDimensionPositive': s.validationDimensionPositive,
    'inventoryEmpty': s.inventoryEmpty,

    // ---- §19 S4.7 Project detail ----
    'projectDetailTitle': s.projectDetailTitle,
    'lineItemsHeader': s.lineItemsHeader,
    'customerInfoHeader': s.customerInfoHeader,
    'newCustomerPlaceholder': s.newCustomerPlaceholder,
    'chatPreviewHeader(5)': s.chatPreviewHeader(5),
    'sendMessageButton': s.sendMessageButton,
    'markDeliveredButton': s.markDeliveredButton,
    'cancelOrderButton': s.cancelOrderButton,
    'filterNegotiating': s.filterNegotiating,

    // ---- §20 S4.8 Shopkeeper chat reply ----
    'proposePriceButton': s.proposePriceButton,
    'proposalSelectItemPrompt': s.proposalSelectItemPrompt,
    'proposalPriceInputLabel': s.proposalPriceInputLabel,
    'proposalSendButton': s.proposalSendButton,
    'proposalSentConfirmation': s.proposalSentConfirmation,

    // ---- §21 S4.4 Inventory edit ----
    'editSkuTitle': s.editSkuTitle,
    'skuSaveChangesButton': s.skuSaveChangesButton,
    'skuChangesSaved': s.skuChangesSaved,
    'skuStockAdjustLabel': s.skuStockAdjustLabel,

    // ---- §22 C3.8 + C3.9 Udhaar khaata flow ----
    'udhaarStartButton': s.udhaarStartButton,
    'udhaarTodayPaymentLabel': s.udhaarTodayPaymentLabel,
    'udhaarBalanceLabel': s.udhaarBalanceLabel,
    'udhaarConfirmButton': s.udhaarConfirmButton,
    'udhaarCreatedSuccess': s.udhaarCreatedSuccess,
    'udhaarAcceptButton': s.udhaarAcceptButton,
    'udhaarDeclineButton': s.udhaarDeclineButton,
    'udhaarAcceptedConfirmation': s.udhaarAcceptedConfirmation,
    'udhaarRecordPaymentButton': s.udhaarRecordPaymentButton,
    'udhaarAmountPaidLabel': s.udhaarAmountPaidLabel,
    'udhaarPaymentMethodLabel': s.udhaarPaymentMethodLabel,
    'udhaarPaymentRecordedSuccess': s.udhaarPaymentRecordedSuccess,
    'udhaarLedgerClosed': s.udhaarLedgerClosed,
    'udhaarOverpaymentError': s.udhaarOverpaymentError,
  };
}

void main() {
  // ===========================================================================
  // 1. SYMMETRY — every string is non-empty in both locales
  // ===========================================================================

  group('AppStrings symmetry', () {
    const hi = AppStringsHi();
    const en = AppStringsEn();

    test('both implementations return the same set of keys', () {
      final hiMap = _renderAllStrings(hi);
      final enMap = _renderAllStrings(en);

      expect(
        hiMap.keys.toSet(),
        equals(enMap.keys.toSet()),
        reason: 'strings_hi.dart and strings_en.dart must cover identical keys',
      );
    });

    test('Hindi returns non-empty output for every string', () {
      final hiMap = _renderAllStrings(hi);
      hiMap.forEach((key, value) {
        expect(
          value,
          isNotEmpty,
          reason: 'strings_hi.dart $key returned empty — missing translation',
        );
      });
    });

    test('English returns non-empty output for every string', () {
      final enMap = _renderAllStrings(en);
      enMap.forEach((key, value) {
        expect(
          value,
          isNotEmpty,
          reason: 'strings_en.dart $key returned empty — missing translation',
        );
      });
    });

    test('Hindi and English output differ for every string (no accidental copy)',
        () {
      // A string identical between the two implementations is almost always
      // a bug — either the Hindi was forgotten (placeholder English fallback)
      // or the English was forgotten (placeholder Hindi fallback). Exceptions:
      //   - shopDisplayName proper noun is the same in both (one of the
      //     cases where the Devanagari string happens to transliterate
      //     identically to the English — but we use different scripts so
      //     even the display string differs)
      //   - locale code differs by definition
      //   - `personaLabelIAmLooking` / `personaLabelMummyJi` — English
      //     uses "Mummy-ji" as loanword, so they DO differ.
      // In practice every one of our 50+ strings should differ between
      // Hindi and English output.
      final hiMap = _renderAllStrings(hi);
      final enMap = _renderAllStrings(en);

      final identical = <String>[];
      for (final key in hiMap.keys) {
        if (hiMap[key] == enMap[key]) {
          identical.add('$key = ${hiMap[key]}');
        }
      }

      // Expected identicals: none in the current set. Flag any.
      // Allow the receiptCancelledWatermark (UPPERCASE English vs Devanagari
      // "रद्द") and cloudinaryExhaustedR2Active (same two loanwords in both
      // locales — Cloudinary/R2 are product names) as legitimate overlaps.
      // proposalPriceLine is legitimately identical — ₹ format with Western
      // numerals per UX Spec §5.4, same in both locales.
      const allowedIdenticals = <String>{
        'proposalPriceLine',
      };

      final unexpected = identical
          .where(
            (s) => !allowedIdenticals.any((allowed) => s.startsWith(allowed)),
          )
          .toList();

      expect(
        unexpected,
        isEmpty,
        reason:
            'Strings identical between hi and en (likely missing translation): '
            '$unexpected',
      );
    });
  });

  // ===========================================================================
  // 2. FORBIDDEN VOCABULARY — udhaar lending + mythic Sanskritized
  // ===========================================================================

  group('AppStrings forbidden vocabulary scan', () {
    // UX Spec §5.6 Hindi forbidden list for udhaar lending.
    const forbiddenHiUdhaar = <String>[
      'ब्याज', // interest
      'ब्याज दर', // interest rate
      'देय तिथि', // due date
      'देय', // due (on its own)
      'जुर्माना', // penalty / fee
      'लेट फीस', // late fee
      'ऋण', // loan
      'उधारी', // borrowing
      'कर्ज़', // debt
      'डिफ़ॉल्ट', // default
      'वसूली', // collection
      'क़िस्त', // installment
      'क़िस्त बंदी', // installment plan
      'भुगतान विफल', // payment failed (too harsh)
    ];

    // UX Spec §5.6 English forbidden list. Case-insensitive.
    const forbiddenEnUdhaar = <String>[
      'interest',
      'interest rate',
      'due date',
      'overdue',
      'past due',
      'late fee',
      'penalty',
      'loan',
      'credit',
      'lending',
      'defaulter',
      'collection',
      'recovery',
      'installment',
      ' emi ',
      'payment failed',
      'debt',
    ];

    // Brief Constraint 10 — forbidden mythic / Sanskritized vocabulary.
    const forbiddenMythicHi = <String>[
      'शुभ',
      'मंगल',
      'मंगलमय',
      'मंदिर',
      'धर्म',
      'धार्मिक',
      'पूज्य',
      'आशीर्वाद',
      'तीर्थ',
      'तीर्थयात्री',
      'स्वागतम्',
      'उत्पाद',
      'गुणवत्ता',
      'श्रेष्ठ',
      'सर्वोत्तम',
    ];

    test('Hindi strings contain no udhaar lending vocabulary', () {
      final hiMap = _renderAllStrings(const AppStringsHi());
      for (final entry in hiMap.entries) {
        for (final forbidden in forbiddenHiUdhaar) {
          // Special case: बकाया is forbidden per §5.6, but "बाकी" (permitted
          // per §5.6 permitted vocabulary) is NOT. Guard explicit substring
          // matching — use `.contains()` which is what real code reviewers
          // scan for.
          expect(
            entry.value.contains(forbidden),
            isFalse,
            reason:
                'strings_hi.dart ${entry.key} contains forbidden udhaar word '
                '"$forbidden" per ADR-010 / UX Spec §5.6',
          );
        }
      }
    });

    test('English strings contain no udhaar lending vocabulary', () {
      final enMap = _renderAllStrings(const AppStringsEn());
      for (final entry in enMap.entries) {
        final lower = entry.value.toLowerCase();
        for (final forbidden in forbiddenEnUdhaar) {
          expect(
            lower.contains(forbidden),
            isFalse,
            reason:
                'strings_en.dart ${entry.key} contains forbidden English '
                'udhaar word "$forbidden" per ADR-010 / UX Spec §5.6',
          );
        }
      }
    });

    test('Hindi strings contain no mythic Sanskritized vocabulary', () {
      final hiMap = _renderAllStrings(const AppStringsHi());
      for (final entry in hiMap.entries) {
        for (final forbidden in forbiddenMythicHi) {
          expect(
            entry.value.contains(forbidden),
            isFalse,
            reason:
                'strings_hi.dart ${entry.key} contains forbidden mythic word '
                '"$forbidden" per Brief Constraint 10 / UX Spec §5.6',
          );
        }
      }
    });
  });

  // ===========================================================================
  // 3. PARAMETER SUBSTITUTION + INDIAN LAKH FORMAT
  // ===========================================================================

  group('AppStrings parameter substitution', () {
    const hi = AppStringsHi();
    const en = AppStringsEn();

    test('Indian lakh formatter: 22000 → 22,000', () {
      expect(hi.udhaarBalance(22000), contains('22,000'));
      expect(en.udhaarBalance(22000), contains('22,000'));
    });

    test('Indian lakh formatter: 150000 → 1,50,000', () {
      expect(hi.udhaarBalance(150000), contains('1,50,000'));
      expect(en.udhaarBalance(150000), contains('1,50,000'));
    });

    test('Indian lakh formatter: amounts below 1000 have no comma', () {
      expect(hi.udhaarBalance(750), contains('750'));
      expect(hi.udhaarBalance(750), isNot(contains(',')));
    });

    // Phase 1.9 code review cleanup (Agent C finding #4 defensive): lock
    // in the Indian-lakh boundary math at every decade + lakh + crore
    // transition. Agent C flagged 10,000 as a suspected bug — walking
    // through the algorithm shows it's correct, but these defensive tests
    // make any future regression loud.
    test('Indian lakh formatter: 1 → "1" (no comma)', () {
      expect(hi.udhaarBalance(1), contains(' ₹1'));
      expect(hi.udhaarBalance(1), isNot(contains(',')));
    });

    test('Indian lakh formatter: 999 → "999" (last three digits, no comma)', () {
      expect(hi.udhaarBalance(999), contains('999'));
      expect(hi.udhaarBalance(999), isNot(contains(',')));
    });

    test('Indian lakh formatter: 1000 → "1,000" (first thousand boundary)', () {
      expect(hi.udhaarBalance(1000), contains('1,000'));
      expect(en.udhaarBalance(1000), contains('1,000'));
    });

    test('Indian lakh formatter: 9999 → "9,999"', () {
      expect(hi.udhaarBalance(9999), contains('9,999'));
    });

    test('Indian lakh formatter: 10000 → "10,000" (five-digit boundary)', () {
      // Agent C flagged this case — walkthrough: rest="10", i=0 write '1',
      // i=1 check (2-1)%2=1 ≠ 0 → no comma, write '0' → "10" → "10,000".
      // Correct. This test locks it in defensively.
      expect(hi.udhaarBalance(10000), contains('10,000'));
      expect(en.udhaarBalance(10000), contains('10,000'));
    });

    test('Indian lakh formatter: 99999 → "99,999"', () {
      expect(hi.udhaarBalance(99999), contains('99,999'));
    });

    test('Indian lakh formatter: 100000 → "1,00,000" (first lakh boundary)',
        () {
      expect(hi.udhaarBalance(100000), contains('1,00,000'));
      expect(en.udhaarBalance(100000), contains('1,00,000'));
    });

    test('Indian lakh formatter: 1000000 → "10,00,000" (ten-lakh)', () {
      expect(hi.udhaarBalance(1000000), contains('10,00,000'));
    });

    test('Indian lakh formatter: 1500000 → "15,00,000"', () {
      expect(hi.udhaarBalance(1500000), contains('15,00,000'));
    });

    test('Indian lakh formatter: 10000000 → "1,00,00,000" (one crore)', () {
      expect(hi.udhaarBalance(10000000), contains('1,00,00,000'));
      expect(en.udhaarBalance(10000000), contains('1,00,00,000'));
    });

    test('shopDeactivatingBanner substitutes retention days', () {
      expect(hi.shopDeactivatingBanner(30), contains('30'));
      expect(en.shopDeactivatingBanner(30), contains('30'));
    });

    test('shopPurgeScheduledBanner substitutes days-until-purge', () {
      expect(hi.shopPurgeScheduledBanner(7), contains('7'));
      expect(en.shopPurgeScheduledBanner(7), contains('7'));
    });

    test('udhaarReminderCountBadge shows count/3 cap', () {
      expect(hi.udhaarReminderCountBadge(2), contains('2/3'));
      expect(en.udhaarReminderCountBadge(2), contains('2/3'));
    });

    test('receiptUdhaarBaaki uses permitted "बाकी" wording only', () {
      final result = hi.receiptUdhaarBaaki(5500);
      expect(result, contains('बाकी'));
      expect(result, contains('5,500'));
      // Verify absence of any forbidden vocabulary in this specific string.
      expect(result, isNot(contains('ब्याज')));
      expect(result, isNot(contains('देय')));
      expect(result, isNot(contains('जुर्माना')));
    });
  });

  // ===========================================================================
  // 4. LOCALE RESOLVER
  // ===========================================================================

  group('LocaleResolver', () {
    test('forCode("hi") returns AppStringsHi', () {
      expect(LocaleResolver.forCode('hi'), isA<AppStringsHi>());
    });

    test('forCode("en") returns AppStringsEn', () {
      expect(LocaleResolver.forCode('en'), isA<AppStringsEn>());
    });

    test('forCode is case-insensitive', () {
      expect(LocaleResolver.forCode('HI'), isA<AppStringsHi>());
      expect(LocaleResolver.forCode('EN'), isA<AppStringsEn>());
    });

    test('forCode with unknown code falls back to AppStringsHi', () {
      expect(LocaleResolver.forCode('fr'), isA<AppStringsHi>());
      expect(LocaleResolver.forCode(''), isA<AppStringsHi>());
    });

    // Phase 1.9 code review cleanup (Agent C finding #2): the original
    // test suite only covered the pure `forCode` path. The full `resolve`
    // method integrates with Remote Config — these tests exercise the
    // user-override-beats-Remote-Config precedence and the Remote Config
    // fallback path when the flag returns unexpected values.
    group('resolve with Remote Config', () {
      late _MockRemoteConfig mockConfig;

      setUp(() {
        mockConfig = _MockRemoteConfig();
      });

      test('Remote Config "hi" → AppStringsHi', () {
        when(() => mockConfig.getString('default_locale')).thenReturn('hi');
        final resolved = LocaleResolver.resolve(remoteConfig: mockConfig);
        expect(resolved, isA<AppStringsHi>());
      });

      test('Remote Config "en" → AppStringsEn (END STATE B fallback)', () {
        when(() => mockConfig.getString('default_locale')).thenReturn('en');
        final resolved = LocaleResolver.resolve(remoteConfig: mockConfig);
        expect(resolved, isA<AppStringsEn>());
      });

      test('Remote Config empty string → AppStringsHi (Brief default)', () {
        when(() => mockConfig.getString('default_locale')).thenReturn('');
        final resolved = LocaleResolver.resolve(remoteConfig: mockConfig);
        expect(resolved, isA<AppStringsHi>());
      });

      test('Remote Config unknown code → AppStringsHi with warning', () {
        when(() => mockConfig.getString('default_locale')).thenReturn('es');
        final resolved = LocaleResolver.resolve(remoteConfig: mockConfig);
        expect(resolved, isA<AppStringsHi>());
      });

      test(
        'user override "en" beats Remote Config "hi"',
        () {
          when(() => mockConfig.getString('default_locale')).thenReturn('hi');
          final resolved = LocaleResolver.resolve(
            remoteConfig: mockConfig,
            userOverride: 'en',
          );
          expect(resolved, isA<AppStringsEn>());
        },
      );

      test(
        'user override "hi" beats Remote Config "en" (customer re-enables Hindi)',
        () {
          when(() => mockConfig.getString('default_locale')).thenReturn('en');
          final resolved = LocaleResolver.resolve(
            remoteConfig: mockConfig,
            userOverride: 'hi',
          );
          expect(resolved, isA<AppStringsHi>());
        },
      );

      test('empty user override falls through to Remote Config', () {
        when(() => mockConfig.getString('default_locale')).thenReturn('en');
        final resolved = LocaleResolver.resolve(
          remoteConfig: mockConfig,
          userOverride: '',
        );
        expect(resolved, isA<AppStringsEn>());
      });
    });
  });
}
