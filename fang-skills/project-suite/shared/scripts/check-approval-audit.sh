#!/bin/bash
# Approval Audit Checker v1.0
# Validates approval trail completeness in .project-runtime/state.json
#
# Usage: bash shared/scripts/check-approval-audit.sh [project-root]
# Exit: 0=clean, 1=warnings, 2=violations

set -euo pipefail
PROJECT_ROOT="${1:-.}"
STATE_FILE="$PROJECT_ROOT/.project-runtime/state.json"

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

echo "========================================"
echo " Approval Audit Report"
echo "========================================"
echo ""

if [ ! -f "$STATE_FILE" ]; then
  yellow "No state.json found — nothing to audit"
  echo ""
  echo "Create state.json by running any project-suite skill."
  exit 0
fi

PASS=0; WARN=0; VIOLATION=0

# Check 1: Each skill execution has approval_log entries
skill_count=$(grep -c '"skill"' "$STATE_FILE" 2>/dev/null || echo 0)
approval_count=$(grep -c '"level"' "$STATE_FILE" 2>/dev/null || echo 0)
if [ "$approval_count" -gt 0 ]; then
  green "  ✅ Approval log: ${approval_count} entries for ${skill_count} skill executions"
  ((PASS++))
else
  yellow "  ⚠️  No approval_log entries found — approvals not being recorded"
  ((WARN++))
fi

# Check 2: No BLOCK without MANUAL_OVERRIDE
blocks=$(grep -c '"level": "BLOCK"' "$STATE_FILE" 2>/dev/null || echo 0)
overrides=$(grep -c '"user_override": true' "$STATE_FILE" 2>/dev/null || echo 0)
if [ "$blocks" -gt 0 ]; then
  if [ "$overrides" -ge "$blocks" ]; then
    green "  ✅ BLOCK compliance: ${blocks} blocks, ${overrides} overrides"
    ((PASS++))
  else
    red "  ❌ BLOCK violation: ${blocks} blocks but only ${overrides} overrides — possible unapproved downstream execution"
    ((VIOLATION++))
  fi
else
  green "  ✅ No BLOCK events"
  ((PASS++))
fi

# Check 3: GATE events have review or override
gates=$(grep -c '"level": "GATE"' "$STATE_FILE" 2>/dev/null || echo 0)
gate_overrides=$(grep -B2 '"user_override": true' "$STATE_FILE" 2>/dev/null | grep -c "GATE" || echo 0)
# Also check for REVIEW records after GATE
review_after_gate=$(grep -A5 '"level": "GATE"' "$STATE_FILE" 2>/dev/null | grep -c '"skill": "project-reviewer"' || echo 0)
gate_covered=$((gate_overrides + review_after_gate))
if [ "$gates" -gt 0 ]; then
  if [ "$gate_covered" -ge "$gates" ]; then
    green "  ✅ GATE compliance: ${gates} gates, ${gate_covered} covered (override/review)"
    ((PASS++))
  else
    yellow "  ⚠️  GATE gap: ${gates} gates, only ${gate_covered} covered"
    ((WARN++))
  fi
else
  green "  ✅ No GATE events"
  ((PASS++))
fi

# Check 4: MANUAL_OVERRIDE entries have non-empty reason
override_no_reason=$(grep -A1 '"user_override": true' "$STATE_FILE" 2>/dev/null | grep -c '"reason": ""' || echo 0)
if [ "$overrides" -gt 0 ]; then
  if [ "$override_no_reason" -eq 0 ]; then
    green "  ✅ Override reasons: all ${overrides} overrides have reasons"
    ((PASS++))
  else
    yellow "  ⚠️  ${override_no_reason}/${overrides} overrides missing reason"
    ((WARN++))
  fi
else
  green "  ✅ No overrides — no reasons needed"
  ((PASS++))
fi

echo ""
echo "========================================"
echo " Verdict"
echo "========================================"
echo " Passed:    $PASS/4"
echo " Warnings:  $WARN/4"
echo " Violations: $VIOLATION/4"
echo ""

if [ "$VIOLATION" -gt 0 ]; then
  red "❌ APPROVAL AUDIT FAILED — ${VIOLATION} violation(s)"
  exit 2
elif [ "$WARN" -gt 0 ]; then
  yellow "⚠️  APPROVAL AUDIT WARNING — ${WARN} issue(s)"
  exit 1
else
  green "✅ APPROVAL AUDIT CLEAN"
  exit 0
fi
