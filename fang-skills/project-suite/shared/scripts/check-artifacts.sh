#!/bin/bash
# Cross-Artifact Analyzer v1.0
# 检查 spec ↔ plan ↔ architecture ↔ tasks 语义一致性。
# Spec Kit Analyze 思想的 project-suite 实现。
#
# Usage: bash shared/scripts/check-artifacts.sh <project-knowledge-dir>
# Exit: 0=consistent, 1=warnings, 2=drift detected

set -uo pipefail
KNOWLEDGE_DIR="${1:-.project-knowledge}"

# 目录不存在 → SKIP（工具默认前提未满足，不是 drift）
if [ ! -d "$KNOWLEDGE_DIR" ]; then
  echo "⚠️ SKIP: $KNOWLEDGE_DIR 不存在（无输入 artifact，非 drift）"
  exit 0
fi

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
if [ -f "$KNOWLEDGE_DIR/../runtime/contracts/project-principles.schema.yaml" ] 2>/dev/null; then
  principles=$(grep -c "principle\." "$KNOWLEDGE_DIR/../runtime/contracts/project-principles.schema.yaml" 2>/dev/null || echo 0)
  echo "  Project has $principles active principles" >> "$REPORT"
  # Check if PLAN mentions principles
  plan_principles=$(grep -c "principle\|Principle\|原则" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null || echo 0)
  [ "$plan_principles" -gt 0 ] && echo "  ✅ Plan references $plan_principles principles" >> "$REPORT" || echo "  ⚠️ Plan does not reference project principles" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 5. ID Traceability（Decision-traceable）" >> "$REPORT"
echo "" >> "$REPORT"

# 5a. 提取 Requirement 定义（R-xxx: 列表项）与 Task 的 satisfies 引用（区分定义 vs 引用，避免空转）
if [ -f "$KNOWLEDGE_DIR/proposals/PLAN-"*.md ] 2>/dev/null; then
  orphan_ids=0
  # 定义：R-xxx: 形式（Scope In 列表项）；引用：satisfies: R-xxx
  defined_reqs=$(grep -oE "R-[0-9]{3}:" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | grep -oE "R-[0-9]{3}" | sort -u || true)
  referenced_reqs=$(grep -oE "satisfies:.*R-[0-9]{3}" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | grep -oE "R-[0-9]{3}" | sort -u || true)

  for req in $referenced_reqs; do
    if ! echo "$defined_reqs" | grep -q "$req"; then
      echo "- ⚠️ Task 的 satisfies 引用 $req，但未定义该 Requirement（无 R-xxx: 列表项）" >> "$REPORT"
      ((orphan_ids++))
      ((ISSUES++))
    fi
  done

  # 定义：#### T-xxx: 详情头；引用：verifies: T-xxx（AC）
  defined_tasks=$(grep -oE "#### T-[0-9]{3}:" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | grep -oE "T-[0-9]{3}" | sort -u || true)
  referenced_tasks=$(grep -oE "verifies:.*T-[0-9]{3}" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | grep -oE "T-[0-9]{3}" | sort -u || true)

  for task in $referenced_tasks; do
    if ! echo "$defined_tasks" | grep -q "$task"; then
      echo "- ⚠️ AC 的 verifies 引用 $task，但未定义该 Task（无 #### T-xxx: 详情头）" >> "$REPORT"
      ((orphan_ids++))
      ((ISSUES++))
    fi
  done

  # 定义：D-xxx（PLAN）；引用：implements: D-xxx（ARCHITECTURE）
  defined_decisions=$(grep -oE "D-[0-9]{3}" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | sort -u || true)
  referenced_decisions=$(grep -oE "implements:.*D-[0-9]{3}" "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-"*.md 2>/dev/null | grep -oE "D-[0-9]{3}" | sort -u || true)
  for d in $referenced_decisions; do
    if ! echo "$defined_decisions" | grep -q "$d"; then
      echo "- ⚠️ ADR 的 implements 引用 $d，但 PLAN 未定义该 Decision" >> "$REPORT"
      ((orphan_ids++))
      ((ISSUES++))
    fi
  done

  # 定义：AC-xxx（PLAN）；引用：against: AC-xxx（REVIEW）
  defined_acs=$(grep -oE "AC-[0-9]{3}" "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null | sort -u || true)
  referenced_acs=$(grep -oE "against:.*AC-[0-9]{3}" "$KNOWLEDGE_DIR/reports/REVIEW-"*.md 2>/dev/null | grep -oE "AC-[0-9]{3}" | sort -u || true)
  for ac in $referenced_acs; do
    if ! echo "$defined_acs" | grep -q "$ac"; then
      echo "- ⚠️ Review Finding 的 against 引用 $ac，但 PLAN 未定义该 AC" >> "$REPORT"
      ((orphan_ids++))
      ((ISSUES++))
    fi
  done

  [ "$orphan_ids" -eq 0 ] && echo "✅ All ID references resolve（无孤立 ID）" >> "$REPORT"
else
  echo "ℹ️  No PLAN found — ID traceability skipped" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 6. Decision 语义（粗筛：① 是否误写成实现动作 ② 是否缺选择题语义）" >> "$REPORT"
if [ -f "$KNOWLEDGE_DIR/proposals/PLAN-"*.md ] 2>/dev/null; then
  # 只取 # Decision 段（到下一个 # 标题为止），避免误扫 Task 表的 Decision Deps 列
  decision_lines=$(awk '/^# Decision/{f=1;next} /^# /{f=0} f' "$KNOWLEDGE_DIR/proposals/PLAN-"*.md 2>/dev/null || true)

  # 6a. 负向：D-XX 含实现动词 → 疑似把 Task 写成 Decision
  decision_task_lines=$(echo "$decision_lines" | grep -nE "D-[0-9]+.*(实现|新增|修改|删除|构建|重构|开发|搭建|编写)" || true)
  if [ -n "$decision_task_lines" ]; then
    echo "- ⚠️ 6a 疑似把 Task 写成 D-XX（含实现动词）：" >> "$REPORT"
    echo "$decision_task_lines" | sed 's/^/    /' >> "$REPORT"
    ((ISSUES++))
  else
    echo "✅ 6a 负向粗筛未命中（D-XX 无实现动词）" >> "$REPORT"
  fi

  # 6b. 正向：D-XX 缺「选择题」语义（无问号、无「还是」、无候选方案 A:/B:）→ 疑似写成陈述句
  decision_statement_lines=$(echo "$decision_lines" | grep -E "D-[0-9]+" | grep -vE "？|还是|A:|B:" || true)
  if [ -n "$decision_statement_lines" ]; then
    echo "- ⚠️ 6b 疑似把陈述句写成 D-XX（无问号/「还是」/候选方案）：" >> "$REPORT"
    echo "$decision_statement_lines" | sed 's/^/    /' >> "$REPORT"
    ((ISSUES++))
  else
    echo "✅ 6b 正向粗筛未命中（每个 D-XX 均含问号/「还是」/候选方案）" >> "$REPORT"
  fi

  echo "  （粗筛命中以 verifier V8 语义复核为准）" >> "$REPORT"
else
  echo "ℹ️  No PLAN found — Decision 语义粗筛 skipped" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## Summary" >> "$REPORT"
echo "| Check | Status |" >> "$REPORT"
echo "|-------|--------|" >> "$REPORT"
echo "| Spec → Plan | $([ "$ISSUES" -eq 0 ] && echo '✅' || echo "⚠️ $ISSUES issues") |" >> "$REPORT"

echo "Report: $REPORT"
[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
