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

import '../utils/format_inr.dart';
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
  @override
  String get goldenHourTitle => 'Golden Hour Photo';
  @override
  String get goldenHourLightGuide => 'Sunlight should fall at an angle';
  @override
  String get goldenHourCaptureButton => 'Take photo';
  @override
  String get goldenHourHeroLabel => 'Hero photo';
  @override
  String get goldenHourWorkingLabel => 'Working photo';
  @override
  String get goldenHourRetake => 'Retake';
  @override
  String get goldenHourSave => 'Save';

  // ---- §2 Curated shortlists ----

  @override
  String get shortlistTitleShaadi => 'For a wedding';

  @override
  String get shortlistTitleNayaGhar => 'For the new home';

  @override
  String get shortlistTitlePuranaBadlne => 'To replace the old one';

  @override
  String get shortlistTitleBetiKaGhar => "For daughter's new home";

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

  // ---- §4c C3.2 Draft line item editing ----

  @override
  String draftItemRemoved(String skuName) => '$skuName removed';

  @override
  String get draftUndoRemove => 'Undo';

  @override
  String get draftQtyHighTitle => 'More than 10?';

  @override
  String draftQtyHighBody(int qty, String skuName) =>
      'You need $qty of $skuName — sure?';

  @override
  String get draftQtyHighConfirm => 'Yes, add';

  @override
  String get draftQtyHighCancel => 'No';

  @override
  String get draftTotalLabel => 'Total';

  // ---- §4d C3.3 Negotiation flow ----

  @override
  String proposalBubbleLabel(String skuName) =>
      "Sunil-bhaiya's offer — $skuName";

  @override
  String proposalPriceLine(int amount) => '₹${formatInr(amount)}';

  @override
  String get proposalAcceptButton => 'Accept';

  @override
  String get proposalAcceptedBadge => 'Accepted';

  @override
  String proposalAcceptedSystemMessage(int amount, String skuName) =>
      '$skuName confirmed at ₹${formatInr(amount)}';

  @override
  String get proposalOriginalPriceLabel => 'Original price';

  // ---- §5 Commit + OTP + payment ----

  @override
  String get commitButtonPakka => 'Confirm the order';

  @override
  String get otpPromptBhaiyaNeedsIt =>
      'Sunil-bhaiya will contact you for delivery — we need your phone number';

  @override
  String get phoneInputLabel => 'Enter your phone number';

  @override
  String get otpCodeLabel => 'Enter OTP code';

  @override
  String get otpSendButton => 'Send OTP';

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get otpInvalidCode => 'Invalid OTP — please try again';

  @override
  String get otpCodeExpired => 'OTP expired — please resend';

  @override
  String otpResendCountdown(int seconds) => 'Resend in ${seconds}s';

  @override
  String get commitSuccessTitle => 'Order confirmed!';

  @override
  String get proceedToPayment => 'Proceed to payment';

  @override
  String get orderTotalLabel => 'Total amount';

  @override
  String get commitFailed => 'Order failed — please try again';

  @override
  String get upiPayButton => 'Pay via UPI';

  @override
  String get paymentOtherMethods => 'Other ways to pay';

  @override
  String get noUpiAppFound =>
      'No UPI app found — choose another method';

  @override
  String get paymentProcessing => 'Processing payment...';

  @override
  String get paymentSuccessPakka => 'Order confirmed. Thank you.';

  // ---- §5b C3.6 COD + C3.7 Bank transfer ----

  @override
  String get codOption => 'Cash on delivery';

  @override
  String get codConfirmNote =>
      'Sunil-bhaiya will collect payment when he delivers';

  @override
  String get codConfirmButton => 'Confirm COD';

  @override
  String get bankTransferOption => 'Send directly from bank';

  @override
  String get bankTransferMarkPaid => 'I have sent it — confirm';

  @override
  String get bankAccountNumberLabel => 'Account number';

  @override
  String get bankIfscLabel => 'IFSC code';

  @override
  String get bankAccountHolderLabel => 'Account holder name';

  @override
  String get bankBranchLabel => 'Branch';

  @override
  String get awaitingVerificationMessage =>
      'Sunil-bhaiya will check the bank — please wait';

  // ---- §5c S4.6 Active projects list ----

  @override
  String get ordersTitle => 'Orders';

  @override
  String get filterAll => 'All';

  @override
  String get filterCommitted => 'Committed';

  @override
  String get filterPendingPayment => 'Pending payment';

  @override
  String get filterDelivering => 'Delivering';

  @override
  String get filterClosed => 'Closed';

  @override
  String get emptyOrdersList =>
      'First order coming soon.';

  // ---- §6 Udhaar khaata ----

  @override
  String get udhaarProposal => 'Sunil-bhaiya has proposed a khaata';

  @override
  String udhaarBalance(int amount) =>
      'Remaining with Sunil-bhaiya: ₹${formatInr(amount)}';

  @override
  String get deliveryConfirmed => 'Sunil-bhaiya has delivered the order';

  @override
  String udhaarReminderPush(int amount) =>
      'Your account: ₹${formatInr(amount)} remaining with Sunil-bhaiya';

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
  String receiptUdhaarBaaki(int amount) => 'Remaining: ₹${formatInr(amount)}';

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
      'If you tapped by mistake, you can reverse this in the next 30 days';

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
  String get skuSaveBeforePhoto => 'Save the item first, then take photo';
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

  // ---- §19 S4.7 Project detail ----

  @override
  String get projectDetailTitle => 'Order details';
  @override
  String get lineItemsHeader => 'Items';
  @override
  String get customerInfoHeader => 'Customer info';
  @override
  String get newCustomerPlaceholder => 'New customer';
  @override
  String chatPreviewHeader(int count) => 'Chat ($count)';
  @override
  String get sendMessageButton => 'Send message';
  @override
  String get markDeliveredButton => 'Mark delivered';
  @override
  String get cancelOrderButton => 'Cancel order';
  @override
  String get filterNegotiating => 'Negotiating';

  // ---- §20 S4.8 Shopkeeper chat reply ----

  @override
  String get proposePriceButton => 'Propose price';
  @override
  String get proposalSelectItemPrompt => 'Which item?';
  @override
  String get proposalPriceInputLabel => 'Your price (₹)';
  @override
  String get proposalSendButton => 'Send';
  @override
  String get proposalSentConfirmation => 'Price proposal sent';

  // ---- §21 S4.4 Inventory edit ----

  @override
  String get editSkuTitle => 'Edit item';
  @override
  String get skuSaveChangesButton => 'Save changes';
  @override
  String get skuChangesSaved => 'Changes saved!';
  @override
  String get skuStockAdjustLabel => 'Stock';

  // ---- §22 C3.8 + C3.9 Udhaar khaata flow ----

  @override
  String get udhaarStartButton => 'Start udhaar khaata';
  @override
  String get udhaarTodayPaymentLabel => 'How much will they pay today?';
  @override
  String get udhaarBalanceLabel => 'Running balance';
  @override
  String get udhaarConfirmButton => 'Confirm';
  @override
  String get udhaarCreatedSuccess => 'Udhaar khaata created';
  @override
  String get udhaarAcceptButton => 'Accept';
  @override
  String get udhaarDeclineButton => 'Decline';
  @override
  String get udhaarAcceptedConfirmation => 'Udhaar khaata accepted';
  @override
  String get udhaarRecordPaymentButton => 'Record payment';
  @override
  String get udhaarAmountPaidLabel => 'Amount received';
  @override
  String get udhaarPaymentMethodLabel => 'Payment method';
  @override
  String get udhaarPaymentRecordedSuccess => 'Payment recorded';
  @override
  String get udhaarLedgerClosed => 'Udhaar khaata closed — balance zero';
  @override
  String get udhaarOverpaymentError => 'Amount exceeds balance';

  // ---- §23 S4.9 Customer memory editing ----

  @override
  String get memoryEditButton => 'Edit memory';
  @override
  String get memorySheetTitle => 'Customer memory';
  @override
  String get memoryNotesLabel => 'Notes';
  @override
  String get memoryRelationshipLabel => 'Relationships';
  @override
  String get memoryOccasionsLabel => 'Buying occasions';
  @override
  String get memoryPriceRangeLabel => 'Budget';
  @override
  String get memoryPriceMinLabel => 'Min (₹)';
  @override
  String get memoryPriceMaxLabel => 'Max (₹)';
  @override
  String get memorySaved => 'Memory saved';
  @override
  String get memoryNewCustomerPlaceholder => 'New customer — first time';

  // ---- §24 D-2: Order detail timeline labels ----

  @override
  String orderItemCount(int count) => '$count items';

  @override
  String get orderStatusLabel => 'Status';

  @override
  String get orderDownloadReceipt => 'Download receipt';

  @override
  String get timelineCommitted => 'Confirmed';

  @override
  String get timelineUdhaarStarted => 'Udhaar khaata started';

  @override
  String get timelinePaid => 'Paid';

  @override
  String get timelineBankTransferPending => 'Bank transfer — verification pending';

  @override
  String get timelineDelivering => 'Out for delivery';

  @override
  String get timelineDelivered => 'Delivered';

  @override
  String get timelineClosed => 'Closed';

  @override
  String get timelineCancelled => 'Cancelled';

  @override
  String get timelineDraft => 'Draft';

  @override
  String get receiptGenerating => 'Generating receipt…';

  @override
  String receiptShareSubject(String projectId) => 'Receipt — $projectId';

  @override
  String receiptGenerationError(String detail) =>
      'Receipt generation failed: $detail';

  @override
  String monthName(int month) => const <int, String>{
        1: 'January',
        2: 'February',
        3: 'March',
        4: 'April',
        5: 'May',
        6: 'June',
        7: 'July',
        8: 'August',
        9: 'September',
        10: 'October',
        11: 'November',
        12: 'December',
      }[month] ?? '';

  // ---- §25 D-2: Order list state badge labels ----

  @override
  String get stateBadgeDraft => 'Draft';

  @override
  String get stateBadgeNegotiating => 'Negotiating';

  @override
  String get stateBadgeCommitted => 'Confirmed';

  @override
  String get stateBadgePaid => 'Paid';

  @override
  String get stateBadgeDelivering => 'Delivering';

  @override
  String get stateBadgeAwaitingVerification => 'Pending payment';

  @override
  String get stateBadgeClosed => 'Closed';

  @override
  String get stateBadgeCancelled => 'Cancelled';

  // ---- §26 D-2: Analytics dashboard labels ----

  @override
  String get analyticsOrders => 'Orders';

  @override
  String get analyticsRevenue => 'Revenue';

  @override
  String get analyticsOpenOrders => 'Open orders';

  @override
  String get analyticsUdhaarPending => 'Udhaar pending';

  @override
  String get analyticsNewCustomers => 'New customers';

  @override
  String get analyticsLast7Days => 'Last 7 days';

  @override
  String get analyticsNoOrdersYet => 'No orders yet';

  // ---- §27 D-2: Voice recorder widget labels ----

  @override
  String get micPermissionNeeded =>
      'Microphone permission needed — please allow in settings';

  @override
  String get voiceGoBack => 'Go back';

  @override
  String get voiceMinDuration => 'At least 5 seconds';

  @override
  String get voiceRecordingInProgress => 'Recording...';

  @override
  String get voiceCancel => 'Cancel';

  @override
  String get voiceReRecord => 'Re-record';

  @override
  String get voiceCancelShort => 'Cancel';

  // ---- §28 D-2: Presence toggle screen labels ----

  @override
  String get presenceAtShop => 'At the shop';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceBusyWithCustomer => 'With a customer';

  @override
  String get presenceAtEvent => 'At a wedding / event';

  @override
  String get presenceMyAvailability => 'My availability';

  @override
  String get presenceReturnTimePrompt => 'When will you be back?';

  @override
  String get presenceReturnTimeDefault => '6 PM';

  @override
  String get presenceVoicePrompt => 'Let the customer hear your voice';

  @override
  String presenceVoiceRecorded(int seconds) =>
      'Voice recorded — $seconds seconds';

  @override
  String get presenceRemoveVoice => 'Remove';

  @override
  String get presenceUpdateButton => 'Update';

  @override
  String get presenceUpdated => 'Availability updated';

  // ---- §29 D-2: Curation screen labels ----

  @override
  String get curationMyPicks => 'My picks';

  @override
  String get curationEmptyPrompt => 'Nothing selected yet — add from below';

  @override
  String get curationAddButton => '+ Add';

  // ---- §30 D-2: Home dashboard section labels ----

  @override
  String get homeSectionMyPicks => 'My picks';

  @override
  String get homeSectionDashboard => 'Dashboard';

  @override
  String get homeSectionSettings => 'Settings';

  @override
  String get homeSectionUdhaar => 'Udhaar khaata';

  // ---- §31 D-2: Settings screen labels ----

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsShopInfo => 'Shop info';

  @override
  String get settingsTaglineHindi => 'Tagline (Hindi)';

  @override
  String get settingsGst => 'GST number';

  @override
  String get settingsWhatsapp => 'WhatsApp number';

  @override
  String get settingsBranding => 'Branding';

  @override
  String get settingsChangeGreeting => 'Change greeting message';

  @override
  String get settingsFeatures => 'Features';

  @override
  String get settingsDecisionCircle => 'Decision Circle (Family)';

  @override
  String get settingsRemoteConfigNote =>
      'Features are managed via Remote Config — contact Yugma Labs';

  @override
  String get settingsOperators => 'Operators';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsSaved => 'Settings saved';

  // ---- §32 D-10: Settings enhancements ----

  @override
  String get settingsColorPicker => 'Change shop color';

  @override
  String get settingsFaceUpload => 'Upload your photo';

  @override
  String get settingsAddOperator => 'Add operator';

  @override
  String get settingsRemoveOperator => 'Remove';
  @override
  String get settingsRemoveOperatorConfirm =>
      'Are you sure you want to remove this person? Their access will be revoked immediately.';

  // ---- §33 Customer Udhaar Screen ----

  @override
  String get udhaarScreenTitle => 'Udhaar Account';

  @override
  String get udhaarNoLedgers => 'No udhaar accounts yet';

  @override
  String get udhaarOpenLedgers => 'Open Udhaar';

  @override
  String get udhaarClosedLedgers => 'Closed Accounts';

  @override
  String get udhaarTotalBaaki => 'Total Remaining';

  @override
  String get udhaarSettledBadge => 'Settled';

  @override
  String get udhaarBaakiLabel => 'Remaining';

  @override
  String udhaarOpenAccountsCount(int count) => '$count open accounts';

  @override
  String get udhaarOriginalAmountPrefix => 'Original amount';

  @override
  String udhaarPartialPaymentCount(int count) =>
      '$count partial ${count == 1 ? 'payment' : 'payments'} made';

  @override
  String udhaarRemindersSentCount(int count) =>
      '$count ${count == 1 ? 'reminder' : 'reminders'} sent';

  // ---- §34 Persona Toggle ----

  @override
  String get personaSheetTitle => 'Who is browsing?';

  @override
  String get personaCustomLabelHint => 'Enter name';

  // ---- §35 Large Text Toggle ----

  @override
  String get largeTextToggleLabel => 'Large Text';

  // ---- §36 Presence Banner ----

  @override
  String presenceReturnBy(String time) => ', back by $time';

  @override
  String get presenceListenVoice => 'Listen to voice message';

  // ---- §37 Read Tracking ----

  @override
  String get readStatusSeen => 'Seen';

  @override
  String readStatusSeenByCount(int count) => 'Seen by $count people';

  // ---- §38 Shopkeeper Udhaar List ----

  @override
  String get shopUdhaarToggleOpen => 'Open';

  @override
  String get shopUdhaarToggleClosed => 'Closed';

  @override
  String get shopUdhaarNoOpen => 'No open udhaar accounts';

  @override
  String get shopUdhaarNoClosed => 'No closed accounts';

  // ---- §39 Shopkeeper Search ----

  @override
  String get searchHintOrders => 'Search — name, phone, amount';

  // ---- §40 Shopkeeper Inventory Voice ----

  @override
  String get voiceNoteButtonLabel => 'Voice Note';

  @override
  String get voiceNoteAttached => 'Voice note attached';

  // ---- §41 Payment success navigation ----

  @override
  String get paymentSuccessViewOrder => 'View Order';

  @override
  String get paymentSuccessBackHome => 'Back to Home';

}
