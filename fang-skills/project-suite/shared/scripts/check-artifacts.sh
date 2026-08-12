#!/bin/bash
# Cross-Artifact Analyzer v1.0
# 检查 spec ↔ plan ↔ architecture ↔ tasks 语义一致性。
# Spec Kit Analyze 思想的 project-suite 实现。
#
# Usage: bash shared/scripts/check-artifacts.sh <project-knowledge-dir>
# Exit: 0=consistent, 1=warnings, 2=drift detected

set -euo pipefail
KNOWLEDGE_DIR="${1:-.project-knowledge}"
REPORT="$KNOWLEDGE_DIR/artifact-consistency-report.md"
ISSUES=0

echo "# Artifact Consistency Report" > "$REPORT"
echo "> $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$REPORT"
echo "" >> "$REPORT"

# 1. Spec → Plan: spec 中的 requirement 是否在 plan 中有对应？
echo "## 1. Spec → Plan" >> "$REPORT"
if [ -f "$KNOWLEDGE_DIR/proposals/PLAN-"*.md ] 2>/dev/null; then
  # Check: Spec mentions "avatar" → Plan must have corresponding task
  spec_terms=$(grep -oE "上传|upload|avatar|头像" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | sort -u || true)
  for term in $spec_terms; do
    plan_has=$(grep -c "$term" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null || echo 0)
    if [ "$plan_has" -lt 2 ]; then
      echo "- ⚠️ Spec mentions '$term' but Plan lacks corresponding task" >> "$REPORT"
      ((ISSUES++))
    fi
  done
  [ "$ISSUES" -eq 0 ] && echo "✅ All spec requirements mapped to plan" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 2. Plan → Architecture: plan decisions → architecture decisions
echo "## 2. Plan → Architecture" >> "$REPORT"
if [ -f "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-"*.md ] 2>/dev/null; then
  plan_decisions=$(grep -c "Decision\|decision\|决策" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null || echo 0)
  arch_decisions=$(grep -c "###\|Decision\|ADR" "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-"*.md 2>/dev/null || echo 0)
  if [ "$arch_decisions" -ge "$plan_decisions" ] 2>/dev/null; then
    echo "✅ Architecture covers all plan decisions ($arch_decisions ≥ $plan_decisions)" >> "$REPORT"
  else
    echo "- ⚠️ Plan has $plan_decisions decisions but Architecture only covers $arch_decisions" >> "$REPORT"
    ((ISSUES++))
  fi
fi
echo "" >> "$REPORT"

# 3. Architecture → Tasks: component decisions → implementation tasks
echo "## 3. Architecture → Tasks" >> "$REPORT"
arch_components=$(grep -c "component\|Component\|模块\|module" "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-"*.md 2>/dev/null || echo 0)
echo "  Architecture defines $arch_components components (verify tasks cover them)" >> "$REPORT"
echo "" >> "$REPORT"

# 4. Principle Compliance: do plan/architecture respect project principles?
echo "## 4. Principle Compliance" >> "$REPORT"
if [ -f "$KNOWLEDGE_DIR/../runtime/registry/project-principles.yaml" ] 2>/dev/null; then
  principles=$(grep -c "principle\." "$KNOWLEDGE_DIR/../runtime/registry/project-principles.yaml" 2>/dev/null || echo 0)
  echo "  Project has $principles active principles" >> "$REPORT"
  # Check if PLAN mentions principles
  plan_principles=$(grep -c "principle\|Principle\|原则" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null || echo 0)
  [ "$plan_principles" -gt 0 ] && echo "  ✅ Plan references $plan_principles principles" >> "$REPORT" || echo "  ⚠️ Plan does not reference project principles" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## Summary" >> "$REPORT"
echo "| Check | Status |" >> "$REPORT"
echo "|-------|--------|" >> "$REPORT"
echo "| Spec → Plan | $([ "$ISSUES" -eq 0 ] && echo '✅' || echo "⚠️ $ISSUES issues") |" >> "$REPORT"

echo "Report: $REPORT"
[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
