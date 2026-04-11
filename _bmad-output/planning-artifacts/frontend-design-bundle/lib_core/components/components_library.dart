// lib_core/src/components/components_library.dart
//
// Yugma Dukaan Component Library — consolidated reference implementation
//
// This file contains the remaining 12 widgets from the design system in
// a single consolidated reference. In production, each widget will be
// extracted into its own file under lib_core/src/components/. They are
// kept together here for handoff readability — Amelia can extract them
// into the proper file structure as she imports them.
//
// Component inventory:
//   1. CuratedShortlistCard
//   2. SkuDetailCard
//   3. ChatBubble (Sunil-bhaiya Ka Kamra balance-scale layout)
//   4. VoiceNotePlayer (waveform inline player)
//   5. ProjectStateTimeline
//   6. UdhaarLedgerCard (forbidden vocabulary excluded)
//   7. PersonaToggle (Decision Circle Guest Mode)
//   8. ElderTierWrapper
//   9. AbsencePresenceBanner
//   10. HindiTextField (Devanagari-optimized input)
//   11. UpiPayButton
//   12. GoldenHourPhotoView
//
// All components consume YugmaThemeExtension via context.yugmaTheme — no
// hardcoded colors, no hardcoded fonts. Each is multi-tenant safe.

import 'package:flutter/material.dart';
import '../theme/yugma_theme_extension.dart';
import '../theme/tokens.dart';

// ═════════════════════════════════════════════════════════════════
// 1. CURATED SHORTLIST CARD
// ═════════════════════════════════════════════════════════════════
//
// Renders a single SKU within a curated shortlist. Per Sally's UX Spec
// §4.3, shortlists are FINITE not paginated — these cards live in a
// vertical scroll with no "load more" CTA at the bottom.

class CuratedShortlistCard extends StatelessWidget {
  final String nameDevanagari;
  final String nameEnglish;
  final String materialLabel; // e.g., "स्टील"
  final String dimensionsLabel; // e.g., "5 ft"
  final int priceInr;
  final bool negotiable;
  final String? thumbnailUrl;
  final bool isShopkeepersTopPick;
  final VoidCallback onTap;

