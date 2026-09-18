#!/bin/bash
# Approval Audit Checker v1.0
# Validates approval trail completeness in .project-knowledge/runtime/state.json
#
# Usage: bash shared/scripts/check-approval-audit.sh [project-root]
# Exit: 0=clean, 1=warnings, 2=violations

set -euo pipefail
PROJECT_ROOT="${1:-.}"
STATE_FILE="$PROJECT_ROOT/.project-knowledge/runtime/state.json"

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

# ⚠️ 计数统一用 count_of()，不要写 `$(grep -c X f || echo 0)`：
#    grep -c 在「文件存在但零匹配」时会**打印 0 且 exit 1**，`|| echo 0` 再补一个 0
#    → 变量变成两行 `0\n0` → 后续 `[ "$var" -gt 0 ]` 报 integer expression 错误并**静默走 else 分支**。
#    实测（2026-09-18）：本脚本每次真实运行喷 3 个 shell 错误。
count_of() {
  local n
  n=$(grep -c "$1" "$2" 2>/dev/null || true)
  printf '%s' "${n:-0}"
}

# Check 1: 每次 skill 执行都要有 approval_log 条目
# ⚠️ 原实现只判 `approval_count > 0` 就打印 ✅，**从不比较 skill_count**——
#    实测：2 次执行只有 1 条审批记录，照样输出「✅ 1 entries for 2 skill executions」。
#    声称的是「每次执行都有条目」，实际只查了「至少有一条」→ 假检查（2026-09-18 修）。
skill_count=$(count_of '"skill"' "$STATE_FILE")
approval_count=$(count_of '"level"' "$STATE_FILE")
if [ "$skill_count" -eq 0 ]; then
  yellow "  ⚠️  state.json 无 skill 执行记录"
  ((WARN++))
elif [ "$approval_count" -ge "$skill_count" ]; then
  green "  ✅ Approval log: ${approval_count} entries ≥ ${skill_count} skill executions"
  ((PASS++))
else
  yellow "  ⚠️  Approval log 不全：${skill_count} 次 skill 执行，仅 ${approval_count} 条审批记录"
  ((WARN++))
fi

# Check 2: No BLOCK without MANUAL_OVERRIDE
blocks=$(count_of '"level": "BLOCK"' "$STATE_FILE")
overrides=$(count_of '"user_override": true' "$STATE_FILE")
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
gates=$(count_of '"level": "GATE"' "$STATE_FILE")
gate_overrides=$(grep -B2 '"user_override": true' "$STATE_FILE" 2>/dev/null | grep -c "GATE" || true); gate_overrides=${gate_overrides:-0}
# Also check for REVIEW records after GATE
review_after_gate=$(grep -A5 '"level": "GATE"' "$STATE_FILE" 2>/dev/null | grep -c '"skill": "project-reviewer"' || true); review_after_gate=${review_after_gate:-0}
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
override_no_reason=$(grep -A1 '"user_override": true' "$STATE_FILE" 2>/dev/null | grep -c '"reason": ""' || true); override_no_reason=${override_no_reason:-0}
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
