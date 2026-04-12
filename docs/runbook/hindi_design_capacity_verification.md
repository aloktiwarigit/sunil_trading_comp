---
artifact: Hindi Design Capacity Verification — I6.11 Sprint 0 Gate Closure
status: CLOSED — END STATE A
reviewer: Alok Tiwari (founder, Yugma Labs)
date_closed: 2026-04-12
constraint: Constraint 15 (PRD / Brief §8)
---

# Hindi Design Capacity Verification

## Decision

**END STATE A — Hindi-native reviewer identified: Alok Tiwari (founder).**

Alok is Hindi-native, from Ayodhya (the target market), and has shipped
Devanagari apps before. He can verify that all UX strings sound natural
to the target personas (Sunita-ji, Amit-ji, Geeta-ji, Rajeev-ji) and
catch any "textbook Hindi" or register drift before screens ship.

No external hire required. The Constraint 15 gate is satisfied by the
founder serving as the Hindi design reviewer.

## What this unblocks

All 55 user-visible stories across E1 (Bharosa), E2 (Pariwar), E3
(Commerce), E4 (Shopkeeper Ops), and E5 (Marketing Surface) are now
unblocked for implementation.

## Review workflow going forward

- Alok reviews Devanagari strings in PR diffs before merge
- The 50 strings in `packages/lib_core/lib/src/locale/strings_hi.dart`
  are the baseline — Alok has already seen these via prior sessions
- New strings added in Sprint 2+ go through the same review path
- ShopThemeTokens taglines (currently empty per Sprint 0 discipline)
  can now be populated with Alok-approved copy

## Additional context

- D4 Sunil-bhaiya face photo consent: SECURED (2026-04-12)
- B1.2 can use real shopkeeper photo as primary path (fallback circle
  remains as graceful degradation for missing photo)
