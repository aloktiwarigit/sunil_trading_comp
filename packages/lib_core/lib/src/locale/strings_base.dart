// =============================================================================
// AppStrings — the abstract interface for every user-facing string in the
// Yugma Dukaan customer + shopkeeper apps.
//
// Hindi is the source-of-truth language per Brief Constraint 4 + PRD I6.9.
// English is the derived translation for the Hindi toggle (or the default
// when Sprint 0 closes to END STATE B via the `defaultLocale` flag flip).
//
// **Domain grounding (from the three binding memory rules):**
//   - Every string in this interface has a counterpart in UX Spec v1.1 §5.5
//     — Sally's approved 50-string table of voice & tone examples.
//   - Domain-grounded enum naming: the methods reference `bhaiya`,
//     `shaadi`, `udhaar`, `pakka`, `baaki` — NOT generic e-commerce
//     vocabulary like `user`, `checkout`, `balance`, `confirm`.
//   - Forbidden vocabulary enforcement: no string in any implementation
//     may use udhaar lending terms (`interest / due date / penalty / loan /
//     default / collection / installment / EMI`) or mythic vocabulary
//     (`शुभ / मंगल / मंदिर / धर्म / तीर्थ / स्वागतम् / उत्पाद / गुणवत्ता / श्रेष्ठ`).
//     A dedicated test (`strings_forbidden_vocab_test.dart`) scans every
//     implementation's output on every PR.
//
// **Sprint 0 / Constraint 15 interaction:**
//   - This interface + `AppStringsHi` + `AppStringsEn` are infrastructure.
//     No user-visible screen consumes them yet in Phase 1.
//   - When Sprint 0 closes END STATE A (Hindi-native reviewer hired), the
//     reviewer does one pass over `AppStringsHi` and green-lights it.
//   - When Sprint 0 closes END STATE B (`defaultLocale` flipped to `en`),
//     the `LocaleResolver` starts returning `AppStringsEn` as default and
//     the Hindi toggle becomes opt-in. No code change required.
//
// Each method is a getter (no parameters) or a small method (with typed
// parameters) for parameterized strings. For maximum Flutter-analyzer
// friendliness and zero runtime overhead we use plain Dart string
// composition — no ICU MessageFormat, no intl_utils code generation. The
// `intl` package is in pubspec for future locale-aware formatting of
// dates / numbers / plurals, NOT for string message bundles.
// =============================================================================

/// Abstract interface that every locale implementation must satisfy.
///
/// To add a new string: add a getter or method to this class, then
/// implement it in BOTH [AppStringsHi] and [AppStringsEn]. A compilation
/// error in either file is the signal that a string is missing a
/// translation — the symmetry is enforced at compile time.
abstract class AppStrings {
  /// Create an instance. Constructor is const so each implementation can
  /// be a compile-time constant singleton.
  const AppStrings();

  /// The Dart locale code this implementation represents.
  /// Canonical: `hi` or `en`.
  String get localeCode;

  // =========================================================================
  // §1 — Landing, splash, and greeting (UX Spec §5.5 #1–2)
  // =========================================================================

  /// First-launch splash + app-bar title on the Bharosa landing.
  /// Example hi: `सुनील ट्रेडिंग कंपनी`
  /// Example en: `Sunil Trading Company`
  String get shopDisplayName;

  /// Label under the greeting voice-note player on the landing screen.
  /// Example hi: `सुनील भैया का स्वागत संदेश`
  String get greetingVoiceNoteLabel;

  // =========================================================================
  // §1b — Bharosa landing (Wave 0 mapping rows 3, 6, 8–11, 13)
  // =========================================================================

  /// Meta bar "X years · since YYYY" label.
  /// Example hi: `23 साल · 2003 से`
  String metaBarYearsInBusiness(int years, int establishedYear);

  /// Greeting card headline.
  /// Example hi: `नमस्ते जी, स्वागत है`
  String get greetingCardTitle;

  /// Greeting voice note sublabel with owner name and duration.
  /// Example hi: `सुनील भैय��� का स्वागत संदेश · 23 सेकंड`
  String greetingVoiceNoteSublabel(String ownerName, int seconds);

