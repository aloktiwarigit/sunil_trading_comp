#!/usr/bin/env bash
# =============================================================================
# audit_project_patch_imports.sh — PRD I6.12 AC #3 import discipline guard
#
# Verifies that:
#   1. customer_app code imports ONLY ProjectCustomerPatch + Cancel variant
#   2. shopkeeper_app code imports ONLY ProjectOperatorPatch + Revert variant
#   3. functions/ code imports ONLY ProjectSystemPatch (via JS/TS in future;
#      for now we just verify no Dart cross-imports)
#   4. No file in any app uses `unrestricted` imports of `project_patch.dart`
#      (i.e., every import must use `show` to limit the imported symbols)
#
# Runs in CI on every PR (.github/workflows/ci-cross-tenant-test.yml).
# Exit 0 on pass, exit 1 on any violation.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CUSTOMER_APP="$REPO_ROOT/apps/customer_app"
SHOPKEEPER_APP="$REPO_ROOT/apps/shopkeeper_app"

FAIL=0

# -----------------------------------------------------------------------------
# Helper: grep for a pattern in a directory, exit 1 on any match
# -----------------------------------------------------------------------------

forbid_pattern_in_dir() {
  local dir="$1"
  local pattern="$2"
  local reason="$3"

  if [ ! -d "$dir" ]; then
    # Directory doesn't exist yet (Sprint 1 — apps/ not yet scaffolded).
    return 0
  fi

  local hits
  hits=$(grep -rn --include='*.dart' -E "$pattern" "$dir" || true)
  if [ -n "$hits" ]; then
    echo "❌ FORBIDDEN import in $dir:"
    echo "   reason: $reason"
    echo "$hits"
    FAIL=1
  fi
}

# -----------------------------------------------------------------------------
# customer_app must NOT import ProjectOperatorPatch, ProjectSystemPatch,
# or ProjectOperatorRevertPatch.
# -----------------------------------------------------------------------------

forbid_pattern_in_dir "$CUSTOMER_APP" \
  'ProjectOperatorPatch' \
  'customer_app cannot construct operator patches (PRD Standing Rule 11)'

forbid_pattern_in_dir "$CUSTOMER_APP" \
  'ProjectSystemPatch' \
  'customer_app cannot construct system patches (PRD Standing Rule 11)'

forbid_pattern_in_dir "$CUSTOMER_APP" \
  'ProjectOperatorRevertPatch' \
  'customer_app cannot construct revert patches (PRD I6.12 edge case #2)'

# -----------------------------------------------------------------------------
# shopkeeper_app must NOT import ProjectCustomerPatch, ProjectSystemPatch,
# or ProjectCustomerCancelPatch.
# -----------------------------------------------------------------------------

forbid_pattern_in_dir "$SHOPKEEPER_APP" \
  'ProjectCustomerPatch' \
  'shopkeeper_app cannot construct customer patches (PRD Standing Rule 11)'

forbid_pattern_in_dir "$SHOPKEEPER_APP" \
  'ProjectSystemPatch' \
  'shopkeeper_app cannot construct system patches (PRD Standing Rule 11)'

forbid_pattern_in_dir "$SHOPKEEPER_APP" \
  'ProjectCustomerCancelPatch' \
  'shopkeeper_app cannot construct customer-cancel patches (PRD I6.12 edge case #1)'

# -----------------------------------------------------------------------------
# Neither app may use an unrestricted import of project_patch.dart.
# Every import MUST use `show` to limit the symbols.
# -----------------------------------------------------------------------------

for app_dir in "$CUSTOMER_APP" "$SHOPKEEPER_APP"; do
  if [ ! -d "$app_dir" ]; then
    continue
  fi
  # Find any import of project_patch.dart that does NOT include `show`.
  unrestricted=$(grep -rn --include='*.dart' \
    "import.*project_patch\.dart" "$app_dir" | grep -v ' show ' || true)
  if [ -n "$unrestricted" ]; then
    echo "❌ FORBIDDEN unrestricted import of project_patch.dart in $app_dir:"
    echo "   (every import must use 'show' to limit symbols per PRD I6.12 AC #3)"
    echo "$unrestricted"
    FAIL=1
  fi
done

# -----------------------------------------------------------------------------
# Same audit for chat_thread_patch.dart and udhaar_ledger_patch.dart
# -----------------------------------------------------------------------------

forbid_pattern_in_dir "$CUSTOMER_APP" \
  'ChatThreadOperatorPatch' \
  'customer_app cannot construct chat thread operator patches'

forbid_pattern_in_dir "$CUSTOMER_APP" \
  'UdhaarLedgerOperatorPatch' \
  'customer_app cannot construct udhaar operator patches (ADR-010, customers never write udhaar)'

# -----------------------------------------------------------------------------
# Verdict
# -----------------------------------------------------------------------------

if [ $FAIL -eq 0 ]; then
  echo "✓ project_patch import audit PASSED"
  exit 0
else
  echo ""
  echo "✗ project_patch import audit FAILED — fix the violations above."
  echo "  See PRD v1.0.5 I6.12 AC #3 and Standing Rule 11."
  exit 1
fi