  const CuratedShortlistCard({
    super.key,
    required this.nameDevanagari,
    required this.nameEnglish,
    required this.materialLabel,
    required this.dimensionsLabel,
    required this.priceInr,
    required this.negotiable,
    required this.thumbnailUrl,
    required this.isShopkeepersTopPick,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: theme.shopSurface,
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            border: Border.all(color: theme.shopDivider),
            boxShadow: YugmaShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail with optional "top pick" badge
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.shopSecondary,
                            theme.shopPrimaryDeep,
                          ],
                        ),
                      ),
                      child: thumbnailUrl != null
                          ? Image.network(thumbnailUrl!, fit: BoxFit.cover)
                          : Center(
                              child: Icon(
                                Icons.rectangle_outlined,
                                color: theme.shopAccentGlow,
                                size: 36,
                              ),
                            ),
                    ),
                    if (isShopkeepersTopPick)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.shopAccent,
                            borderRadius:
                                BorderRadius.circular(YugmaRadius.sm),
                          ),
                          child: Text(
                            'सुनील भैया की पसंद',
                            style: TextStyle(
                              fontFamily: theme.fontFamilyDevanagariBody,
                              fontSize: 9,
                              color: theme.shopPrimaryDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(YugmaSpacing.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameDevanagari,
                              style: TextStyle(
                                fontFamily:
                                    theme.fontFamilyDevanagariDisplay,
                                fontSize: theme.isElderTier ? 18 : 15,
                                color: theme.shopTextPrimary,
                                height: YugmaLineHeights.snug,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              nameEnglish,
                              style: TextStyle(
                                fontFamily: theme.fontFamilyEnglishDisplay,
                                fontSize: theme.isElderTier ? 13 : 11,
                                fontStyle: FontStyle.italic,
                                color: theme.shopTextMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$materialLabel · $dimensionsLabel',
                              style: TextStyle(
                                fontFamily: theme.fontFamilyDevanagariBody,
                                fontSize: theme.isElderTier ? 13 : 11,
                                color: theme.shopTextMuted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${_formatInr(priceInr)}',
                              style: TextStyle(
                                fontFamily: YugmaFonts.mono,
                                fontSize: theme.isElderTier ? 19 : 16,
                                fontWeight: FontWeight.w600,
                                color: theme.shopPrimary,
                              ),
                            ),
                            if (negotiable) ...[
                              const SizedBox(width: 4),
                              Text(
                                'मोल भाव',
                                style: TextStyle(
                                  fontFamily: theme.fontFamilyDevanagariBody,
                                  fontSize: 10,
                                  color: theme.shopAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatInr(int amount) {
    // Indian number system: 17,500 not 17500
    final s = amount.toString();
    if (s.length <= 3) return s;
    if (s.length <= 5) return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    final last3 = s.substring(s.length - 3);
    final mid = s.substring(s.length - 5, s.length - 3);
    final rest = s.substring(0, s.length - 5);
    return '$rest,$mid,$last3';
  }
}

// ═════════════════════════════════════════════════════════════════
// 3. CHAT BUBBLE — Sunil-bhaiya Ka Kamra balance scale
// ═════════════════════════════════════════════════════════════════
//
// Per the design rationale: customer messages float left, shopkeeper
// messages float right, a brass-colored vertical thread runs down the
// center of the scroll. Visualizes the relationship as a balance scale
// rather than an SMS-style monologue.
//
// Maps to PRD P2.4, P2.5, P2.6, B1.7

enum ChatBubbleType { text, voiceNote, image, system, priceProposal }
enum ChatBubbleAuthor { customer, shopkeeper }

class ChatBubble extends StatelessWidget {
  final ChatBubbleType type;
  final ChatBubbleAuthor author;
  final String? textBody;
  final String? voiceNoteUrl;
  final int? voiceNoteDurationSeconds;
  final String? imageUrl;
  final String? systemNote;
  final int? priceProposalAmount;
  final String? priceProposalLineItemName;
  final DateTime sentAt;
  final bool seenByOtherSide;

  const ChatBubble({
    super.key,
    required this.type,
    required this.author,
    this.textBody,
    this.voiceNoteUrl,
    this.voiceNoteDurationSeconds,
    this.imageUrl,
    this.systemNote,
    this.priceProposalAmount,
    this.priceProposalLineItemName,
    required this.sentAt,
    required this.seenByOtherSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final isShopkeeper = author == ChatBubbleAuthor.shopkeeper;
    final maxBubbleWidth =
        MediaQuery.of(context).size.width * (theme.isElderTier ? 0.85 : 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s3,
        vertical: YugmaSpacing.s2,
      ),
      child: Align(
        alignment:
            isShopkeeper ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Column(
            crossAxisAlignment: isShopkeeper
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Sender label (shopkeeper only — customer doesn't need it)
              if (isShopkeeper)
                Padding(
                  padding: const EdgeInsets.only(
                    right: YugmaSpacing.s2,
                    bottom: 2,
                  ),
                  child: Text(
                    theme.ownerName,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyEnglishDisplay,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: theme.shopAccent,
                    ),
                  ),
                ),
              // Bubble
              Container(
                padding: const EdgeInsets.all(YugmaSpacing.s3),
                decoration: BoxDecoration(
                  color: isShopkeeper
                      ? theme.shopPrimary
                      : theme.shopBackgroundWarmer,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(YugmaRadius.lg),
                    topRight: const Radius.circular(YugmaRadius.lg),
                    bottomLeft: Radius.circular(
                        isShopkeeper ? YugmaRadius.lg : 4),
                    bottomRight: Radius.circular(
                        isShopkeeper ? 4 : YugmaRadius.lg),
                  ),
                  border: Border.all(
                    color: isShopkeeper
                        ? Colors.transparent
                        : theme.shopDivider,
                  ),
                  boxShadow: YugmaShadows.card,
                ),
                child: _buildBody(context, theme, isShopkeeper),
              ),
              // Timestamp + seen indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: YugmaSpacing.s2,
                  vertical: 4,
                ),
                child: Text(
                  '${_formatTime(sentAt)}${seenByOtherSide ? ' · seen ✓' : ''}',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: 9,
                    color: theme.shopTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, YugmaThemeExtension theme, bool isShopkeeper) {
    switch (type) {
      case ChatBubbleType.text:
        return Text(
          textBody ?? '',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: theme.isElderTier ? 17 : 13,
            height: YugmaLineHeights.normal,
            color: isShopkeeper
                ? theme.shopTextOnPrimary
                : theme.shopTextPrimary,
          ),
        );
      case ChatBubbleType.voiceNote:
        return VoiceNotePlayer(
          durationSeconds: voiceNoteDurationSeconds ?? 0,
          isOnPrimary: isShopkeeper,
        );
      case ChatBubbleType.priceProposal:
        return _buildPriceProposal(theme, isShopkeeper);
      case ChatBubbleType.system:
        return Text(
          systemNote ?? '',
          style: TextStyle(
            fontFamily: theme.fontFamilyEnglishDisplay,
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: theme.shopTextMuted,
          ),
        );
      case ChatBubbleType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(YugmaRadius.md),
          child: Image.network(imageUrl ?? '', fit: BoxFit.cover),
        );
    }
  }

  Widget _buildPriceProposal(
      YugmaThemeExtension theme, bool isShopkeeper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceProposalLineItemName ?? '',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 12,
            color: isShopkeeper
                ? theme.shopTextOnPrimary.withOpacity(0.85)
                : theme.shopTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${priceProposalAmount ?? 0}',
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isShopkeeper
                ? theme.shopAccentGlow
                : theme.shopPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ═════════════════════════════════════════════════════════════════
// 4. VOICE NOTE PLAYER — waveform inline
// ═════════════════════════════════════════════════════════════════
//
// Bars instead of progress bar — feels organic, not SaaS-y.
// Persona-aware volume per PRD P2.3: louder default in elder tier.

class VoiceNotePlayer extends StatefulWidget {
  final int durationSeconds;
  final bool isOnPrimary; // true if rendered on a dark/primary background

  const VoiceNotePlayer({
    super.key,
    required this.durationSeconds,
    this.isOnPrimary = false,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final accentColor =
        widget.isOnPrimary ? theme.shopAccentGlow : theme.shopAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: accentColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => setState(() => _playing = !_playing),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                _playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: theme.shopPrimaryDeep,
                size: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: YugmaSpacing.s2),
        // Waveform bars
        SizedBox(
          width: 120,
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(14, (i) {
              // Pseudo-random heights for the waveform aesthetic
              final heights = [8, 14, 18, 22, 16, 12, 20, 14, 18, 10, 16, 22, 12, 8];
              return Container(
                width: 3,
                height: heights[i].toDouble(),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: YugmaSpacing.s2),
        Text(
          '0:${widget.durationSeconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: 9,
            color: widget.isOnPrimary
                ? theme.shopTextOnPrimary.withOpacity(0.7)
                : theme.shopTextMuted,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 5. PROJECT STATE TIMELINE
// ═════════════════════════════════════════════════════════════════

enum ProjectState {
  draft,
  committed,
  paid,
  preparing,
  inPolish,
  dispatched,
  delivered,
  closed,
}

class ProjectStateTimeline extends StatelessWidget {
  final ProjectState currentState;
  final Map<ProjectState, DateTime> stateTimestamps;

  const ProjectStateTimeline({
    super.key,
    required this.currentState,
    required this.stateTimestamps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final orderedStates = [
      (ProjectState.committed, 'पुष्टि की गयी'),
      (ProjectState.paid, 'भुगतान हुआ'),
      (ProjectState.preparing, 'तैयार हो रहा है'),
      (ProjectState.inPolish, 'पॉलिश में है'),
      (ProjectState.dispatched, 'रवाना हुआ'),
      (ProjectState.delivered, 'डिलीवर हुआ'),
      (ProjectState.closed, 'बंद हुआ'),
    ];

    return Column(
      children: orderedStates.asMap().entries.map((entry) {
        final i = entry.key;
        final (state, label) = entry.value;
        final isCompleted = currentState.index >= state.index;
        final isLast = i == orderedStates.length - 1;
        final timestamp = stateTimestamps[state];

        return _TimelineRow(
          theme: theme,
          state: state,
          label: label,
          isCompleted: isCompleted,
          isLast: isLast,
          timestamp: timestamp,
          isCurrent: state == currentState,
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final YugmaThemeExtension theme;
  final ProjectState state;
  final String label;
  final bool isCompleted;
  final bool isLast;
  final DateTime? timestamp;
  final bool isCurrent;

  const _TimelineRow({
    required this.theme,
    required this.state,
    required this.label,
    required this.isCompleted,
    required this.isLast,
    required this.timestamp,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? theme.shopAccent
                      : theme.shopBackground,
                  border: Border.all(
                    color: isCompleted
                        ? theme.shopAccent
                        : theme.shopDivider,
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        isCurrent ? Icons.circle : Icons.check,
                        size: 10,
                        color: theme.shopPrimaryDeep,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: isCompleted
                        ? theme.shopAccent
                        : theme.shopDivider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: YugmaSpacing.s3),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: YugmaSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: theme.isElderTier ? 17 : 14,
                      color: isCompleted
                          ? theme.shopTextPrimary
                          : theme.shopTextMuted,
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatRelativeDate(timestamp!),
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: 10,
                          color: theme.shopTextMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime t) {
    return '${t.day} अप्रैल · ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

// ═════════════════════════════════════════════════════════════════
// 6. UDHAAR LEDGER CARD — accounting mirror, FORBIDDEN VOCABULARY EXCLUDED
// ═════════════════════════════════════════════════════════════════
//
// Per ADR-010, this widget MUST NOT use any of these field names or labels:
//   interest, interestRate, overdueFee, dueDate, lendingTerms,
//   borrowerObligation, defaultStatus, collectionAttempt
//
// The vocabulary used here is intentionally accounting-mirror only:
//   recordedAmount, partialPaymentReferences, runningBalance, closedAt
//
// Sally's UX Spec §5.6 has the full forbidden list and recommends a
// CI lint to enforce it. This widget honors the spec.

class UdhaarLedgerCard extends StatelessWidget {
  final String customerDisplayName;
  final int recordedAmountInr;
  final int runningBalanceInr;
  final List<UdhaarPayment> partialPaymentReferences;
  final DateTime initiatedAt;
  final DateTime? closedAt;

  // ─── v1.1 S4.10 reminder affordances (UX Spec §4.16, §6.11 #63–#65) ──
  //
  // These three fields are OPERATOR-owned per SAD v1.0.4 §9 partition.
  // A customer-side offline replay must NEVER be able to write them —
  // I6.12 sealed-union discipline keeps them out of any ProjectCustomerPatch.
  // The widget is render-only; toggle and stepper callbacks route writes
  // through the OperatorLedgerRepository which enforces the partition.

  /// Per-ledger opt-in. Default OFF. Affirmative-tap required per R10.
  final bool reminderOptIn;

  /// Lifetime reminder count, hard-capped at 3.
  /// Badge turns amber-neutral at 3/3 — informational cap, NOT a shame state.
  final int reminderCountLifetime;

  /// Cadence in days. Range 7–30, default 14.
  final int reminderCadenceDays;

  /// Shop lifecycle awareness — when the parent Shop is not `active`, the
  /// card transitions to a `रुका हुआ` (paused) read-only state per UX Spec
  /// §6.7 state #47. No reminders fire. No "collect now" CTA. R10 locked.
  final bool isFrozenByShopLifecycle;

  /// Toggles the opt-in. Returns the new value so the caller can surface
  /// the 3-second undo micro-toast (AE F8 patch, state #63). This widget
  /// does NOT own the toast — the host screen does.
  final ValueChanged<bool>? onReminderOptInChanged;

  /// Cadence stepper change handler.
  final ValueChanged<int>? onReminderCadenceChanged;

  /// Optional expansion — when true, the cadence stepper is visible.
  final bool expanded;
  final VoidCallback? onToggleExpanded;

  const UdhaarLedgerCard({
    super.key,
    required this.customerDisplayName,
    required this.recordedAmountInr,
    required this.runningBalanceInr,
    required this.partialPaymentReferences,
    required this.initiatedAt,
    required this.closedAt,
    // v1.1 additions — defaults keep the widget backward-compatible.
    this.reminderOptIn = false,
    this.reminderCountLifetime = 0,
    this.reminderCadenceDays = 14,
    this.isFrozenByShopLifecycle = false,
    this.onReminderOptInChanged,
    this.onReminderCadenceChanged,
    this.expanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final isClosed = closedAt != null;
    final progressPct = recordedAmountInr == 0
        ? 0.0
        : (recordedAmountInr - runningBalanceInr) / recordedAmountInr;

    return Container(
      margin: const EdgeInsets.all(YugmaSpacing.s4),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border(
          left: BorderSide(
            color: isClosed ? theme.shopAccent : theme.shopCommit,
            width: 4,
          ),
        ),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — customer name + closed badge if applicable
          Row(
            children: [
              Expanded(
                child: Text(
                  customerDisplayName,
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 18 : 15,
                    color: theme.shopPrimary,
                  ),
                ),
              ),
              if (isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: YugmaSpacing.s2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.shopAccent,
                    borderRadius: BorderRadius.circular(YugmaRadius.sm),
                  ),
                  child: Text(
                    'पूरा हो गया',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.shopPrimaryDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s3),

          // Progress bar (custom, brass-toned)
          ClipRRect(
            borderRadius: BorderRadius.circular(YugmaRadius.sm),
            child: LinearProgressIndicator(
              value: progressPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.shopBackgroundWarmer,
              valueColor: AlwaysStoppedAnimation(
                isClosed ? theme.shopAccent : theme.shopCommit,
              ),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),

          // Amount summary — uses ONLY allowed field labels
          Row(
            children: [
              _AmountColumn(
                theme: theme,
                label: 'कुल राशि', // total recorded amount
                amount: recordedAmountInr,
                color: theme.shopTextSecondary,
              ),
              const SizedBox(width: YugmaSpacing.s4),
              _AmountColumn(
                theme: theme,
                label: 'बाकी', // remaining balance
                amount: runningBalanceInr,
                color: isClosed ? theme.shopAccent : theme.shopCommit,
                emphasized: true,
              ),
            ],
          ),

          // ─── v1.1 S4.10 reminder affordances ───────────────────────
          // Shown only on OPEN ledgers (i.e., isClosed == false) and
          // suppressed entirely when the Shop is frozen by lifecycle.
          if (!isClosed && !isFrozenByShopLifecycle) ...[
            const SizedBox(height: YugmaSpacing.s3),
            _UdhaarReminderOptInRow(
              theme: theme,
              optIn: reminderOptIn,
              reminderCount: reminderCountLifetime,
              onChanged: onReminderOptInChanged,
              onToggleExpanded: onToggleExpanded,
              isExpanded: expanded,
            ),
            if (expanded) ...[
              const SizedBox(height: YugmaSpacing.s3),
              _UdhaarCadenceStepper(
                theme: theme,
                days: reminderCadenceDays,
                enabled: reminderOptIn,
                onChanged: onReminderCadenceChanged,
              ),
            ],
          ],
          // ─── v1.1 frozen state — §6.7 state #47 ─────────────────────
          if (isFrozenByShopLifecycle) ...[
            const SizedBox(height: YugmaSpacing.s3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: YugmaSpacing.s3,
                vertical: YugmaSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: theme.shopBackgroundWarmer,
                borderRadius: BorderRadius.circular(YugmaRadius.sm),
                border: Border.all(color: theme.shopDivider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    size: 16,
                    color: theme.shopTextMuted,
                  ),
                  const SizedBox(width: YugmaSpacing.s2),
                  Text(
                    'रुका हुआ',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 12,
                      color: theme.shopTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (partialPaymentReferences.isNotEmpty) ...[
            const SizedBox(height: YugmaSpacing.s3),
            Container(
              height: 1.5,
              color: theme.shopDivider,
            ),
            const SizedBox(height: YugmaSpacing.s3),
            Text(
              'भुगतान का इतिहास',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: 12,
                color: theme.shopTextSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s2),
            ...partialPaymentReferences.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.recordedAt.day}/${p.recordedAt.month} · ${p.method}',
                          style: TextStyle(
                            fontFamily: theme.fontFamilyDevanagariBody,
                            fontSize: 12,
                            color: theme.shopTextMuted,
                          ),
                        ),
                      ),
                      Text(
                        '+₹${p.amount}',
                        style: TextStyle(
                          fontFamily: YugmaFonts.mono,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.shopTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final YugmaThemeExtension theme;
  final String label;
  final int amount;
  final Color color;
  final bool emphasized;

  const _AmountColumn({
    required this.theme,
    required this.label,
    required this.amount,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariBody,
            fontSize: 11,
            color: theme.shopTextMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹$amount',
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: emphasized ? 22 : 17,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class UdhaarPayment {
  final String paymentId;
  final int amount;
  final DateTime recordedAt;
  final String method; // 'upi' | 'cash' | 'bank'
  const UdhaarPayment({
    required this.paymentId,
    required this.amount,
    required this.recordedAt,
    required this.method,
  });
}

// ═════════════════════════════════════════════════════════════════
// 7. PERSONA TOGGLE — Decision Circle Guest Mode
// ═════════════════════════════════════════════════════════════════
//
// Per Sally's UX Spec §3.3 + ADR-009: Decision Circle is a "silent
// superpower." This toggle is the ONE place where DC becomes visible.
// When tapped, it opens a sheet with persona options. Selecting an
// elder persona triggers the elder UI tier transformation.

enum CommitteePersona {
  me, // default
  mummyJi,
  papaJi,
  bhabhi,
  dadi,
  chachaJi,
  someoneElse,
}

class PersonaToggle extends StatelessWidget {
  final CommitteePersona currentPersona;
  final void Function(CommitteePersona) onPersonaChanged;

  const PersonaToggle({
    super.key,
    required this.currentPersona,
    required this.onPersonaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Material(
      color: theme.shopBackgroundWarmer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YugmaRadius.pill),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(YugmaRadius.pill),
        onTap: () => _showPersonaSheet(context, theme),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: theme.shopPrimary,
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Text(
                _personaLabel(currentPersona),
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: 12,
                  color: theme.shopPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _personaLabel(CommitteePersona p) {
    return switch (p) {
      CommitteePersona.me => 'मैं देख रहा हूँ',
      CommitteePersona.mummyJi => 'मम्मी जी',
      CommitteePersona.papaJi => 'पापा जी',
      CommitteePersona.bhabhi => 'भाभी',
      CommitteePersona.dadi => 'दादी',
      CommitteePersona.chachaJi => 'चाचा जी',
      CommitteePersona.someoneElse => 'कोई और',
    };
  }

  void _showPersonaSheet(
      BuildContext context, YugmaThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.shopSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(YugmaRadius.xl),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(YugmaSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'फोन कौन देख रहा है?',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: 18,
                color: theme.shopPrimary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s4),
            ...CommitteePersona.values.map((p) => ListTile(
                  title: Text(
                    _personaLabel(p),
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 16,
                      color: theme.shopTextPrimary,
                    ),
                  ),
                  onTap: () {
                    onPersonaChanged(p);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 8. ELDER TIER WRAPPER
// ═════════════════════════════════════════════════════════════════
//
// Wraps any subtree and applies the elder tier transformations
// (1.4× text, 56dp tap targets, slower animations, larger photos).
// Per PRD P2.3 + Sally's UX Spec §4.6.

class ElderTierWrapper extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ElderTierWrapper({
    super.key,
    required this.child,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final currentTheme = context.yugmaTheme;
    final elderTheme = currentTheme.copyWith(isElderTier: true);
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [elderTheme],
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 9. ABSENCE PRESENCE BANNER
// ═════════════════════════════════════════════════════════════════
//
// "Sunil-bhaiya is at a wedding today, back at 6 PM" — never silent.
// Per Brief §3 Bharosa "Absence as Presence" + PRD B1.9, B1.10.

enum PresenceStatus { available, away, busyWithCustomer, atEvent }

class AbsencePresenceBanner extends StatelessWidget {
  final PresenceStatus status;
  final String? awayMessageDevanagari;
  final String? awayVoiceNoteId;
  final DateTime? expectedReturnAt;
  final VoidCallback? onPlayVoiceNote;

  const AbsencePresenceBanner({
    super.key,
    required this.status,
    this.awayMessageDevanagari,
    this.awayVoiceNoteId,
    this.expectedReturnAt,
    this.onPlayVoiceNote,
  });

  @override
  Widget build(BuildContext context) {
    if (status == PresenceStatus.available) return const SizedBox.shrink();
    final theme = context.yugmaTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      margin: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: theme.shopBackgroundWarmer,
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        border: Border(
          left: BorderSide(color: theme.shopAccent, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: theme.shopAccent,
            size: 20,
          ),
          const SizedBox(width: YugmaSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awayMessageDevanagari ??
                      '${theme.ownerName} अभी दुकान पर नहीं हैं',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 16 : 14,
                    color: theme.shopPrimary,
                  ),
                ),
                if (expectedReturnAt != null)
                  Text(
                    '${expectedReturnAt!.hour}:${expectedReturnAt!.minute.toString().padLeft(2, '0')} बजे तक वापस आएंगे',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 14 : 12,
                      color: theme.shopTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (awayVoiceNoteId != null && onPlayVoiceNote != null)
            IconButton(
              icon: Icon(Icons.play_circle_outline,
                  color: theme.shopAccent, size: 28),
              onPressed: onPlayVoiceNote,
              tooltip: 'सुनील भैया का संदेश सुनिए',
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 10. HINDI TEXT FIELD — Devanagari-optimized
// ═════════════════════════════════════════════════════════════════

class HindiTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelDevanagari;
  final String? hintDevanagari;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final TextInputType? keyboardType;

  const HindiTextField({
    super.key,
    this.controller,
    this.labelDevanagari,
    this.hintDevanagari,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelDevanagari != null)
          Padding(
            padding: const EdgeInsets.only(bottom: YugmaSpacing.s2),
            child: Text(
              labelDevanagari!,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: 13,
                color: theme.shopPrimary,
              ),
            ),
          ),
        Container(
          constraints: BoxConstraints(minHeight: theme.tapTargetMin),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: theme.isElderTier ? 18 : 14,
              height: YugmaLineHeights.normal,
              color: theme.shopTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintDevanagari,
              hintStyle: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                color: theme.shopTextMuted,
              ),
              filled: true,
              fillColor: theme.shopSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                borderSide:
                    BorderSide(color: theme.shopDivider, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                borderSide:
                    BorderSide(color: theme.shopAccent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: YugmaSpacing.s3,
                vertical: YugmaSpacing.s3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 11. UPI PAY BUTTON — primary commitment CTA
// ═════════════════════════════════════════════════════════════════
//
// Per locked PQ3 + Sally's UX Spec: single tall UPI button with
// COD/bank/udhaar as smaller "और तरीके" link below.

class UpiPayButton extends StatelessWidget {
  final int amountInr;
  final VoidCallback onPressed;

  const UpiPayButton({
    super.key,
    required this.amountInr,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Material(
      color: theme.shopPrimary,
      borderRadius: BorderRadius.circular(YugmaRadius.lg),
      elevation: 4,
      shadowColor: theme.shopPrimaryDeep,
      child: InkWell(
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s6,
            vertical: YugmaSpacing.s4,
          ),
          constraints: BoxConstraints(minHeight: theme.tapTargetMin + 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'UPI से दीजिए · ₹$amountInr',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: theme.isElderTier ? 19 : 17,
                  color: theme.shopTextOnPrimary,
                ),
              ),
              const SizedBox(width: YugmaSpacing.s3),
              Row(
                children: [
                  _UpiAppIcon(label: 'P', color: theme.shopAccent),
                  const SizedBox(width: 4),
                  _UpiAppIcon(label: 'G', color: theme.shopAccent),
                  const SizedBox(width: 4),
                  _UpiAppIcon(label: 'पे', color: theme.shopAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpiAppIcon extends StatelessWidget {
  final String label;
  final Color color;
  const _UpiAppIcon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: YugmaFonts.mono,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A2308),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 12. GOLDEN HOUR PHOTO VIEW
// ═════════════════════════════════════════════════════════════════
//
// Full-bleed photo viewer with the "asli roop dikhaiye" toggle.
// Default = Golden Hour photo, toggled = working light photo.
// Per Brief §3 Golden Hour Mode + PRD B1.5.

class GoldenHourPhotoView extends StatefulWidget {
  final String goldenHourImageUrl;
  final String? workingLightImageUrl;
  final double height;

  const GoldenHourPhotoView({
    super.key,
    required this.goldenHourImageUrl,
    this.workingLightImageUrl,
    this.height = 280,
  });

  @override
  State<GoldenHourPhotoView> createState() => _GoldenHourPhotoViewState();
}

class _GoldenHourPhotoViewState extends State<GoldenHourPhotoView> {
  bool _showAsli = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final imageUrl =
        _showAsli && widget.workingLightImageUrl != null
            ? widget.workingLightImageUrl!
            : widget.goldenHourImageUrl;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.shopSecondary,
            theme.shopPrimaryDeep,
            const Color(0xFF2C1810),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Image (or fallback gradient)
          if (imageUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // Bottom gradient for legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),

          // Asli roop toggle
          if (widget.workingLightImageUrl != null)
            Positioned(
              top: YugmaSpacing.s3,
              right: YugmaSpacing.s3,
              child: Material(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(YugmaRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(YugmaRadius.pill),
                  onTap: () => setState(() => _showAsli = !_showAsli),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s3,
                      vertical: 6,
                    ),
                    child: Text(
                      _showAsli ? 'सुंदर रूप' : 'असली रूप दिखाइए',
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariBody,
                        fontSize: 11,
                        color: theme.shopAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 13. S4.10 UDHAAR REMINDER AFFORDANCES (v1.1 additions)
// ═════════════════════════════════════════════════════════════════
//
// Helper widgets consumed by UdhaarLedgerCard. Kept in this file per the
// "extend existing component" directive from Sally's handoff — these
// affordances are NOT their own component, they are additions to the
// existing S4.10 ledger card.
//
// Maps to UX Spec §4.16 and §6.11 states #63–#65.
// Strings come from UX Spec §5.5 #48–#50. No invented copy.
// Forbidden vocabulary enforcement: R10 locked (no ब्याज / पेनल्टी /
// बकाया तारीख / देय / क़िस्त / वसूली / डिफ़ॉल्ट).

class _UdhaarReminderOptInRow extends StatelessWidget {
  final YugmaThemeExtension theme;
  final bool optIn;
  final int reminderCount;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onToggleExpanded;
  final bool isExpanded;

  const _UdhaarReminderOptInRow({
    required this.theme,
    required this.optIn,
    required this.reminderCount,
    required this.onChanged,
    required this.onToggleExpanded,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s3,
        vertical: YugmaSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: theme.shopBackgroundWarmer,
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
        border: Border.all(color: theme.shopDivider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UX Spec §5.5 string #48 — bhaiya-authored question.
                // NOT system-authored. Voice is the bhaiya asking himself.
                Text(
                  'क्या मैं इस ग्राहक को याद दिलाऊँ?',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 14 : 12,
                    color: theme.shopTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (reminderCount > 0) ...[
                  const SizedBox(height: 2),
                  // UX Spec §5.5 string #49. DM Mono numerals. Amber-neutral
                  // at 3/3, NOT red — informational cap, not a shame state.
                  _ReminderCountBadge(
                    theme: theme,
                    count: reminderCount,
                  ),
                ],
              ],
            ),
          ),
          // Switch — affirmative opt-in required per R10 defensive posture.
          Switch(
            value: optIn,
            onChanged: onChanged,
            activeColor: theme.shopAccent,
            // Track color stays within token palette — no candy gold.
            activeTrackColor: theme.shopAccentGlow,
          ),
          // Expand/collapse for cadence stepper. Disabled affordance is
          // greyed, NOT hidden — discoverability matters.
          IconButton(
            icon: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: theme.shopTextMuted,
              size: 20,
            ),
            onPressed: onToggleExpanded,
            tooltip: isExpanded ? 'बंद कीजिए' : 'खोलिए',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: theme.tapTargetMin * 0.67,
              minHeight: theme.tapTargetMin * 0.67,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCountBadge extends StatelessWidget {
  final YugmaThemeExtension theme;
  final int count;
  const _ReminderCountBadge({required this.theme, required this.count});

  @override
  Widget build(BuildContext context) {
    final isCapped = count >= 3;
    // Amber-neutral at cap. Warning color token (not error, not commit).
    final badgeColor = isCapped ? theme.shopAccent : theme.shopTextMuted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.shopBackground,
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'याद दिलाया गया: ',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 10,
              color: theme.shopTextMuted,
            ),
          ),
          // DM Mono for the numeric — UX Spec §5.5 #49.
          Text(
            '$count/3',
            style: TextStyle(
              fontFamily: YugmaFonts.mono,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _UdhaarCadenceStepper extends StatelessWidget {
  final YugmaThemeExtension theme;
  final int days;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  const _UdhaarCadenceStepper({
    required this.theme,
    required this.days,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // UX Spec §6.11 #65 — min 7, max 30, default 14, DM Mono numerals.
    // No percentage, no slider handle decoration, no "recommended" callout.
    final opacity = enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'कितने दिन बाद याद दिलाना है?',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: theme.isElderTier ? 13 : 11,
                color: theme.shopTextSecondary,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s2),
            Row(
              children: [
                _StepperButton(
                  theme: theme,
                  icon: Icons.remove,
                  onTap: () {
                    final next = (days - 1).clamp(7, 30);
                    onChanged?.call(next);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$days दिन',
                      style: TextStyle(
                        fontFamily: YugmaFonts.mono,
                        fontSize: theme.isElderTier ? 19 : 16,
                        fontWeight: FontWeight.w600,
                        color: theme.shopPrimary,
                      ),
                    ),
                  ),
                ),
                _StepperButton(
                  theme: theme,
                  icon: Icons.add,
                  onTap: () {
                    final next = (days + 1).clamp(7, 30);
                    onChanged?.call(next);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '7 दिन',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: 9,
                    color: theme.shopTextMuted,
                  ),
                ),
                Text(
                  '30 दिन',
                  style: TextStyle(
                    fontFamily: YugmaFonts.mono,
                    fontSize: 9,
                    color: theme.shopTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final YugmaThemeExtension theme;
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 56dp tap targets per UX §6.11 #65 — "the munshi uses this screen,
    // and the munshi is not young." This is a non-elder-specific bump.
    return Material(
      color: theme.shopSurface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: theme.shopPrimary, size: 22),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 14. SHOP DEACTIVATION BANNER (C3.12) — v1.1
// ═════════════════════════════════════════════════════════════════
//
// A single reserved slot at the top of the customer-app screen stack,
// below the system status bar and above any in-app dock. Persistent —
// visible on every customer-facing screen during a shop lifecycle
// transition. Taps expand the FAQ screen.
//
// UX Spec §4.12, §6.7 states #42–#44.
// Strings from §5.5 #37–#40. No invented copy.
//
// Constraint 10 compliance:
//   - No legal jargon. No DPDP Act citations. No मंदिर / धर्म / मंगल.
// Dark-pattern discipline (UX §10 handoff #15):
//   - Amber only, never red. Never blinking. Never ticking animation.
//   - "data will be deleted in N days" is descriptive, never imperative.
//
// Partition discipline (I6.12):
//   - This widget is read-only. No customer-side writes touch
//     Shop.shopLifecycle — that field is operator-owned + system-owned.

enum ShopLifecycleState { active, deactivating, purgeScheduled, purged }

class ShopDeactivationBanner extends StatelessWidget {
  final ShopLifecycleState lifecycle;

  /// Days until final purge (for `deactivating` and `purge_scheduled`).
  final int retentionDaysRemaining;

  /// Short-copy elder-tier variant is forced when `true` — keeps the
  /// banner on a single wrapped line on 5.5" cheap Android displays per
  /// AE F14 patch (elder-tier what-if scenario).
  final bool useElderShortCopy;

  final VoidCallback onTapFaq;

  /// Only shown in `purge_scheduled` — primary action promoted out of
  /// the FAQ and into the banner itself per state #43.
  final VoidCallback? onExportData;

  const ShopDeactivationBanner({
    super.key,
    required this.lifecycle,
    required this.retentionDaysRemaining,
    required this.useElderShortCopy,
    required this.onTapFaq,
    this.onExportData,
  });

  @override
  Widget build(BuildContext context) {
    if (lifecycle == ShopLifecycleState.active) {
      return const SizedBox.shrink();
    }
    final theme = context.yugmaTheme;

    // Amber warning token for `deactivating`; one step warmer amber for
    // `purge_scheduled`. Red is NEVER used (dark-pattern discipline).
    final bgColor = lifecycle == ShopLifecycleState.deactivating
        ? theme.shopBackgroundWarmer
        : const Color(0xFFF4D9A3); // slightly warmer amber — within palette

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTapFaq,
        child: Container(
          width: double.infinity,
          // 48dp default / 64dp elder per UX §4.12.
          constraints: BoxConstraints(
            minHeight: theme.isElderTier ? 64 : 48,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: YugmaSpacing.s4,
            vertical: YugmaSpacing.s2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.shopAccent,
                size: 20,
              ),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: Text(
                  _bannerCopy(theme),
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariBody,
                    fontSize: theme.isElderTier ? 14 : 12,
                    color: theme.shopTextPrimary,
                    height: YugmaLineHeights.snug,
                  ),
                ),
              ),
              if (lifecycle == ShopLifecycleState.purgeScheduled &&
                  onExportData != null) ...[
                const SizedBox(width: YugmaSpacing.s2),
                Material(
                  color: theme.shopAccent,
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                    onTap: onExportData,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: YugmaSpacing.s3,
                        vertical: YugmaSpacing.s2,
                      ),
                      child: Text(
                        // UX Spec §5.5 string #40.
                        'डेटा export कीजिए',
                        style: TextStyle(
                          fontFamily: theme.fontFamilyDevanagariBody,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.shopPrimaryDeep,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _bannerCopy(YugmaThemeExtension theme) {
    switch (lifecycle) {
      case ShopLifecycleState.deactivating:
        // UX Spec §5.5 string #37 (full copy) or §6.7 #42 elder-short.
        if (useElderShortCopy) {
          // Elder-tier short variant per AE F14 — full copy wraps to 3
          // lines on 5.5" and clips bottom nav.
          return '${theme.ownerName} की दुकान बंद हो रही है — पैसा वापस, डेटा $retentionDaysRemaining दिन सुरक्षित';
        }
        return '${theme.ownerName} की दुकान बंद हो रही है — आपका पैसा वापस आ जाएगा, आपका डेटा $retentionDaysRemaining दिन तक सुरक्षित है';
      case ShopLifecycleState.purgeScheduled:
        // UX Spec §5.5 string #38.
        return 'डेटा $retentionDaysRemaining दिन में हटा दिया जाएगा — export कीजिए';
      case ShopLifecycleState.purged:
        // Customer still has app installed; read-only acknowledgment.
        return 'इस दुकान का डेटा हटा दिया गया है। आपकी पुरानी रसीदें अब भी आपके फ़ोन में हैं।';
      case ShopLifecycleState.active:
        return '';
    }
  }
}

// ─── FAQ screen companion — "क्या हो रहा है?" ──────────────────────────
//
// UX Spec §6.7 state #45. Full-screen scroll, NOT a modal. Plain
// Awadhi-Hindi bullets in 5 sections: money / orders / udhaar / retention
// / data export. No DPDP Act citations. No legal tone.
//
// The FAQ screen is also subscribed to the Firestore Shop listener — if
// the shop reactivates while the FAQ is open, the screen auto-redirects
// back to the normal shop landing with a 300ms fade (AE F6 patch).
// This widget does NOT own the listener — the host screen does; this
// widget just accepts an `onReactivated` callback it fires when the host
// tells it.
//
// Copy bindings: five Devanagari section headers are hardcoded here
// because they are documented as locked in UX Spec §4.12 section structure
// (money / orders / udhaar / retention / data export). The body copy is
// injected as parameters — the host screen reads it from strings_hi.dart.

class ShopDeactivationFaqScreen extends StatelessWidget {
  final ShopLifecycleState lifecycle;
  final int retentionDaysRemaining;
  final VoidCallback onExportData;

  /// Body copy for each of the 5 sections. Supplied by the host from
  /// strings_hi.dart — this widget does not invent strings.
  final String moneyBody;
  final String ordersBody;
  final String udhaarBody;
  final String retentionBody;
  final String dataExportBody;

  const ShopDeactivationFaqScreen({
    super.key,
    required this.lifecycle,
    required this.retentionDaysRemaining,
    required this.onExportData,
    required this.moneyBody,
    required this.ordersBody,
    required this.udhaarBody,
    required this.retentionBody,
    required this.dataExportBody,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopSurface,
        elevation: 0,
        title: Text(
          // UX Spec §5.5 string #39 — casual, NOT formal `क्या हुआ है?`.
          'क्या हो रहा है?',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: theme.isElderTier ? 22 : 18,
            color: theme.shopPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        children: [
          _FaqSection(theme: theme, title: 'पैसा', body: moneyBody),
          _FaqSection(theme: theme, title: 'आपके परिवार के सभी ऑर्डर', body: ordersBody),
          _FaqSection(theme: theme, title: 'खाता', body: udhaarBody),
          _FaqSection(
            theme: theme,
            title: 'डेटा',
            body: retentionBody,
          ),
          _FaqSection(
            theme: theme,
            title: 'रसीदें',
            body: dataExportBody,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        decoration: BoxDecoration(
          color: theme.shopSurface,
          border: Border(top: BorderSide(color: theme.shopDivider)),
        ),
        child: SafeArea(
          child: Material(
            color: theme.shopPrimary,
            borderRadius: BorderRadius.circular(YugmaRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(YugmaRadius.lg),
              onTap: onExportData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: YugmaSpacing.s4,
                ),
                alignment: Alignment.center,
                constraints: BoxConstraints(minHeight: theme.tapTargetMin),
                child: Text(
                  // UX Spec §5.5 string #40.
                  'डेटा export कीजिए',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 19 : 16,
                    color: theme.shopTextOnPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final YugmaThemeExtension theme;
  final String title;
  final String body;
  const _FaqSection({
    required this.theme,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: YugmaSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariDisplay,
              fontSize: theme.isElderTier ? 19 : 16,
              color: theme.shopPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          Text(
            body,
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: theme.isElderTier ? 15 : 13,
              color: theme.shopTextPrimary,
              height: YugmaLineHeights.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 15. SHOPKEEPER NPS CARD (S4.17) — v1.1
// ═════════════════════════════════════════════════════════════════
//
// DISMISSIBLE DASHBOARD CARD — NEVER A MODAL. UX Spec §4.13 locks this.
// Lives inside the `आज की सूची` triage screen, below the three triage
// sections. 10-dot horizontal rating row with anchor labels.
//
// Role-based visibility: bhaiya role only in bi-weekly cadence. The host
// supplies `visible` — if the role doesn't match, render nothing.
//
// Non-negotiables:
//   1. Card, not modal (PRD AC #1, repeated in UX §10 handoff).
//   2. Casual headline `कितना उपयोगी लगा?` — NOT formal
//      `कितना उपयोगी पाया?` (PRD party-mode F-P3 finding).
//   3. Anchor labels `1 = बिल्कुल नहीं` / `10 = बहुत ज़्यादा` (AE F12 patch).
//   4. Optional textarea collapsed by default (bhaiya never forced to type).
//   5. `भेज दीजिए` primary + `बाद में` secondary text-link (visual weight
//      must differ — secondary is never equal to submit).
//   6. NO gamification — no streaks, no badges, no "you've answered N".
//      Submission → 2-sec `धन्यवाद` pill → nothing else, ever.
//   7. Burnout warning is INVISIBLE to the shopkeeper. The host fires the
//      Crashlytics event from the score callback; this widget never
//      surfaces a warning.
//
// Partition discipline: writes go to `shops/{shopId}/feedback/{feedbackId}`.
// No operator-owned Project / ChatThread / UdhaarLedger field is touched.
// I6.12 sealed union compliant.

class NpsCard extends StatefulWidget {
  final void Function(int score, String? optionalNote) onSubmit;
  final VoidCallback onSnooze;

  const NpsCard({
    super.key,
    required this.onSubmit,
    required this.onSnooze,
  });

  @override
  State<NpsCard> createState() => _NpsCardState();
}

class _NpsCardState extends State<NpsCard> {
  int? _selectedScore;
  bool _textExpanded = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Container(
      margin: const EdgeInsets.all(YugmaSpacing.s4),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(color: theme.shopDivider),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UX Spec §5.5 string #41 — casual register.
          Text(
            'कितना उपयोगी लगा?',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariDisplay,
              fontSize: theme.isElderTier ? 20 : 17,
              color: theme.shopPrimary,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s3),
          // 10-dot horizontal row — DM Mono numerals inside each circle.
          // Water-glass fill pattern: the selected dot and all to its left
          // fill with the shop accent color.
          _NpsDotRow(
            theme: theme,
            selected: _selectedScore,
            onTap: (score) => setState(() => _selectedScore = score),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          // Anchor labels — AE F12 patch. Without these, a bhaiya
          // unfamiliar with NPS can't tell 1 from 10.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 = बिल्कुल नहीं',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: 10,
                  color: theme.shopTextMuted,
                ),
              ),
              Text(
                '10 = बहुत ज़्यादा',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: 10,
                  color: theme.shopTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s3),
          // Optional textarea — collapsed by default.
          if (!_textExpanded)
            GestureDetector(
              onTap: () => setState(() => _textExpanded = true),
              behavior: HitTestBehavior.opaque,
              child: Text(
                // UX Spec §5.5 string #42.
                'कुछ कहना है?',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: theme.isElderTier ? 14 : 12,
                  color: theme.shopAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: theme.isElderTier ? 15 : 13,
                color: theme.shopTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'कुछ कहना है?',
                hintStyle: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  color: theme.shopTextMuted,
                ),
                filled: true,
                fillColor: theme.shopBackgroundWarmer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  borderSide: BorderSide(color: theme.shopDivider),
                ),
              ),
            ),
          const SizedBox(height: YugmaSpacing.s4),
          // Primary + secondary. Visual weight MUST differ — secondary is
          // a text link, not a button.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: widget.onSnooze,
                child: Padding(
                  padding: const EdgeInsets.all(YugmaSpacing.s3),
                  child: Text(
                    // UX Spec §5.5 string #43.
                    'बाद में',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: theme.isElderTier ? 14 : 12,
                      color: theme.shopTextMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s3),
              Material(
                color: _selectedScore == null
                    ? theme.shopDivider
                    : theme.shopPrimary,
                borderRadius: BorderRadius.circular(YugmaRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  onTap: _selectedScore == null
                      ? null
                      : () => widget.onSubmit(
                            _selectedScore!,
                            _textExpanded && _noteController.text.isNotEmpty
                                ? _noteController.text
                                : null,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: YugmaSpacing.s5,
                      vertical: YugmaSpacing.s3,
                    ),
                    child: Text(
                      // No "submit" / "send" — `भेज दीजिए` is the locked
                      // primary. Not invented.
                      'भेज दीजिए',
                      style: TextStyle(
                        fontFamily: theme.fontFamilyDevanagariDisplay,
                        fontSize: theme.isElderTier ? 16 : 14,
                        color: _selectedScore == null
                            ? theme.shopTextMuted
                            : theme.shopTextOnPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NpsDotRow extends StatelessWidget {
  final YugmaThemeExtension theme;
  final int? selected;
  final ValueChanged<int> onTap;

  const _NpsDotRow({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(10, (i) {
        final score = i + 1;
        final isFilled = selected != null && score <= selected!;
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onTap(score),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? theme.shopAccent : theme.shopBackground,
                border: Border.all(
                  color: isFilled
                      ? theme.shopAccent
                      : theme.shopDivider,
                  width: 1.5,
                ),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFilled
                      ? theme.shopPrimaryDeep
                      : theme.shopTextMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 16. SHOP DEACTIVATION OPS 3-TAP FLOW (S4.19) — v1.1
// ═════════════════════════════════════════════════════════════════
//
// Bhaiya-role-only. Munshi and son roles MUST NOT see this — the Settings
// section is hidden, not disabled. The host screen enforces role-based
// visibility BEFORE routing to this widget; this widget trusts that gate.
//
// Three taps, never two, never four (UX §4.14):
//   - Tap 1: informational full-screen explanation
//   - Tap 2: reason dropdown (4 SAD enum values)
//   - Tap 3: confirmation dialog with inverted-language reversibility
//            footer PRINTED ON THE LIVE DIALOG (not in a help tooltip)
//
// Copy bindings come from UX §5.5 strings #44–#45.
// No invented strings. No mythic vocabulary. No legal jargon.

enum ShopDeactivationReason {
  retiring, // रिटायर हो रहा हूँ
  closingShop, // शॉप बंद कर रहा हूँ
  illness, // बीमारी / मेडिकल
  other, // अन्य
}

String shopDeactivationReasonLabel(ShopDeactivationReason r) {
  // UX Spec §5.5 #44 notes these map 1:1 to SAD v1.0.4 shopLifecycleReason.
  return switch (r) {
    ShopDeactivationReason.retiring => 'रिटायर हो रहा हूँ',
    ShopDeactivationReason.closingShop => 'शॉप बंद कर रहा हूँ',
    ShopDeactivationReason.illness => 'बीमारी / मेडिकल',
    ShopDeactivationReason.other => 'अन्य',
  };
}

// ─── Tap 1 — informational page ────────────────────────────────────────
class ShopDeactivationTap1Page extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onStop;

  /// The five body paragraphs from strings_hi.dart — one per section
  /// (customers / orders / udhaar / retention / data purge). UX §6.9 #55.
  final List<String> sectionBodies;

  const ShopDeactivationTap1Page({
    super.key,
    required this.onContinue,
    required this.onStop,
    required this.sectionBodies,
  }) : assert(sectionBodies.length == 5);

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    // UX Spec §6.9 #55 AE F10 patch — Awadhi-inflected when-clause order.
    const title = 'जब आप दुकान बंद करेंगे, तो क्या होगा?';
    const sectionTitles = [
      'ग्राहक',
      'ऑर्डर',
      'खाता',
      'डेटा',
      'रसीदें',
    ];

    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopSurface,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: theme.isElderTier ? 20 : 17,
            color: theme.shopPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: YugmaSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionTitles[i],
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: theme.isElderTier ? 18 : 15,
                  color: theme.shopPrimary,
                ),
              ),
              const SizedBox(height: YugmaSpacing.s2),
              Text(
                sectionBodies[i],
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariBody,
                  fontSize: theme.isElderTier ? 15 : 13,
                  color: theme.shopTextPrimary,
                  height: YugmaLineHeights.normal,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(YugmaSpacing.s4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onStop,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: YugmaSpacing.s4,
                    ),
                    side: BorderSide(color: theme.shopDivider),
                  ),
                  child: Text(
                    'रुक जाइए',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: theme.isElderTier ? 16 : 14,
                      color: theme.shopTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: YugmaSpacing.s3),
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.shopPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: YugmaSpacing.s4,
                    ),
                  ),
                  child: Text(
                    'आगे बढ़िए',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariDisplay,
                      fontSize: theme.isElderTier ? 16 : 14,
                      color: theme.shopTextOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tap 2 — reason dropdown (single-screen, 56dp tap targets) ─────────
class ShopDeactivationTap2ReasonPicker extends StatelessWidget {
  final void Function(ShopDeactivationReason) onReasonPicked;

  const ShopDeactivationTap2ReasonPicker({
    super.key,
    required this.onReasonPicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Scaffold(
      backgroundColor: theme.shopBackground,
      appBar: AppBar(
        backgroundColor: theme.shopSurface,
        elevation: 0,
        title: Text(
          'कारण चुनिए',
          style: TextStyle(
            fontFamily: theme.fontFamilyDevanagariDisplay,
            fontSize: theme.isElderTier ? 20 : 17,
            color: theme.shopPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(YugmaSpacing.s4),
        children: ShopDeactivationReason.values
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: YugmaSpacing.s3),
                child: Material(
                  color: theme.shopSurface,
                  borderRadius: BorderRadius.circular(YugmaRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(YugmaRadius.md),
                    onTap: () => onReasonPicked(r),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.all(YugmaSpacing.s4),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.shopDivider),
                        borderRadius: BorderRadius.circular(YugmaRadius.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopDeactivationReasonLabel(r),
                              style: TextStyle(
                                fontFamily: theme.fontFamilyDevanagariBody,
                                fontSize: theme.isElderTier ? 16 : 14,
                                color: theme.shopTextPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.shopTextMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Tap 3 — confirmation dialog with reversibility footer ─────────────
//
// The single most important copy placement in the ops app. The reversal
// footer is printed DIRECTLY BELOW the confirm button where the bhaiya's
// thumb is hovering — not in a tooltip, not in a help popover, not in a
// FAQ. If his thumb slips, the footer tells him it's okay.

Future<bool?> showShopDeactivationConfirmDialog({
  required BuildContext context,
}) async {
  final theme = context.yugmaTheme;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.shopSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(YugmaRadius.xl),
      ),
    ),
    builder: (dialogContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: YugmaSpacing.s5,
          right: YugmaSpacing.s5,
          top: YugmaSpacing.s5,
          bottom: MediaQuery.of(dialogContext).viewInsets.bottom +
              YugmaSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              // UX Spec §6.9 state #57 dialog title.
              'क्या आप पक्का हैं? यह तुरंत शुरू हो जाएगा।',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: theme.isElderTier ? 20 : 17,
                color: theme.shopPrimary,
                height: YugmaLineHeights.snug,
              ),
            ),
            const SizedBox(height: YugmaSpacing.s4),
            // Secondary first so the primary (warning color) sits lower
            // and the reversibility footer is directly under the thumb.
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.shopDivider),
                padding: const EdgeInsets.symmetric(
                  vertical: YugmaSpacing.s4,
                ),
              ),
              child: Text(
                'रुकिए, मुझे सोचना है',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: theme.isElderTier ? 16 : 14,
                  color: theme.shopTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.shopCommit, // oxblood — gravity
                padding: const EdgeInsets.symmetric(
                  vertical: YugmaSpacing.s4,
                ),
              ),
              child: Text(
                'हाँ, पक्का बंद कीजिए',
                style: TextStyle(
                  fontFamily: theme.fontFamilyDevanagariDisplay,
                  fontSize: theme.isElderTier ? 16 : 14,
                  color: theme.shopTextOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: YugmaSpacing.s3),
            // ─── The reversibility footer ───
            // UX Spec §5.5 string #45. PRINTED ON THE LIVE DIALOG. Not a
            // tooltip. Not a help popover. Not a FAQ. Directly under the
            // confirm button where the finger is hovering. Single most
            // important copy placement in the ops app.
            Text(
              'अगर गलती से दबाया, अगले 24 घंटे में उल्टा कर सकते हैं',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariBody,
                fontSize: theme.isElderTier ? 13 : 11,
                color: theme.shopTextSecondary,
                height: YugmaLineHeights.snug,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ─── Reversibility card — shown during the 24-hour window ──────────────
// Replaces the Settings "दुकान बंद करना" section during the window.
// UX Spec §6.9 #58.

class ShopReversibilityCard extends StatelessWidget {
  final int hoursRemaining;
  final VoidCallback onReopen;

  const ShopReversibilityCard({
    super.key,
    required this.hoursRemaining,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    return Container(
      margin: const EdgeInsets.all(YugmaSpacing.s4),
      padding: const EdgeInsets.all(YugmaSpacing.s4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D9A3), // yellow-amber, within palette
        borderRadius: BorderRadius.circular(YugmaRadius.lg),
        border: Border.all(color: theme.shopAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.replay, color: theme.shopPrimary),
              const SizedBox(width: YugmaSpacing.s2),
              Expanded(
                child: Text(
                  'दुकान फिर से चालू कीजिए',
                  style: TextStyle(
                    fontFamily: theme.fontFamilyDevanagariDisplay,
                    fontSize: theme.isElderTier ? 18 : 15,
                    color: theme.shopPrimary,
                  ),
                ),
              ),
              // DM Mono countdown — UX §6.9 #58.
              Text(
                '$hoursRemaining घंटे बाकी',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: theme.isElderTier ? 14 : 12,
                  fontWeight: FontWeight.w600,
                  color: theme.shopPrimaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s3),
          FilledButton(
            onPressed: onReopen,
            style: FilledButton.styleFrom(
              backgroundColor: theme.shopPrimary,
              minimumSize: Size(double.infinity, theme.tapTargetMin),
            ),
            child: Text(
              'दुकान खोलिए',
              style: TextStyle(
                fontFamily: theme.fontFamilyDevanagariDisplay,
                fontSize: theme.isElderTier ? 16 : 14,
                color: theme.shopTextOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// 17. MEDIA USAGE TILE (S4.16) — v1.1
// ═════════════════════════════════════════════════════════════════
//
// A single tile in the existing S4.11 analytics dashboard. Operator-only
// (bhaiya role). No new screen.
//
// Four color/banner states + count-incomplete asterisk:
//   - Green <50% (silent tile, no banner)
//   - Amber 50–80% (banner: `मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है`)
//   - Red ≥80% (same copy, red token, no emoji, no warning-triangle)
//   - Red-alt ≥100% + mediaStoreStrategy=r2 (`Cloudinary खत्म — R2 चालू`)
//   - `countIncomplete` asterisk overlay — informational, does NOT change tile color
//
// UX Spec §4.15, §5.5 #46–#47, §6.10 states #59–#62b.
// No emoji, no warning-triangle icon — deliberate per AC #4.

enum MediaUsageState { green, amber, red, redAltR2Active }

class MediaUsageTile extends StatelessWidget {
  final int usedCredits;
  final int totalCredits;
  final MediaUsageState state;

  /// Month-over-month delta. Positive → up, negative → down.
  final double momDeltaPct;

  /// Projected end-of-month total credits.
  final int projectedEom;

  /// AE F7 / state #62b — count-incomplete asterisk overlay. Tile color
  /// UNCHANGED by this flag; it's informational, not a threshold change.
  final bool countIncomplete;

  const MediaUsageTile({
    super.key,
    required this.usedCredits,
    required this.totalCredits,
    required this.state,
    required this.momDeltaPct,
    required this.projectedEom,
    this.countIncomplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.yugmaTheme;
    final pct = totalCredits == 0 ? 0.0 : usedCredits / totalCredits;

    // Progress bar color per threshold.
    final barColor = switch (state) {
      MediaUsageState.green => theme.shopAccent, // success derived from palette
      MediaUsageState.amber => const Color(0xFF8B6914), // weathered brass warn
      MediaUsageState.red ||
      MediaUsageState.redAltR2Active =>
        theme.shopCommit,
    };

    final showBanner = state != MediaUsageState.green;

    return Container(
      margin: const EdgeInsets.all(YugmaSpacing.s3),
      padding: const EdgeInsets.all(YugmaSpacing.s3),
      decoration: BoxDecoration(
        color: theme.shopSurface,
        borderRadius: BorderRadius.circular(YugmaRadius.md),
        border: Border.all(color: theme.shopDivider),
        boxShadow: YugmaShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBanner)
            _MediaBanner(theme: theme, state: state, barColor: barColor),
          if (showBanner) const SizedBox(height: YugmaSpacing.s2),
          // UX Spec §5.5 #46.
          Text(
            'मीडिया खर्च',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 14,
              color: theme.shopTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$usedCredits',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.shopPrimary,
                ),
              ),
              Text(
                '/$totalCredits',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 14,
                  color: theme.shopTextMuted,
                ),
              ),
              if (countIncomplete)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    '*',
                    style: TextStyle(
                      fontFamily: YugmaFonts.mono,
                      fontSize: 20,
                      color: theme.shopAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              // Month-over-month delta arrow.
              Icon(
                momDeltaPct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: momDeltaPct >= 0
                    ? theme.shopCommit
                    : theme.shopAccent,
              ),
              Text(
                '${momDeltaPct.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: YugmaFonts.mono,
                  fontSize: 11,
                  color: theme.shopTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: YugmaSpacing.s2),
          // Progress bar — 6dp tall, palette-derived color.
          ClipRRect(
            borderRadius: BorderRadius.circular(YugmaRadius.sm),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.shopBackgroundWarmer,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: YugmaSpacing.s2),
          Text(
            'अनुमानित महीने का अंत: $projectedEom',
            style: TextStyle(
              fontFamily: theme.fontFamilyDevanagariBody,
              fontSize: 11,
              color: theme.shopTextMuted,
            ),
          ),
          if (countIncomplete) ...[
            const SizedBox(height: YugmaSpacing.s2),
            // Tooltip-row under the tile — UX §6.10 #62b.
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: theme.shopAccent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'गिनती अधूरी — रात में ठीक हो जाएगी',
                    style: TextStyle(
                      fontFamily: theme.fontFamilyDevanagariBody,
                      fontSize: 10,
                      color: theme.shopTextMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaBanner extends StatelessWidget {
  final YugmaThemeExtension theme;
  final MediaUsageState state;
  final Color barColor;
  const _MediaBanner({
    required this.theme,
    required this.state,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    // UX Spec §5.5 #47 for the red-alt variant. No emoji, no icon.
    final copy = state == MediaUsageState.redAltR2Active
        ? 'Cloudinary खत्म — R2 चालू'
        : 'मीडिया खर्च आधा से ज़्यादा — जल्द खत्म हो सकता है';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YugmaSpacing.s3,
        vertical: YugmaSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(YugmaRadius.sm),
        border: Border(left: BorderSide(color: barColor, width: 3)),
      ),
      child: Text(
        copy,
        style: TextStyle(
          fontFamily: theme.fontFamilyDevanagariBody,
          fontSize: 11,
          color: theme.shopTextPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