  /// Mute toggle tooltip — turn sound on.
  String get muteToggleOn;

  /// Mute toggle tooltip — mute.
  String get muteToggleMute;

  /// Shortlist preview section headline.
  /// Example hi: `���ुनील भैया की पसंद · आज के लिए`
  String shortlistPreviewHeadline(String ownerName);

  /// Badge on the first shortlist tile.
  String get shortlistBadgeCurated;

  /// Presence dock status — at the shop.
  String get presenceStatusAvailable;

  /// Meta bar map link label.
  String get metaBarMapLabel;

  // =========================================================================
  // §1c — Browse widgets (Wave 0 mapping — B1.4, B1.5)
  // =========================================================================

  /// "Sunil-bhaiya's pick" badge on curated shortlist cards.
  String get skuTopPickBadge;

  /// Negotiable indicator label.
  String get skuNegotiableLabel;

  /// Golden Hour toggle — switch BACK to beautiful view.
  String get goldenHourToggleBeautiful;

  /// Golden Hour capture screen title.
  String get goldenHourTitle;

  /// Golden Hour light guide instruction.
  String get goldenHourLightGuide;

  /// Golden Hour capture button label.
  String get goldenHourCaptureButton;

  /// Golden Hour hero photo tier label.
  String get goldenHourHeroLabel;

  /// Golden Hour working photo tier label.
  String get goldenHourWorkingLabel;

  /// Golden Hour retake button.
  String get goldenHourRetake;

  /// Golden Hour save button.
  String get goldenHourSave;

  // =========================================================================
  // §2 — Curated shortlists (UX Spec §5.5 #3–5)
  // =========================================================================

  /// Shortlist title — wedding occasion.
  String get shortlistTitleShaadi;

  /// Shortlist title — new home occasion.
  String get shortlistTitleNayaGhar;

  /// Shortlist title — replacement occasion.
  String get shortlistTitlePuranaBadlne;

  /// Shortlist title — dowry occasion.
  /// Not in UX Spec §5.5 explicit row but called out in PRD B1.4 AC #1.
  String get shortlistTitleDahej;

  /// Shortlist title — budget-friendly picks.
  /// Called out in PRD B1.4 AC #1.
  String get shortlistTitleBudget;

  /// Shortlist title — ladies category.
  /// Called out in PRD B1.4 AC #1.
  String get shortlistTitleLadies;

  // =========================================================================
  // §3 — SKU detail (UX Spec §5.5 #6–8)
  // =========================================================================

  /// SKU detail screen — "Add to my list" CTA.
  String get skuAddToList;

  /// SKU detail screen — "Talk to Sunil-bhaiya about this" CTA.
  String get skuTalkToBhaiya;

  /// Golden Hour photo "show real form" toggle.
  String get asliRoopToggle;

  // =========================================================================
  // §4 — Chat (UX Spec §5.5 #9–10)
  // =========================================================================

  /// Title of the Sunil-bhaiya Ka Kamra chat thread.
  String get chatThreadTitle;

  /// Chat input placeholder.
  String get chatInputPlaceholder;

  // =========================================================================
  // §4b — C3.1 + P2.4 + P2.5 Chat + Draft (Sprint 4)
  // =========================================================================

  /// Chat thread title with order suffix.
  /// Example hi: `सुनील भैया का कमरा — आपका ऑर्डर #abc123`
  String chatThreadTitleWithOrder(String suffix);

  /// "My list" title for the draft list screen.
  String get myListTitle;

  /// "Added to list" snackbar confirmation.
  String get addedToList;

  /// Chat sender label — the customer.
  String get chatSenderYou;

  /// Chat sender label — the shopkeeper.
  String get chatSenderBhaiya;

  /// Chat send button label.
  String get chatSendButton;

  /// Chat message pending / sending indicator.
  String get chatMessagePending;

  // =========================================================================
  // §4c — C3.2 Draft line item editing (Sprint 7)
  // =========================================================================

  /// Snackbar after swiping to remove a line item. Parameter: SKU name.
  /// Example hi: `रमेश-बहन हटाई गई`
  String draftItemRemoved(String skuName);

