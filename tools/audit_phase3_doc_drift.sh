#!/usr/bin/env bash
# =============================================================================
# audit_phase3_doc_drift.sh — Phase 4 doc-drift guard.
#
# Verifies that the Phase 3 contract (amountReceivedByShop set inside
# applyOperatorMarkPaidPatch, Triple Zero asserted at paid OR closed) is not
# contradicted in the canonical docs. Historical artifacts are intentionally
# excluded.
#
# Patterns are precise extended regexes — they catch the illegitimate
# *contexts* (commit patch, client-side framing, state diagram) without
# banning the bare assignment `amountReceivedByShop = totalAmount` (which
# legitimately appears in operator-mark-paid and close prose).
#
# Wired into CI via .github/workflows/ci-cross-tenant-test.yml (mirror
# audit_project_patch_imports.sh shape).
#
# Exit 0 on pass, exit 1 on any drift. Run from repo root.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Canonical docs (in scope). Historical artifacts (docs/reviews/, session
# handoffs, party-mode synthesis, plans, .remember, CLAUDE.md) are out of
# scope by design — see Phase 4 plan §D3.
CANONICAL_DOCS=(
  "$REPO_ROOT/docs/architecture-source-of-truth.md"
  "$REPO_ROOT/_bmad-output/planning-artifacts/solution-architecture.md"
  "$REPO_ROOT/_bmad-output/planning-artifacts/prd.md"
)

# Forbidden regex patterns. Each binds the "amountReceivedByShop set at
# commit / client-side" claim to a specific illegitimate context. The bare
# phrase `amountReceivedByShop = totalAmount` is intentionally NOT banned —
# operator-mark-paid prose and Phase 3 patch notes legitimately use it.
# See Phase 4 plan §D4 for the full rationale.
FORBIDDEN_PATTERNS=(
  # Prose: "the customer commit patch sets amountReceivedByShop = totalAmount"
  'ProjectCustomerCommitPatch.*amountReceivedByShop[[:space:]]*=?[[:space:]]*totalAmount'
  # Pre-Phase-3 SAD framing
  'Triple Zero invariant set client-side'
  # State-diagram annotation: `Triple Zero set: ... amountReceivedByShop = totalAmount`
  'Triple Zero set:.*amountReceivedByShop[[:space:]]*=[[:space:]]*totalAmount'
  # Alternative phrasings without the type name
  'amountReceivedByShop set at commit'
)

FAIL=0

for doc in "${CANONICAL_DOCS[@]}"; do
  if [ ! -f "$doc" ]; then
    echo "❌ canonical doc missing: $doc"
    FAIL=1
    continue
  fi

  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    # grep -E: extended regex; -n: line numbers; --color=never: stable in CI;
    # || true so an empty match doesn't trip set -e before we inspect it.
    matches=$(grep -En --color=never "$pattern" "$doc" || true)
    if [ -n "$matches" ]; then
      echo "❌ FORBIDDEN pattern in $doc:"
      echo "   /$pattern/ — Phase 3 moved this to applyOperatorMarkPaidPatch"
      echo "$matches"
      echo ""
      FAIL=1
    fi
  done
done

if [ $FAIL -eq 0 ]; then
  echo "✓ Phase 3 doc-drift audit PASSED"
  exit 0
else
  echo ""
  echo "✗ Phase 3 doc-drift audit FAILED — see Phase 4 plan §G1 for fix guide."
  exit 1
fi
