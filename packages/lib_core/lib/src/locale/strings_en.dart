// =============================================================================
// AppStringsEn — the English implementation of AppStrings.
//
// Per Brief Constraint 4 + §5.5, English is the derived translation of the
// Hindi source-of-truth. Every string here mirrors the corresponding
// Devanagari string in `strings_hi.dart` — both in meaning and in the
// "warm but direct, non-apologetic" tone register.
//
// **Constraint 15 fallback role (ADR-008 v1.0.4):**
// When Sprint 0 closes to END STATE B (Hindi-native design capacity not
// secured), `LocaleResolver` flips the default to return this class. At
// that point the customer app boots in English with a Hindi toggle, and
// this file becomes the user-visible default until Hindi capacity is
// eventually secured.
//
// **Forbidden vocabulary check applied (UX Spec §5.6):**
//   - udhaar lending: interest / due date / overdue / past due / late fee /
//     penalty / loan / credit / lending / default / defaulter / collection /
//     recovery / installment / EMI / debt (absent ✓)
//   - "Payment failed" replaced with "Payment didn't go through" (per §5.8)
//   - Non-apologetic empty states, no "Unfortunately..." / "Sorry..." (per §5.7)
// =============================================================================

import 'strings_base.dart';

/// English implementation of [AppStrings]. Activated when the Hindi
/// toggle is engaged OR when Sprint 0 / Constraint 15 END STATE B is
/// triggered (default locale flipped to `en` via Remote Config).
class AppStringsEn extends AppStrings {
  /// Default const constructor.
  const AppStringsEn();

  @override
  String get localeCode => 'en';

  // ---- §1 Landing + greeting ----

  @override
  String get shopDisplayName => 'Sunil Trading Company';

  @override
  String get greetingVoiceNoteLabel => "Sunil-bhaiya's welcome message";

  // ---- §1b Bharosa landing ----

  @override
  String metaBarYearsInBusiness(int years, int establishedYear) =>
      '$years years · since $establishedYear';

  @override
  String get greetingCardTitle => 'Hello, welcome';

  @override
  String greetingVoiceNoteSublabel(String ownerName, int seconds) =>
      "$ownerName's welcome message · $seconds sec";

  @override
  String get muteToggleOn => 'Turn sound on';

  @override
  String get muteToggleMute => 'Mute';

  @override
  String shortlistPreviewHeadline(String ownerName) =>
      "$ownerName's picks · for today";

  @override
  String get shortlistBadgeCurated => 'Curated';

  @override
  String get presenceStatusAvailable => '● At the shop';

  @override
  String get metaBarMapLabel => 'Map';

  // ---- §1c Browse widgets ----

  @override
  String get skuTopPickBadge => "Sunil-bhaiya's pick";

  @override
  String get skuNegotiableLabel => 'Negotiable';

  @override
  String get goldenHourToggleBeautiful => 'Beautiful view';

  // ---- §2 Curated shortlists ----

  @override
  String get shortlistTitleShaadi => 'For a wedding';

  @override
  String get shortlistTitleNayaGhar => 'For the new home';

  @override
  String get shortlistTitlePuranaBadlne => 'To replace the old one';

  @override
  String get shortlistTitleDahej => 'For dahej';

  @override
  String get shortlistTitleBudget => 'Budget picks';

  @override
  String get shortlistTitleLadies => 'For ladies';

  // ---- §3 SKU detail ----

  @override
  String get skuAddToList => 'Add to my list';

  @override
  String get skuTalkToBhaiya => 'Talk to Sunil-bhaiya';

  @override
  String get asliRoopToggle => 'Show the real form';

  // ---- §4 Chat ----

  @override
  String get chatThreadTitle => "Sunil-bhaiya's room";

  @override
  String get chatInputPlaceholder => 'Type your message here…';

  // ---- §4b C3.1 + P2.4 + P2.5 Chat + Draft ----

  @override
  String chatThreadTitleWithOrder(String suffix) =>
      "Sunil-bhaiya's room — your order #$suffix";

  @override
  String get myListTitle => 'My list';

  @override
  String get addedToList => 'Added to list';

  @override
  String get chatSenderYou => 'You';

  @override
  String get chatSenderBhaiya => 'Sunil-bhaiya';

  @override
  String get chatSendButton => 'Send';

  @override
  String get chatMessagePending => 'Sending...';

  // ---- §5 Commit + OTP + payment ----

  @override
  String get commitButtonPakka => 'Confirm the order';

  @override
  String get otpPromptBhaiyaNeedsIt =>
      'Sunil-bhaiya will contact you for delivery — we need your phone number';

  @override
  String get upiPayButton => 'Pay via UPI';

  @override
  String get paymentSuccessPakka => 'Order confirmed. Thank you.';

  // ---- §6 Udhaar khaata ----

  @override
  String get udhaarProposal => 'Sunil-bhaiya has proposed a khaata';

  @override
  String udhaarBalance(int amount) =>
      'Remaining with Sunil-bhaiya: ₹${_formatInr(amount)}';

  @override
  String get deliveryConfirmed => 'Sunil-bhaiya has delivered the order';

  @override
  String udhaarReminderPush(int amount) =>
      'Your account: ₹${_formatInr(amount)} remaining with Sunil-bhaiya';

  // ---- §7 Empty states ----

  @override
  String get emptyDraftList =>
      'Your list is empty right now. Pick something from below.';

  @override
  String get noOrdersYet =>
      "No orders yet. When you place your first one, it'll show here.";