  /// Undo button on the remove snackbar.
  String get draftUndoRemove;

  /// Qty > 10 confirmation dialog title.
  String get draftQtyHighTitle;

  /// Qty > 10 confirmation dialog body. Parameters: quantity, SKU name.
  /// Example hi: `{name} {qty} चाहिए — पक्का?`
  String draftQtyHighBody(int qty, String skuName);

  /// Qty > 10 confirm button.
  String get draftQtyHighConfirm;

  /// Qty > 10 cancel button.
  String get draftQtyHighCancel;

  /// Total amount label shown at bottom of draft list.
  String get draftTotalLabel;

  // =========================================================================
  // §4d — C3.3 Negotiation flow (Sprint 7)
  // =========================================================================

  /// Price proposal bubble label — "Bhaiya's offer for {skuName}".
  String proposalBubbleLabel(String skuName);

  /// Proposed price line — "₹{amount}".
  String proposalPriceLine(int amount);

  /// "Accept" button on price proposal bubble.
  String get proposalAcceptButton;

  /// "Accepted" badge shown on an already-accepted proposal.
  String get proposalAcceptedBadge;

  /// System message when customer accepts a proposal.
  /// Example hi: `₹{amount} पर {skuName} पक्का ह���आ`
  String proposalAcceptedSystemMessage(int amount, String skuName);

  /// Original price strikethrough label on proposal bubble.
  String get proposalOriginalPriceLabel;

  // =========================================================================
  // §5 — Commit + OTP + payment (UX Spec §5.5 #11–14)
  // =========================================================================

  /// "Confirm the order" commit button — "pakka" is stronger than confirm.
  String get commitButtonPakka;

  /// OTP framing — reframes OTP as shopkeeper-need, not app-distrust.
  /// Critical R12 mitigation copy.
  String get otpPromptBhaiyaNeedsIt;

  /// Phone number input field label (C3.4 OTP flow).
  String get phoneInputLabel;

  /// OTP code input field label.
  String get otpCodeLabel;

  /// "Send OTP" button on phone input screen.
  String get otpSendButton;

  /// "Verify" button on OTP code entry screen.
  String get otpVerifyButton;

  /// Invalid OTP code error.
  String get otpInvalidCode;

  /// OTP code expired error.
  String get otpCodeExpired;

  /// OTP resend cooldown countdown text with remaining seconds.
  String otpResendCountdown(int seconds);

  /// Post-commit confirmation title.
  String get commitSuccessTitle;

  /// "Proceed to payment" CTA after commit.
  String get proceedToPayment;

  /// "Total amount" label on order summary.
  String get orderTotalLabel;

  /// Commit transaction failed error.
  String get commitFailed;

  /// UPI primary payment button.
  String get upiPayButton;

  /// "Other ways to pay" expandable link (C3.5 AC #1).
  String get paymentOtherMethods;

  /// "No UPI app found" error (C3.5 edge case #1).
  String get noUpiAppFound;

  /// "Payment processing" loading indicator.
  String get paymentProcessing;

  /// Payment success toast.
  String get paymentSuccessPakka;

  // ---- §5b C3.6 COD + C3.7 Bank transfer ----

  /// COD option label (C3.6 AC #1).
  String get codOption;

  /// COD confirmation note (C3.6 AC #2).
  String get codConfirmNote;

  /// COD confirm button.
  String get codConfirmButton;

  /// Bank transfer option label (C3.7 AC #1).
  String get bankTransferOption;

  /// "Mark as paid" self-report button (C3.7 AC #3).
  String get bankTransferMarkPaid;

  /// Bank account number label.
  String get bankAccountNumberLabel;

  /// IFSC label.
  String get bankIfscLabel;

  /// Account holder name label.
  String get bankAccountHolderLabel;

  /// Bank branch label.
  String get bankBranchLabel;

  /// Awaiting verification status message.
  String get awaitingVerificationMessage;

  // ---- §5c S4.6 Active projects list ----

  /// Orders tab title (S4.6).
  String get ordersTitle;

  /// Filter: All.
  String get filterAll;

  /// Filter: Committed.
  String get filterCommitted;

  /// Filter: Pending payment.
  String get filterPendingPayment;

