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
  // §5 — Commit + OTP + payment (UX Spec §5.5 #11–14)
  // =========================================================================

  /// "Confirm the order" commit button — "pakka" is stronger than confirm.
  String get commitButtonPakka;

  /// OTP framing — reframes OTP as shopkeeper-need, not app-distrust.
  /// Critical R12 mitigation copy.
  String get otpPromptBhaiyaNeedsIt;

  /// UPI primary payment button.
  String get upiPayButton;

  /// Payment success toast.
  String get paymentSuccessPakka;

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
}
