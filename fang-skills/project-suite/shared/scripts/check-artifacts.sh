#!/bin/bash
# Cross-Artifact Analyzer v1.0
# 检查 spec ↔ plan ↔ architecture ↔ tasks 语义一致性。
# Spec Kit Analyze 思想的 project-suite 实现。
#
# Usage: bash shared/scripts/check-artifacts.sh <project-knowledge-dir>
# Exit: 0=consistent, 1=发现 issue, 2=参数不是 .project-knowledge 目录
#
# ⚠️ 参数守卫（2026-09-18 加）：本脚本把报告**写在参数目录内**。若误传项目根
#    （check-approval-audit.sh 的约定就是传项目根，两脚本约定不同），报告会落到项目根，
#    违反「生成产物一律进 .project-knowledge/」。故先校验参数，不合格直接拒绝。

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KNOWLEDGE_DIR="${1:-.project-knowledge}"

case "$KNOWLEDGE_DIR" in
  *.project-knowledge|project-knowledge) : ;;
  *)
    echo "❌ 参数应为 .project-knowledge 目录，收到：$KNOWLEDGE_DIR" >&2
    echo "   本脚本会在参数目录内写 artifact-consistency-report.md——传错会把产物落到项目根。" >&2
    echo "   Usage: bash shared/scripts/check-artifacts.sh <project-knowledge-dir>" >&2
    exit 2
    ;;
esac

# 计数统一走这里，不要写 `$(grep -c X f || echo 0)`：
# grep -c 在「文件存在但零匹配」时打印 0 且 exit 1，`|| echo 0` 再补一个 → 变量成两行 `0\n0`
# → `[ "$var" -lt 2 ]` 报整数错误并**静默走 else**，于是「术语完全没出现」（最强的漂移信号）反而不报警。
# 另外多文件时 `grep -c` 会输出 `文件名:计数` 多行，故这里先 cat 再数。
count_in() {   # $1=模式 $2...=文件
  local pat="$1"; shift
  local n
  n=$(cat "$@" 2>/dev/null | grep -c "$pat" || true)
  printf '%s' "${n:-0}"
}

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

# 1. Plan 内部术语覆盖：Scope 提到的术语是否在 Tasks 中有落地
# ⚠️ 原实现标为「Spec → Plan」，但**只读了 PLAN 一个文件**——没有任何 spec 输入，等于拿 PLAN 和自己比。
#    本 suite 也没有 spec artifact，所以改为如实描述：查 PLAN 内部 Scope→Tasks 的术语覆盖（2026-09-18）。
echo "## 1. Plan 内部术语覆盖（Scope → Tasks）" >> "$REPORT"
if compgen -G "$KNOWLEDGE_DIR/proposals/PLAN-*.md" > /dev/null 2>&1; then
  spec_terms=$(cat "$KNOWLEDGE_DIR"/proposals/PLAN-*.md 2>/dev/null | grep -oE "上传|upload|avatar|头像" | sort -u || true)
  sec1_issues=0
  for term in $spec_terms; do
    plan_has=$(count_in "$term" "$KNOWLEDGE_DIR"/proposals/PLAN-*.md)
    if [ "$plan_has" -lt 2 ]; then
      echo "- ⚠️ PLAN 提到 '$term' 但 Tasks 段未见对应落地（全文命中 $plan_has 次，< 2）" >> "$REPORT"
      sec1_issues=$((sec1_issues + 1))
      ISSUES=$((ISSUES + 1))
    fi
  done
  [ "$sec1_issues" -eq 0 ] && echo "✅ Scope 术语均在 PLAN 内有对应（无孤立术语）" >> "$REPORT"
else
  echo "ℹ️  无 PLAN，跳过" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 2. Plan → Architecture: plan decisions → architecture decisions