  /// Filter: Delivering.
  String get filterDelivering;

  /// Filter: Closed.
  String get filterClosed;

  /// Empty orders placeholder (S4.6 edge case #3).
  String get emptyOrdersList;

  // =========================================================================
  // §6 — Udhaar khaata (UX Spec §5.5 #15–17, 29)
  // =========================================================================

  /// Udhaar proposal notification — shopkeeper has proposed a khaata.
  String get udhaarProposal;

  /// Udhaar balance display with parameter.
  /// Example hi: `सुनील भैया में बाकी: ₹{amount}` → `सुनील भैया में बाकी: ₹13,000`
  String udhaarBalance(int amount);

  /// Delivery confirmation — Sunil-bhaiya has delivered the order.
  String get deliveryConfirmed;

  /// Udhaar reminder push notification body with parameter.
  /// Example hi: `आपका खाता: सुनील भैया में ₹{amount} बाकी`
  String udhaarReminderPush(int amount);

  // =========================================================================
  // §7 — Empty states (UX Spec §5.5 #18–19, 27–28)
  // =========================================================================

  /// Empty draft / cart.
  String get emptyDraftList;

  /// No orders yet (new customer).
  String get noOrdersYet;

  /// Empty curated shortlist — shopkeeper hasn't curated yet.
  String get emptyShortlistNotYetCurated;

  /// Empty Decision Circle — only the primary user so far.
  String get emptyDecisionCircle;

  // =========================================================================
  // §8 — Error + connectivity states (UX Spec §5.5 #20–21, 25–26, 30)
  // =========================================================================

  /// No internet banner while browsing.
  String get noInternetShowingCached;

  /// Voice note / photo upload pending badge.
  String get uploadPending;

  /// Payment failed — honest, offers a path.
  String get paymentFailed;

  /// Voice note send failed — specific cause.
  String get voiceNoteSendFailed;

  /// Ops app sign-in error — operator not yet authorized.
  String get opsAppNotAuthorized;

  // =========================================================================
  // §9 — Absence presence (UX Spec §5.5 #22)
  // =========================================================================

  /// Away banner — shopkeeper is at a wedding / event.
  /// Static form; dynamic form can be customized by the shopkeeper in S4.14.
  String get awayBannerAtShaadi;

  // =========================================================================
  // §10 — Decision Circle persona toggle (UX Spec §5.5 #23–24)
  // =========================================================================

  /// Persona toggle default label — "I am looking" (male default).
  String get personaLabelIAmLooking;

  /// Persona toggle default label — "I am looking" (female form).
  String get personaLabelIAmLookingFemale;

  /// Persona toggle elder label — "Mummy-ji is looking."
  String get personaLabelMummyJi;

  // =========================================================================
  // §11 — B1.13 Devanagari receipt / invoice (UX Spec §5.5 #31–36)
  // =========================================================================

  /// Receipt footer thank-you line. The one permitted warmth-sentence.
  /// Per UX Spec §5.5 #31 + Brief §3 "plain dignified invoices".
  String get receiptThankYouFooter;

  /// "View receipt" button on Project detail.
  String get receiptOpenButton;

  /// Cancelled receipt diagonal watermark.
  String get receiptCancelledWatermark;

  /// Udhaar-open on receipt — remaining balance line.
  String receiptUdhaarBaaki(int amount);

  /// Missing customer display name fallback (Standing Rule 8).
  String get receiptCustomerFallback;

  // =========================================================================
  // §12 — C3.12 Shop deactivation (UX Spec §5.5 #37–40)
  // =========================================================================

  /// Shop deactivation banner (deactivating state) with retention days.
  /// Example hi: `सुनील भैया की दुकान बंद हो रही है — ... आपका डेटा {days} दिन तक सुरक्षित है`
  String shopDeactivatingBanner(int retentionDays);

  /// Shop deactivation banner (purge_scheduled state) with days-to-purge.
  String shopPurgeScheduledBanner(int daysUntilPurge);

  /// Shop deactivation FAQ screen title.
  String get shopDeactivationFaqTitle;

  /// Data-export CTA button (routes to B1.13 bundled receipt generation).
  String get dataExportCta;

