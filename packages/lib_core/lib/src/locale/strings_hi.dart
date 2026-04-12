// =============================================================================
// AppStringsHi — the Devanagari implementation of AppStrings.
//
// **SOURCE OF TRUTH** per Brief Constraint 4 + PRD I6.9 + ADR-008. Every
// Devanagari string in this file is derived verbatim from UX Spec v1.1 §5.5
// (Sally's 50-string table of voice & tone examples). The table has been
// cross-checked against the §5.6 forbidden-vocabulary list — no string here
// contains udhaar lending terms (ADR-010) or mythic vocabulary (Constraint 10).
//
// **Sprint 0 / Constraint 15 status (as of 2026-04-11):**
// These 50 strings were authored by Sally (UX designer, not Hindi-native).
// They have NOT yet been reviewed by an Awadhi-Hindi native per Brief
// Constraint 15. The strings are approved as part of UX Spec v1.1 which
// Alok accepted, but the Hindi-native review gate (PRD I6.11 / Sprint 0)
// is still open.
//
// **Ship discipline:**
//   - Phase 1 code (infrastructure-only) can reference these strings.
//   - NO user-visible customer_app / shopkeeper_app screen may consume
//     them until Sprint 0 closes to END STATE A (reviewer hired + sign-off).
//   - If Sprint 0 closes to END STATE B, the `LocaleResolver` flips to
//     return `AppStringsEn` by default and this file becomes the opt-in
//     toggle target. No code change required in either scenario.
//
// **Forbidden vocabulary check applied:**
//   - udhaar: ब्याज / ब्याज दर / देय तिथि / जुर्माना / ऋण / वसूली / डिफ़ॉल्ट / क़िस्त (absent ✓)
//   - mythic: शुभ / मंगल / मंदिर / धर्म / तीर्थ / पूज्य / आशीर्वाद / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ (absent ✓)
// =============================================================================

import 'strings_base.dart';

/// Devanagari implementation of [AppStrings]. Consume via
/// `AppStringsHi()` or via `LocaleResolver.resolve()` which handles
/// Remote Config `defaultLocale` selection.
class AppStringsHi extends AppStrings {
  /// Default const constructor.
  const AppStringsHi();

  @override
  String get localeCode => 'hi';

  // ---- §1 Landing + greeting ----

  @override
  String get shopDisplayName => 'सुनील ट्रेडिंग कंपनी';

  @override
  String get greetingVoiceNoteLabel => 'सुनील भैया का स्वागत संदेश';

  // ---- §1b Bharosa landing ----

  @override
  String metaBarYearsInBusiness(int years, int establishedYear) =>
      '$years साल · $establishedYear से';

  @override
  String get greetingCardTitle => 'नमस्ते जी, स्वागत है';

  @override
  String greetingVoiceNoteSublabel(String ownerName, int seconds) =>
      '$ownerName का स्वागत संदेश · $seconds सेकंड';

  @override
  String get muteToggleOn => 'आवाज़ चालू कीजिए';

  @override
  String get muteToggleMute => 'चुप कीजिए';

  @override
  String shortlistPreviewHeadline(String ownerName) =>
      '$ownerName की पसंद · आज के लिए';

  @override
  String get shortlistBadgeCurated => 'चुनी हुई';

  @override
  String get presenceStatusAvailable => '● दुकान पर हैं';

  @override
  String get metaBarMapLabel => 'नक्शा';

  // ---- §1c Browse widgets ----

  @override
  String get skuTopPickBadge => 'सुनील भैया की पसंद';

  @override
  String get skuNegotiableLabel => 'मोल भाव';

  @override
  String get goldenHourToggleBeautiful => 'सुंदर रूप';

  // ---- §2 Curated shortlists ----

  @override
  String get shortlistTitleShaadi => 'शादी के लिए';

  @override
  String get shortlistTitleNayaGhar => 'नए घर के लिए';

  @override
  String get shortlistTitlePuranaBadlne => 'पुराना बदलने के लिए';

  @override
  String get shortlistTitleDahej => 'दहेज के लिए';

  @override
  String get shortlistTitleBudget => 'बजट के अनुसार';

  @override
  String get shortlistTitleLadies => 'लेडीज के लिए';

  // ---- §3 SKU detail ----

  @override
  String get skuAddToList => 'इसे शॉर्टलिस्ट करें';

  @override
  String get skuTalkToBhaiya => 'सुनील भैया से बात करें';

  @override
  String get asliRoopToggle => 'असली रूप दिखाइए';