echo "## 2. Plan → Architecture" >> "$REPORT"
if compgen -G "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-*.md" > /dev/null 2>&1; then
  plan_decisions=$(count_in "Decision\|decision\|决策" "$KNOWLEDGE_DIR"/proposals/PLAN-*.md)
  arch_decisions=$(count_in "###\|Decision\|ADR" "$KNOWLEDGE_DIR"/decisions/ARCHITECTURE-*.md)
  if [ "$arch_decisions" -ge "$plan_decisions" ]; then
    echo "✅ Architecture 覆盖 plan decisions（$arch_decisions ≥ $plan_decisions）" >> "$REPORT"
  else
    echo "- ⚠️ Plan 有 $plan_decisions 处 decisions，Architecture 仅覆盖 $arch_decisions" >> "$REPORT"
    ISSUES=$((ISSUES + 1))
  fi
fi
echo "" >> "$REPORT"

# 3. Architecture 规模（信息项，**不做断言**）
# ⚠️ 原实现在此假装检查「tasks 是否覆盖 components」——代码里没有比对，只有一句 echo 说
#    "verify tasks cover them"，既无数也无论断。改为如实标注为信息项（2026-09-18）。
echo "## 3. Architecture 规模（信息项，非断言）" >> "$REPORT"
if compgen -G "$KNOWLEDGE_DIR/decisions/ARCHITECTURE-*.md" > /dev/null 2>&1; then
  arch_components=$(count_in "component\|Component\|模块\|module" "$KNOWLEDGE_DIR"/decisions/ARCHITECTURE-*.md)
  echo "  ℹ️  Architecture 提及 $arch_components 处组件/模块（本脚本**不判断** tasks 是否覆盖——无可靠映射，需人工或 V8 语义复核）" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 4. Principle Compliance: do plan/architecture respect project principles?
echo "## 4. Principle Compliance" >> "$REPORT"
# ⚠️ 原路径是 `$KNOWLEDGE_DIR/../runtime/contracts/...` = **项目根目录**的 runtime/，
#    真实项目里没有这个文件 → 本节**永不执行**（静默跳过）。这里应为**套件自身**的 runtime/（2026-09-18 修）。
PRINCIPLES="$SUITE_ROOT/runtime/contracts/project-principles.schema.yaml"
if [ -f "$PRINCIPLES" ]; then
  principles=$(count_in "principle\." "$PRINCIPLES")
  echo "  套件声明 $principles 条 principle" >> "$REPORT"
  # Check if PLAN mentions principles
  plan_principles=$(count_in "principle\|Principle\|原则" "$KNOWLEDGE_DIR"/proposals/PLAN-*.md)
  if [ "$plan_principles" -gt 0 ]; then
    echo "  ✅ Plan references $plan_principles principles" >> "$REPORT"
  else
    echo "  ⚠️ Plan does not reference project principles" >> "$REPORT"
  fi
else
  echo "  ℹ️  未找到 $PRINCIPLES，跳过" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "## 5. ID Traceability（Decision-traceable）" >> "$REPORT"
echo "" >> "$REPORT"

# 5a. 提取 Requirement 定义（R-xxx: 列表项）与 Task 的 satisfies 引用（区分定义 vs 引用，避免空转）
if compgen -G "$KNOWLEDGE_DIR/proposals/PLAN-*.md" > /dev/null 2>&1; then
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
if compgen -G "$KNOWLEDGE_DIR/proposals/PLAN-*.md" > /dev/null 2>&1; then
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
# ⚠️ 原先这一行标签是「Spec → Plan」，值却取**全局** ISSUES（含 §2/§4/§5/§6 的 issue），
#    即标签与数值不是一回事。改为如实分列（2026-09-18）。
echo "| 全部检查（合计） | $([ "$ISSUES" -eq 0 ] && echo '✅ 无 issue' || echo "⚠️ $ISSUES issue(s)") |" >> "$REPORT"
echo "| 其中 §5 ID 孤立引用 | $([ "${orphan_ids:-0}" -eq 0 ] && echo '✅' || echo "⚠️ ${orphan_ids}") |" >> "$REPORT"

echo "Report: $REPORT"
[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