  // =========================================================================
  // §13 — S4.17 NPS card (UX Spec §5.5 #41–43)
  // =========================================================================

  /// NPS card headline — casual register per party mode F-P3 finding.
  String get npsCardHeadline;

  /// NPS optional textarea prompt.
  String get npsOptionalPrompt;

  /// NPS snooze button.
  String get npsSnoozeLater;

  // =========================================================================
  // §14 — S4.19 Shop closure (UX Spec §5.5 #44–45)
  // =========================================================================

  /// Shop-closure option in ops app Settings (bhaiya-only).
  String get shopClosureSettingsOption;

  /// 24-hour reversibility footer on the 3rd tap.
  String get shopClosureReversibilityFooter;

  // =========================================================================
  // §15 — S4.16 Media spend tile (UX Spec §5.5 #46–47)
  // =========================================================================

  /// Media spend dashboard tile label.
  String get mediaSpendTileLabel;

  /// Cloudinary exhausted red-alt banner — R2 active.
  String get cloudinaryExhaustedR2Active;

  // =========================================================================
  // §16 — S4.10 Udhaar reminder affordances (UX Spec §5.5 #48–50)
  // =========================================================================

  /// Per-ledger reminder opt-in toggle — bhaiya-authored question.
  String get udhaarReminderOptInPrompt;

  /// Reminder count badge with parameter — "Reminded: {count}/3".
  String udhaarReminderCountBadge(int count);

  /// Cadence stepper label.
  String get udhaarReminderCadencePrompt;

  // =========================================================================
  // §17 — S4.1 + S4.13 Ops app foundation (Sprint 3)
  // =========================================================================

  /// Google sign-in button label.
  String get signInWithGoogle;

  /// "Today's task" card title.
  String get todaysTaskTitle;

  /// "Done" button on today's task card.
  String get todaysTaskDone;

  /// "Hide" dismiss label for today's task card.
  String get todaysTaskDismiss;

  /// Time estimate with minutes parameter.
  String todaysTaskMinutes(int n);

  /// Sign-out label in ops app settings.
  String get signOutLabel;

  /// Ops app dashboard title.
  String get opsDashboardTitle;

  /// Day 30 celebration message.
  String get todaysTaskDay30Celebration;

  /// Permission-revoked banner (operator doc deleted while signed in).
  String get opsPermissionRevoked;

  // =========================================================================
  // §18 — S4.3 Inventory SKU creation (Sprint 4)
  // =========================================================================

  String get inventoryTitle;
  String get createSkuButton;
  String get skuNameDevanagariLabel;
  String get skuNameEnglishLabel;
  String get skuCategoryLabel;
  String get skuBasePriceLabel;
  String get skuNegotiableFloorLabel;
  String get skuDimensionsLabel;
  String get skuMaterialLabel;
  String get skuInStockLabel;
  String get skuDescriptionLabel;
  String get skuSaveButton;
  String get skuGoldenHourPhotoButton;
  String get skuSaveBeforePhoto;
  String get skuStockCountLabel;
  String get skuDuplicateNameWarning;
  String get skuSavedSuccess;
  String get validationRequired;
  String get validationPricePositive;
  String get validationFloorExceedsBase;
  String get validationDimensionPositive;
  String get inventoryEmpty;

  // =========================================================================
  // §19 — S4.7 Project detail (Sprint 8)
  // =========================================================================

  /// Project detail screen title.
  String get projectDetailTitle;

  /// "Line items" section header.
  String get lineItemsHeader;

  /// "Customer info" section header.
  String get customerInfoHeader;

  /// "New customer" placeholder when no memory exists (Edge #1).
  String get newCustomerPlaceholder;

  /// "Chat" section header with message count.
  String chatPreviewHeader(int count);

  /// "Send message" action button.
  String get sendMessageButton;

  /// "Mark delivered" action button.
  String get markDeliveredButton;

  /// "Cancel order" action button.
  String get cancelOrderButton;

  /// "Negotiating" state badge label.
  String get filterNegotiating;

  // =========================================================================
  // §20 — S4.8 Shopkeeper chat reply (Sprint 8)
  // =========================================================================