  @override
  String get emptyShortlistNotYetCurated =>
      "Sunil-bhaiya hasn't picked anything for this yet";

  @override
  String get emptyDecisionCircle =>
      "Right now it's just you. Send a link to bring family in.";

  // ---- §8 Errors + connectivity ----

  @override
  String get noInternetShowingCached =>
      'No internet right now — showing what you last saw';

  @override
  String get uploadPending => 'Upload pending';

  @override
  String get paymentFailed =>
      "Payment didn't go through. Try again or pick another method.";

  @override
  String get voiceNoteSendFailed =>
      "Voice note couldn't be sent. Check your internet.";

  @override
  String get opsAppNotAuthorized =>
      'You are not yet authorized. Contact Yugma Labs.';

  // ---- §9 Absence presence ----

  @override
  String get awayBannerAtShaadi =>
      'Sunil-bhaiya is at a wedding this evening, back by 6 PM';

  // ---- §10 Decision Circle persona toggle ----

  @override
  String get personaLabelIAmLooking => 'I am looking';

  @override
  String get personaLabelIAmLookingFemale => 'I am looking';

  @override
  String get personaLabelMummyJi => 'Mummy-ji is looking';

  // ---- §11 B1.13 Receipt / invoice ----

  @override
  String get receiptThankYouFooter => 'Thank you — your trust is our future';

  @override
  String get receiptOpenButton => 'View receipt';

  @override
  String get receiptCancelledWatermark => 'CANCELLED';

  @override
  String receiptUdhaarBaaki(int amount) => 'Remaining: ₹${_formatInr(amount)}';

  @override
  String get receiptCustomerFallback => 'Customer';

  // ---- §12 C3.12 Shop deactivation ----

  @override
  String shopDeactivatingBanner(int retentionDays) =>
      "Sunil-bhaiya's shop is closing — your money will come back, "
      'your data is safe for $retentionDays days';

  @override
  String shopPurgeScheduledBanner(int daysUntilPurge) =>
      'Data will be deleted in $daysUntilPurge days — export now';

  @override
  String get shopDeactivationFaqTitle => 'What is happening?';

  @override
  String get dataExportCta => 'Export your data';

  // ---- §13 S4.17 NPS card ----

  @override
  String get npsCardHeadline => 'How useful was it?';

  @override
  String get npsOptionalPrompt => 'Anything you want to say?';

  @override
  String get npsSnoozeLater => 'Later';

  // ---- §14 S4.19 Shop closure ----

  @override
  String get shopClosureSettingsOption => 'Shop closure option';

  @override
  String get shopClosureReversibilityFooter =>
      'If you tapped by mistake, you can reverse this in the next 24 hours';

  // ---- §15 S4.16 Media spend tile ----

  @override
  String get mediaSpendTileLabel => 'Media spend';

  @override
  String get cloudinaryExhaustedR2Active => 'Cloudinary done — R2 active';

  // ---- §16 S4.10 Udhaar reminder affordances ----

  @override
  String get udhaarReminderOptInPrompt => 'Should I remind this customer?';

  @override
  String udhaarReminderCountBadge(int count) => 'Reminded: $count/3';

  @override
  String get udhaarReminderCadencePrompt => 'After how many days should I remind?';

  // ---- §17 S4.1 + S4.13 Ops app foundation ----

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get todaysTaskTitle => "Today's task";

  @override
  String get todaysTaskDone => 'Done';

  @override
  String get todaysTaskDismiss => 'Hide';

  @override
  String todaysTaskMinutes(int n) => '$n min';

  @override
  String get signOutLabel => 'Sign out';

  @override
  String get opsDashboardTitle => 'Shop operations';

  @override
  String get todaysTaskDay30Celebration =>
      'Congratulations! 30 days complete. Now show it to the first customer.';

  @override
  String get opsPermissionRevoked =>
      'You are no longer authorized. Contact Yugma Labs.';

  // ---- §18 S4.3 Inventory SKU creation ----

  @override
  String get inventoryTitle => 'Inventory';
  @override
  String get createSkuButton => 'Add new item';
  @override
  String get skuNameDevanagariLabel => 'Item name (Hindi)';
  @override
  String get skuNameEnglishLabel => 'Item name (English)';
  @override
  String get skuCategoryLabel => 'Category';
  @override
  String get skuBasePriceLabel => 'Price (₹)';
  @override
  String get skuNegotiableFloorLabel => 'Negotiate-to floor (₹)';
  @override
  String get skuDimensionsLabel => 'Size (H × W × D cm)';
  @override
  String get skuMaterialLabel => 'Material';
  @override
  String get skuInStockLabel => 'In stock';
  @override
  String get skuDescriptionLabel => 'Description (Hindi)';
  @override
  String get skuSaveButton => 'Add item';
  @override
  String get skuGoldenHourPhotoButton => 'Capture Golden Hour photo';
  @override
  String get skuStockCountLabel => 'How many';
  @override
  String get skuDuplicateNameWarning =>
      'An item with this name already exists. You can still add it.';
  @override
  String get skuSavedSuccess => 'Item added!';
  @override
  String get validationRequired => 'This field is required';
  @override
  String get validationPricePositive => 'Price must be greater than 0';
  @override
  String get validationFloorExceedsBase =>
      'Floor price must be less than base price';
  @override
  String get validationDimensionPositive => 'Dimension must be greater than 0';
  @override
  String get inventoryEmpty => 'No items yet. Tap + to add your first item.';

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Format INR rupee amount with Indian lakh/thousand separators.
  /// Indian numerical format — shared with strings_hi.dart for consistency.
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