  // ---- §4 Chat ----

  @override
  String get chatThreadTitle => 'सुनील भैया का कमरा';

  @override
  String get chatInputPlaceholder => 'यहाँ संदेश लिखिए...';

  // ---- §4b C3.1 + P2.4 + P2.5 Chat + Draft ----

  @override
  String chatThreadTitleWithOrder(String suffix) =>
      'सुनील भैया का कमरा — आपका ऑर्डर #$suffix';

  @override
  String get myListTitle => 'मेरी सूची';

  @override
  String get addedToList => 'सूची में जोड़ा गया';

  @override
  String get chatSenderYou => 'आप';

  @override
  String get chatSenderBhaiya => 'सुनील भैया';

  @override
  String get chatSendButton => 'भेजिए';

  @override
  String get chatMessagePending => 'भेज रहे हैं...';

  // ---- §4c C3.2 Draft line item editing ----

  @override
  String draftItemRemoved(String skuName) => '$skuName हटाई गई';

  @override
  String get draftUndoRemove => 'वापस लाइए';

  @override
  String get draftQtyHighTitle => '10 से ज़्यादा?';

  @override
  String draftQtyHighBody(int qty, String skuName) =>
      '$skuName $qty चाहिए — पक्का?';

  @override
  String get draftQtyHighConfirm => 'हाँ, जोड़िए';

  @override
  String get draftQtyHighCancel => 'नहीं';

  @override
  String get draftTotalLabel => 'कुल';

  // ---- §4d C3.3 Negotiation flow ----

  @override
  String proposalBubbleLabel(String skuName) =>
      'सुनील भैया की पेशकश — $skuName';

  @override
  String proposalPriceLine(int amount) => '₹${_formatInr(amount)}';

  @override
  String get proposalAcceptButton => 'मंज़ूर है';

  @override
  String get proposalAcceptedBadge => 'मंज़ूर';

  @override
  String proposalAcceptedSystemMessage(int amount, String skuName) =>
      '₹${_formatInr(amount)} पर $skuName पक्का हुआ';

  @override
  String get proposalOriginalPriceLabel => 'पहले का दाम';

  // ---- §5 Commit + OTP + payment ----

  @override
  String get commitButtonPakka => 'ऑर्डर पक्का कीजिए';

  @override
  String get otpPromptBhaiyaNeedsIt =>
      'सुनील भैया डिलीवरी के लिए संपर्क करेंगे, आपका फ़ोन नंबर चाहिए';

  @override
  String get phoneInputLabel => 'अपना फ़ोन नंबर दीजिए';

  @override
  String get otpCodeLabel => 'OTP कोड दीजिए';

  @override
  String get otpSendButton => 'OTP भेजिए';

  @override
  String get otpVerifyButton => 'पुष्टि कीजिए';

  @override
  String get otpInvalidCode => 'OTP सही नहीं है — दुबारा कोशिश कीजिए';

  @override
  String get otpCodeExpired => 'OTP की समय सीमा बीत गई — दुबारा भेजिए';

  @override
  String get commitSuccessTitle => 'ऑर्डर पक्का हुआ!';

  @override
  String get proceedToPayment => 'अब भुगतान कीजिए';

  @override
  String get orderTotalLabel => 'कुल रकम';

  @override
  String get commitFailed => 'ऑर्डर नहीं हो सका — दुबारा कोशिश कीजिए';

  @override
  String get upiPayButton => 'UPI से दीजिए';

  @override
  String get paymentOtherMethods => 'और तरीके';

  @override
  String get noUpiAppFound =>
      'UPI ऐप नहीं मिला — कोई और तरीका चुनिए';

  @override
  String get paymentProcessing => 'भुगतान हो रहा है...';

  @override
  String get paymentSuccessPakka => 'ऑर्डर पक्का हुआ! धन्यवाद।';

  // ---- §5b C3.6 COD + C3.7 Bank transfer ----

  @override
  String get codOption => 'डिलीवरी पर नकद';

  @override
  String get codConfirmNote =>
      'सुनील भैया डिलीवरी के समय पैसे लेंगे';

  @override
  String get codConfirmButton => 'COD पक्का कीजिए';

  @override
  String get bankTransferOption => 'बैंक से सीधे भेजिए';

  @override
  String get bankTransferMarkPaid => 'भेज दिया — पुष्टि कीजिए';

  @override
  String get bankAccountNumberLabel => 'खाता नंबर';

  @override
  String get bankIfscLabel => 'IFSC कोड';

