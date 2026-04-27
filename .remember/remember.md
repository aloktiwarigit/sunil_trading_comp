# Handoff

## State
Built `docs/architecture-source-of-truth.md` v1.0 (5-agent code audit on commit 3e6e2b0) with 30+ item P0–P3 drift backlog in §15. Created `CLAUDE.md` at repo root anchoring future sessions to the doc + non-negotiables. Ran BMAD party-mode (Winston/Amelia/Sally/Mary, all Opus): unanimous "enterprise-aware, not enterprise-grade". Mary scored 7 axes (most <5/10). ~25 net-new gaps surfaced beyond §15.

## Next
1. **Multi-tenant scaling plan-mode review** — user leans Option C (hybrid: single APK + per-shop subdomain + deep links). Backend 80% multi-tenant already; ~3 weeks productization. The 9-area work list + 3-option tradeoff was previewed in the final assistant turn before handoff.
2. Roll ~25 net-new party-mode gaps into §15 as v1.1 (mechanical).
3. Author `docs/enterprise-posture.md` — Mary's axis-by-axis posture-with-trigger-events doc.

## Context
- **DO NOT onboard shop #2** until §15.1 P0 closed: HMAC join token absent, DPDP grace 24h-vs-30d, bilingual deactivation FCM missing. (`dahej` ✅, hosting targets ✅, Triple Zero server-side ✅, App Check on callables ✅, Codex gate workflow ✅, 3 SAD runbooks ✅ + staging-setup updated with App-Check-Console + Codex-branch-protection ops steps.)
- Sonnet quota was hit earlier today; Opus fine. Pass `model: "opus"` to Agent dispatches when subagents fail with rate-limit.
- Free-tier OSS items (CodeQL/Semgrep/gitleaks/Codex/axe/pa11y/Dependabot/SBOM) cost zero — split them from paid SaaS (Sentry/PostHog/GrowthBook) when triaging "agency floor absent". Mary's reframe.
- User prefers upstream rigor over downstream firefighting; never propose shortcuts. Quality > speed.