  /// "Propose price" button label in shopkeeper chat.
  String get proposePriceButton;

  /// "For which item?" prompt in price proposal flow.
  String get proposalSelectItemPrompt;

  /// "Your price" input label in price proposal flow.
  String get proposalPriceInputLabel;

  /// "Send proposal" button.
  String get proposalSendButton;

  /// Proposal sent confirmation.
  String get proposalSentConfirmation;

  // =========================================================================
  // §21 — S4.4 Inventory edit (Sprint 8)
  // =========================================================================

  /// "Edit item" screen title.
  String get editSkuTitle;

  /// "Save changes" button.
  String get skuSaveChangesButton;

  /// "Changes saved" success toast.
  String get skuChangesSaved;

  /// "Stock" quick-adjust label.
  String get skuStockAdjustLabel;

  // =========================================================================
  // §22 — C3.8 + C3.9 Udhaar khaata flow (Sprint 9)
  // =========================================================================

  /// "Start udhaar khaata" button on project detail.
  String get udhaarStartButton;

  /// "How much will they pay today?" dialog label.
  String get udhaarTodayPaymentLabel;

  /// "Running balance" dialog label.
  String get udhaarBalanceLabel;

  /// "Confirm" button on udhaar initiation dialog.
  String get udhaarConfirmButton;

  /// Udhaar created success toast.
  String get udhaarCreatedSuccess;

  /// "Accept" button on customer-side udhaar proposal.
  String get udhaarAcceptButton;

  /// "Decline" button on customer-side udhaar proposal.
  String get udhaarDeclineButton;

  /// Udhaar accepted confirmation.
  String get udhaarAcceptedConfirmation;

  /// "Record payment" button on udhaar ledger view.
  String get udhaarRecordPaymentButton;

  /// "Amount paid" input label.
  String get udhaarAmountPaidLabel;

  /// "Payment method" input label.
  String get udhaarPaymentMethodLabel;

  /// Payment recorded success toast.
  String get udhaarPaymentRecordedSuccess;

  /// "Ledger closed" — balance reached zero.
  String get udhaarLedgerClosed;

  /// Overpayment error.
  String get udhaarOverpaymentError;

  // =========================================================================
  // §23 — S4.9 Customer memory editing (Sprint 11)
  // =========================================================================

  /// "Edit memory" button on customer info card.
  String get memoryEditButton;

  /// Memory sheet title.
  String get memorySheetTitle;

  /// "Notes" field label.
  String get memoryNotesLabel;

  /// "Relationship notes" field label.
  String get memoryRelationshipLabel;

  /// "Preferred occasions" field label.
  String get memoryOccasionsLabel;

  /// "Price range" field label.
  String get memoryPriceRangeLabel;

  /// "Min price" field label.
  String get memoryPriceMinLabel;

  /// "Max price" field label.
  String get memoryPriceMaxLabel;

  /// Auto-saved confirmation.
  String get memorySaved;

  /// "New customer — first time" placeholder (B1.11 edge #2).
  String get memoryNewCustomerPlaceholder;

  // =========================================================================
  // §24 — D-2: Order detail timeline labels (hardcoded Devanagari migration)
  // =========================================================================

  /// Items count label for order card/detail. "X सामान"
  String orderItemCount(int count);

  /// "Status" section header on order detail.
  String get orderStatusLabel;

  /// "Download receipt" button label.
  String get orderDownloadReceipt;

  /// Timeline: committed state.
  String get timelineCommitted;

  /// Timeline: udhaar khaata started.
  String get timelineUdhaarStarted;

  /// Timeline: paid.
  String get timelinePaid;

  /// Timeline: bank transfer awaiting verification.
  String get timelineBankTransferPending;

  /// Timeline: delivering.
  String get timelineDelivering;

  /// Timeline: delivered.
  String get timelineDelivered;

  /// Timeline: closed.
  String get timelineClosed;

  /// Timeline: cancelled.
  String get timelineCancelled;

  /// Timeline: draft state.
  String get timelineDraft;

  /// Receipt generating snackbar.
  String get receiptGenerating;

  /// Receipt share subject with project ID.
  String receiptShareSubject(String projectId);