  @override
  String get bankAccountHolderLabel => 'खाताधारक का नाम';

  @override
  String get bankBranchLabel => 'शाखा';

  @override
  String get awaitingVerificationMessage =>
      'सुनील भैया बैंक चेक करेंगे — थोड़ा इंतज़ार कीजिए';

  // ---- §5c S4.6 Active projects list ----

  @override
  String get ordersTitle => 'ऑर्डर';

  @override
  String get filterAll => 'सब';

  @override
  String get filterCommitted => 'पुष्टि की';

  @override
  String get filterPendingPayment => 'भुगतान बाकी';

  @override
  String get filterDelivering => 'डिलीवरी में';

  @override
  String get filterClosed => 'बंद';

  @override
  String get emptyOrdersList =>
      'जल्द ही पहला ऑर्डर आएगा।';

  // ---- §6 Udhaar khaata ----

  @override
  String get udhaarProposal => 'सुनील भैया ने उधार खाता प्रस्तावित किया है';

  @override
  String udhaarBalance(int amount) =>
      'सुनील भैया में बाकी: ₹${_formatInr(amount)}';

  @override
  String get deliveryConfirmed => 'सुनील भैया ने ऑर्डर डिलीवर कर दिया';

  @override
  String udhaarReminderPush(int amount) =>
      'आपका खाता: सुनील भैया में ₹${_formatInr(amount)} बाकी';

  // ---- §7 Empty states ----

  @override
  String get emptyDraftList =>
      'आपकी सूची अभी खाली है। नीचे से कुछ चुनिए।';

  @override
  String get noOrdersYet =>
      'अभी तक कोई ऑर्डर नहीं। जब आप पहला ऑर्डर करेंगे, यहाँ दिखेगा।';

  @override
  String get emptyShortlistNotYetCurated =>
      'अभी तक सुनील भैया ने इसमें कुछ नहीं चुना';

  @override
  String get emptyDecisionCircle =>
      'अभी सिर्फ़ आप हैं। परिवार को जोड़ने के लिए लिंक भेजिए।';

  // ---- §8 Errors + connectivity ----

  @override
  String get noInternetShowingCached =>
      'अभी इंटरनेट नहीं है — जो पहले देखा था, वो दिखा रहे हैं';

  @override
  String get uploadPending => 'अपलोड बाकी है';

  @override
  String get paymentFailed =>
      'भुगतान नहीं हो सका। दुबारा कोशिश कीजिए या और तरीका चुनिए।';

  @override
  String get voiceNoteSendFailed =>
      'आवाज़ नोट नहीं भेजा जा सका। अपना इंटरनेट देखिए।';

  @override
  String get opsAppNotAuthorized =>
      'आप अभी authorized नहीं हैं। Yugma Labs से संपर्क कीजिए।';

  // ---- §9 Absence presence ----

  @override
  String get awayBannerAtShaadi =>
      'सुनील भैया आज शाम एक शादी में हैं, 6 बजे तक वापस';

  // ---- §10 Decision Circle persona toggle ----

  @override
  String get personaLabelIAmLooking => 'मैं देख रहा हूँ';

  @override
  String get personaLabelIAmLookingFemale => 'मैं देख रही हूँ';

  @override
  String get personaLabelMummyJi => 'मम्मी जी देख रही हैं';

  // ---- §11 B1.13 Receipt / invoice ----

  @override
  String get receiptThankYouFooter => 'धन्यवाद, आपका विश्वास हमारा भविष्य है';

  @override
  String get receiptOpenButton => 'रसीद देखें';

  @override
  String get receiptCancelledWatermark => 'रद्द';

  @override
  String receiptUdhaarBaaki(int amount) => 'बाकी: ₹${_formatInr(amount)}';

  @override
  String get receiptCustomerFallback => 'ग्राहक';

  // ---- §12 C3.12 Shop deactivation ----

  @override
  String shopDeactivatingBanner(int retentionDays) =>
      'सुनील भैया की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, '
      'आपका डेटा $retentionDays दिन तक सुरक्षित है';

  @override
  String shopPurgeScheduledBanner(int daysUntilPurge) =>
      'डेटा $daysUntilPurge दिन में हटा दिया जाएगा — export कीजिए';

  @override
  String get shopDeactivationFaqTitle => 'क्या हो रहा है?';

  @override
  String get dataExportCta => 'डेटा export कीजिए';

  // ---- §13 S4.17 NPS card ----

  @override
  String get npsCardHeadline => 'कितना उपयोगी लगा?';

  @override
  String get npsOptionalPrompt => 'कुछ कहना है?';

  @override
  String get npsSnoozeLater => 'बाद में';

  // ---- §14 S4.19 Shop closure ----

  @override
  String get shopClosureSettingsOption => 'दुकान बंद करने का विकल्प';

  @override
  String get shopClosureReversibilityFooter =>
      'अगर गलती से दबाया, अगले 24 घंटे में उल्टा कर सकते हैं';

  // ---- §15 S4.16 Media spend tile ----

  @override
  String get mediaSpendTileLabel => 'मीडिया खर्च';

  @override
  String get cloudinaryExhaustedR2Active => 'Cloudinary खत्म — R2 चालू';

  // ---- §16 S4.10 Udhaar reminder affordances ----

  @override
  String get udhaarReminderOptInPrompt =>
      'क्या मैं इस ग्राहक को याद दिलाऊँ?';

  @override
  String udhaarReminderCountBadge(int count) => 'याद दिलाया गया: $count/3';

  @override
  String get udhaarReminderCadencePrompt => 'कितने दिन बाद याद दिलाना है?';

  // ---- §17 S4.1 + S4.13 Ops app foundation ----

  @override
  String get signInWithGoogle => 'Google से sign in कीजिए';

  @override
  String get todaysTaskTitle => 'आज का काम';

  @override
  String get todaysTaskDone => 'हो गया';

  @override
  String get todaysTaskDismiss => 'छुपा दीजिए';

  @override
  String todaysTaskMinutes(int n) => '$n मिनट';

  @override
  String get signOutLabel => 'Sign out कीजिए';

  @override
  String get opsDashboardTitle => 'दुकान का काम';

  @override
  String get todaysTaskDay30Celebration =>
      'बधाई! 30 दिन पूरे हुए। अब पहले ग्राहक को दिखाइए।';

  @override
  String get opsPermissionRevoked =>
      'अब आप authorized नहीं हैं। Yugma Labs से संपर्क कीजिए।';

  // ---- §18 S4.3 Inventory SKU creation ----

  @override
  String get inventoryTitle => 'सामान';
  @override
  String get createSkuButton => 'नया सामान जोड़िए';
  @override
  String get skuNameDevanagariLabel => 'सामान का नाम (हिंदी)';
  @override
  String get skuNameEnglishLabel => 'सामान का नाम (English)';
  @override
  String get skuCategoryLabel => 'श्रेणी';
  @override
  String get skuBasePriceLabel => 'दाम (₹)';
  @override
  String get skuNegotiableFloorLabel => 'मोल भाव में कम से कम (₹)';
  @override
  String get skuDimensionsLabel => 'साइज़ (ऊँचाई × चौड़ाई × गहराई cm)';
  @override
  String get skuMaterialLabel => 'सामग्री';
  @override
  String get skuInStockLabel => 'स्टॉक में है';
  @override
  String get skuDescriptionLabel => 'जानकारी (हिंदी)';
  @override
  String get skuSaveButton => 'सामान जोड़ दीजिए';
  @override
  String get skuGoldenHourPhotoButton => 'Golden Hour फ़ोटो लीजिए';
  @override
  String get skuStockCountLabel => 'कितने हैं';
  @override
  String get skuDuplicateNameWarning =>
      'इस नाम का सामान पहले से है। फिर भी जोड़ सकते हैं।';
  @override
  String get skuSavedSuccess => 'सामान जुड़ गया!';
  @override
  String get validationRequired => 'यह भरना ज़रूरी है';
  @override
  String get validationPricePositive => 'दाम 0 से ज़्यादा होना चाहिए';
  @override
  String get validationFloorExceedsBase =>
      'मोल भाव की कीमत दाम से कम होनी चाहिए';
  @override
  String get validationDimensionPositive => 'साइज़ 0 से ज़्यादा होना चाहिए';
  @override
  String get inventoryEmpty =>
      'अभी कोई सामान नहीं है। + बटन से नया सामान जोड़िए।';

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Format INR rupee amount with Indian lakh/thousand separators.
  /// Examples: 22000 → "22,000"; 150000 → "1,50,000".
  ///
  /// Western numerals per UX Spec §5.4 — prices always use 0-9, not ०-९,
  /// because UPI / WhatsApp / every other surface uses Western numerals
  /// and consistency with the user's broader digital life wins over purity.
  static String _formatInr(int amount) {
    if (amount < 1000) return amount.toString();
    final str = amount.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i != 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '$buffer,$lastThree';
  }
}