  /// Receipt generation error with detail.
  String receiptGenerationError(String detail);

  /// Month name by number (1–12).
  String monthName(int month);

  // =========================================================================
  // §25 — D-2: Order list state badge labels
  // =========================================================================

  /// State badge: draft.
  String get stateBadgeDraft;

  /// State badge: negotiating.
  String get stateBadgeNegotiating;

  /// State badge: committed.
  String get stateBadgeCommitted;

  /// State badge: paid.
  String get stateBadgePaid;

  /// State badge: delivering.
  String get stateBadgeDelivering;

  /// State badge: awaiting verification.
  String get stateBadgeAwaitingVerification;

  /// State badge: closed.
  String get stateBadgeClosed;

  /// State badge: cancelled.
  String get stateBadgeCancelled;

  // =========================================================================
  // §26 — D-2: Analytics dashboard labels
  // =========================================================================

  /// "Orders" metric label.
  String get analyticsOrders;

  /// "Revenue" metric label.
  String get analyticsRevenue;

  /// "Open orders" metric label.
  String get analyticsOpenOrders;

  /// "Udhaar pending" metric label.
  String get analyticsUdhaarPending;

  /// "New customers" metric label.
  String get analyticsNewCustomers;

  /// "Last 7 days" period label.
  String get analyticsLast7Days;

  /// "No orders yet" empty state for analytics.
  String get analyticsNoOrdersYet;

  // =========================================================================
  // §27 — D-2: Voice recorder widget labels
  // =========================================================================

  /// Microphone permission needed message.
  String get micPermissionNeeded;

  /// "Go back" button label.
  String get voiceGoBack;

  /// "At least 5 seconds" minimum duration warning.
  String get voiceMinDuration;

  /// "Recording..." in-progress label.
  String get voiceRecordingInProgress;

  /// "Cancel" button on recorder.
  String get voiceCancel;

  /// "Re-record" button label.
  String get voiceReRecord;

  /// Short "Cancel" for compact UI.
  String get voiceCancelShort;

  // =========================================================================
  // §28 — D-2: Presence toggle screen labels
  // =========================================================================

  /// Status: at the shop.
  String get presenceAtShop;

  /// Status: away.
  String get presenceAway;

  /// Status: busy with customer.
  String get presenceBusyWithCustomer;

  /// Status: at wedding/event.
  String get presenceAtEvent;

  /// "My availability" screen title.
  String get presenceMyAvailability;

  /// "When will you be back?" prompt.
  String get presenceReturnTimePrompt;

  /// Default return time "6 PM".
  String get presenceReturnTimeDefault;

  /// "Let the customer hear your voice" prompt.
  String get presenceVoicePrompt;

  /// "Voice recorded — X seconds" confirmation.
  String presenceVoiceRecorded(int seconds);

  /// "Remove" voice note button.
  String get presenceRemoveVoice;

  /// "Update" button.
  String get presenceUpdateButton;

  /// "Availability updated" confirmation.
  String get presenceUpdated;

  // =========================================================================
  // §29 — D-2: Curation screen labels
  // =========================================================================

  /// "My picks" curation screen title.
  String get curationMyPicks;

  /// Empty state: "Nothing selected yet — add from below".
  String get curationEmptyPrompt;

  /// "+ Add" button.
  String get curationAddButton;

  // =========================================================================
  // §30 — D-2: Home dashboard section labels
  // =========================================================================

  /// "My picks" section label on home dashboard.
  String get homeSectionMyPicks;

  /// "Dashboard" section label on home.
  String get homeSectionDashboard;

  /// "Settings" section label.
  String get homeSectionSettings;

  /// "Udhaar khaata" section label.
  String get homeSectionUdhaar;

  // =========================================================================
  // §31 — D-2: Settings screen labels
  // =========================================================================

  /// "Settings" screen title.
  String get settingsTitle;

  /// "Shop info" section header.
  String get settingsShopInfo;

  /// "Tagline (Hindi)" field label.
  String get settingsTaglineHindi;

  /// "GST number" field label.
  String get settingsGst;

  /// "WhatsApp number" field label.
  String get settingsWhatsapp;

  /// "Branding" section header.
  String get settingsBranding;

  /// "Change greeting message" action label.
  String get settingsChangeGreeting;

  /// "Features" section header.
  String get settingsFeatures;

  /// "Decision Circle (family)" feature label.
  String get settingsDecisionCircle;

  /// Remote Config info note.
  String get settingsRemoteConfigNote;

  /// "Operators" section header.
  String get settingsOperators;

  /// "Save" button label.
  String get settingsSave;

  /// "Settings saved" confirmation.
  String get settingsSaved;

  // =========================================================================
  // §32 — D-10: Settings enhancements
  // =========================================================================

  /// "Shop color" picker tile label.
  String get settingsColorPicker;

  /// "Face photo" upload tile label.
  String get settingsFaceUpload;

  /// "Add operator" button.
  String get settingsAddOperator;

  /// "Remove" operator button.
  String get settingsRemoveOperator;

  /// Confirmation message for removing an operator.
  String get settingsRemoveOperatorConfirm;

  // =========================================================================
  // §33 — Customer Udhaar Screen
  // =========================================================================

  /// Screen title: "उधार खाता"
  String get udhaarScreenTitle;

  /// Empty state: "अभी कोई उधार खाता नहीं है"
  String get udhaarNoLedgers;

  /// Open ledgers tab header: "चालू उधार"
  String get udhaarOpenLedgers;

  /// Closed ledgers tab header: "बंद हुए खाते"
  String get udhaarClosedLedgers;

  /// Summary label: "कुल बाकी"
  String get udhaarTotalBaaki;

  /// Settled badge: "चुकता"
  String get udhaarSettledBadge;

  /// Remaining balance label: "बाकी"
  String get udhaarBaakiLabel;

  /// Open accounts count: "N चालू खाते"
  String udhaarOpenAccountsCount(int count);

  /// Original amount prefix: "मूल राशि: ₹..."
  String get udhaarOriginalAmountPrefix;

  /// Partial payments count: "N किस्त चुकाई"
  String udhaarPartialPaymentCount(int count);

  /// Reminders sent count: "N रिमाइंडर भेजे गए"
  String udhaarRemindersSentCount(int count);

  // =========================================================================
  // §34 — Persona Toggle
  // =========================================================================

  /// Sheet title: "कौन देख रहा है?"
  String get personaSheetTitle;

  /// Custom label hint: "नाम लिखिए"
  String get personaCustomLabelHint;

  // =========================================================================
  // §35 — Large Text Toggle
  // =========================================================================

  /// Toggle label: "बड़ा अक्षर"
  String get largeTextToggleLabel;

  // =========================================================================
  // §36 — Presence Banner
  // =========================================================================

  /// Return time suffix: ", [time] तक वापस"
  String presenceReturnBy(String time);

  /// Voice button tooltip: "आवाज़ सुनिए"
  String get presenceListenVoice;

  // =========================================================================
  // §37 — Read Tracking
  // =========================================================================

  /// Seen label: "देखा गया"
  String get readStatusSeen;

  /// Seen by count: "देखा गया · N लोग"
  String readStatusSeenByCount(int count);

  // =========================================================================
  // §38 — Shopkeeper Udhaar List
  // =========================================================================

  /// Toggle label for open ledgers: "खुले"
  String get shopUdhaarToggleOpen;

  /// Toggle label for closed ledgers: "बंद"
  String get shopUdhaarToggleClosed;

  /// Empty state for open ledgers: "कोई खुला उधार खाता नहीं"
  String get shopUdhaarNoOpen;

  /// Empty state for closed ledgers: "कोई बंद खाता नहीं"
  String get shopUdhaarNoClosed;

  // =========================================================================
  // §39 — Shopkeeper Search
  // =========================================================================

  /// Search hint for orders: "खोजें — नाम, फ़ोन, रकम"
  String get searchHintOrders;

  // =========================================================================
  // §40 — Shopkeeper Inventory Voice
  // =========================================================================

  /// Voice note button label: "🎤 आवाज़ नोट"
  String get voiceNoteButtonLabel;

  /// Voice note attached snackbar: "आवाज़ नोट जुड़ गया"
  String get voiceNoteAttached;
}
