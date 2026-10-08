#!/bin/bash
# KB Contract Completeness Gate v1.0
#
# 断言一个 `.project-knowledge/` 是否满足**产出契约**：目录集合 + 固定根产物。
# 这是 analyzer 交付阶段的**阻断门禁**——不满足即不可声明 status: completed。
#
# 为什么要它（2026-09-30 实证）：
#   同一套 project-analyzer skill 在真实项目上跑出的产出结构差异可达 10 倍：
#     有的项目契约目录 / 根 JSON 基本齐全；有的只产出 1/14 目录、0/5 根 JSON。
#   根因不是 agent 能力，而是**技能规格自相矛盾**：产出结构在 5 处各自声明且互不相同
#   （output-format.md 树 / knowledge-builder.md Coverage Gate / main.md Wave 表 /
#     validation.md V7 / capability-matrix.md 固定产出），且 finish-workflow.md
#   （规定「statistics/context/graph/search-index 每次扫描必定执行」）**零个 stage 引用它**。
#   同时既有门禁「只标注不阻断」（validation.md V7 / finish-workflow.md Phase D），
#   于是 13/14 目录缺失仍能声明 completed——这正是治理文档要防的「假完成」。
#
# 本脚本是那些散落清单的**单一执行点**：目录集合从契约派生、不硬编码。
#
# Usage: bash shared/scripts/check-kb-contract.sh <project-knowledge-dir>
# Exit:  0 = 契约满足, 1 = 有缺失项, 2 = 参数不是 .project-knowledge 目录
#
# ⚠️ 参数守卫（沿用 check-artifacts.sh 的约定）：本脚本把报告**写在参数目录内**。
#    若误传项目根，报告会落到项目根，违反「生成产物一律进 .project-knowledge/」。
#    故先校验参数，不合格直接拒绝。

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KNOWLEDGE_DIR="${1:-.project-knowledge}"

case "$KNOWLEDGE_DIR" in
  *.project-knowledge|project-knowledge) : ;;
  *)
    echo "❌ 参数应为 .project-knowledge 目录，收到：$KNOWLEDGE_DIR" >&2
    echo "   本脚本会在参数目录内写 kb-contract-report.md——传错会把产物落到项目根。" >&2
    echo "   Usage: bash shared/scripts/check-kb-contract.sh <project-knowledge-dir>" >&2
    exit 2
    ;;
esac

# ── 目录集合：从契约的生成片段读取，**不硬编码** ────────────────────────
# 为什么读生成片段而不是直接读 YAML：本 Suite 的 bash 脚本保持零依赖
# （见 generate-knowledge-dirs.mjs 的说明）。该片段由契约派生，是 SSOT 的唯一投影。
# 若在脚本里另写一份目录清单，就是在制造第 6 份口径——正是本次修复要消除的东西。
KD_FRAGMENT="$SCRIPT_DIR/knowledge-directories.generated.sh"
if [ ! -f "$KD_FRAGMENT" ]; then
  echo "❌ 找不到契约生成片段：$KD_FRAGMENT" >&2
  echo "   → 先跑：node shared/scripts/generate-knowledge-dirs.mjs" >&2
  exit 2
fi
# shellcheck source=/dev/null
. "$KD_FRAGMENT"

# ── 固定根产物：每次扫描必定生成（output-format.md「固定产出结构」+ capability-matrix.md「固定产出」）──
# 注意**不含** knowledge-index.json / context-package.json：那两个由 Compiler / Resolver 产出，
# 不是 analyzer 的交付物，缺了不算 analyzer 违约。
ROOT_ARTIFACTS="manifest.json statistics.json context.json graph.json search-index.json index.md"

if [ ! -d "$KNOWLEDGE_DIR" ]; then
  echo "⚠️ SKIP: $KNOWLEDGE_DIR 不存在（尚无知识库，非契约违约）"
  exit 0
fi

REPORT="$KNOWLEDGE_DIR/kb-contract-report.md"
ISSUES=0

{
  echo "# KB Contract Completeness Report"
  echo "> $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "> 契约: shared/schemas/knowledge-directories.yaml (v${KD_CONTRACT_VERSION:-?})"
  echo ""
} > "$REPORT"

# ── 1. 契约声明的目录必须存在 ──────────────────────────────────────────
# 契约（output-format.md「目录初次运行时全部创建」）要求一次分析后全部目录在位——
# 因为下游 skill 按目录读取，缺目录 = 知识链断裂，不是「这个项目没有该维度」。
MISSING_DIRS=""
for d in $KD_ALL; do
  [ -d "$KNOWLEDGE_DIR/$d" ] || MISSING_DIRS="$MISSING_DIRS $d"
done
TOTAL_DIRS=$(echo "$KD_ALL" | wc -w | tr -d ' ')
PRESENT_DIRS=$((TOTAL_DIRS - $(echo "${MISSING_DIRS:- }" | wc -w | tr -d ' ')))

if [ -n "$MISSING_DIRS" ]; then
  {
    echo "## ❌ 缺失的契约目录（$PRESENT_DIRS/$TOTAL_DIRS 在位）"
    echo ""
    echo "| 缺失目录 | 生产方 |"
    echo "|---------|--------|"
  } >> "$REPORT"
  for d in $MISSING_DIRS; do
    prod="$(echo "$KD_BY_PRODUCER" | tr ' ' '\n' | grep "^${d}:" | cut -d: -f2-)"
    echo "| \`$d/\` | ${prod:-?} |" >> "$REPORT"
  done
  echo "" >> "$REPORT"
  ISSUES=$((ISSUES + $(echo "$MISSING_DIRS" | wc -w | tr -d ' ')))
else
  echo "## ✅ 契约目录齐全（$TOTAL_DIRS/$TOTAL_DIRS）" >> "$REPORT"
  echo "" >> "$REPORT"
fi

# ── 2. 固定根产物必须存在（**大小写精确**）──────────────────────────────
# 大小写为什么要专门查：`[ -f index.md ]` 在 macOS 的大小写不敏感 APFS 上对 `INDEX.md`
# 也同样为真，于是「索引文件名漂移」在开发机上永远测不出来，却在大小写敏感的 CI/Linux
# 上直接 404。实证：真实产出里出现过 `INDEX.md`（大写），而契约是小写 `index.md`。
# 做法：比对 `ls` 输出的**真实文件名**，而非用 test 去猜。
ACTUAL_NAMES="$(ls -1 "$KNOWLEDGE_DIR" 2>/dev/null || true)"
MISSING_ROOT=""
BAD_CASE=""
for f in $ROOT_ARTIFACTS; do
  if printf '%s\n' "$ACTUAL_NAMES" | grep -qx -- "$f"; then
    continue
  fi
  # 存在但大小写不符？→ 单独归类，给出比「缺失」更准确的信息
  lower="$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')"
  actual="$(printf '%s\n' "$ACTUAL_NAMES" | grep -ix -- "$f" || true)"
  if [ -n "$actual" ] && [ "$actual" != "$f" ]; then
    BAD_CASE="$BAD_CASE ${actual}→${f}"
  else
    MISSING_ROOT="$MISSING_ROOT $f"
  fi
done

if [ -n "$MISSING_ROOT" ] || [ -n "$BAD_CASE" ]; then
  echo "## ❌ 固定根产物缺失或命名不符" >> "$REPORT"
  echo "" >> "$REPORT"
  if [ -n "$MISSING_ROOT" ]; then
    echo "**完全缺失：**" >> "$REPORT"
    for f in $MISSING_ROOT; do echo "- \`$f\`" >> "$REPORT"; done
    echo "" >> "$REPORT"
    ISSUES=$((ISSUES + $(echo "$MISSING_ROOT" | wc -w | tr -d ' ')))
  fi
  if [ -n "$BAD_CASE" ]; then
    echo "**存在但大小写不符（在大小写敏感的 CI/Linux 上会 404）：**" >> "$REPORT"
    for p in $BAD_CASE; do echo "- \`$p\`" >> "$REPORT"; done
    echo "" >> "$REPORT"
    ISSUES=$((ISSUES + $(echo "$BAD_CASE" | wc -w | tr -d ' ')))
  fi
else
  echo "## ✅ 固定根产物齐全（$(echo "$ROOT_ARTIFACTS" | wc -w | tr -d ' ') 项，大小写精确）" >> "$REPORT"
  echo "" >> "$REPORT"
fi

# ── Summary ────────────────────────────────────────────────────────────
{
  echo "## Summary"
  echo ""
  echo "| Check | Status |"
  echo "|-------|--------|"
  echo "| 契约目录 | $([ -n "$MISSING_DIRS" ] && echo "❌ $PRESENT_DIRS/$TOTAL_DIRS 在位" || echo "✅ $TOTAL_DIRS/$TOTAL_DIRS") |"
  echo "| 固定根产物 | $([ -n "$MISSING_ROOT" ] || [ -n "$BAD_CASE" ] && echo "❌ 有缺失/命名不符" || echo "✅ 齐全") |"
  echo "| 合计 | $([ "$ISSUES" -eq 0 ] && echo '✅ 契约满足' || echo "⛔ $ISSUES 项违约") |"
} >> "$REPORT"

echo "Report: $REPORT"
if [ "$ISSUES" -gt 0 ]; then
  echo "⛔ 契约未满足（$ISSUES 项）——不可声明 status: completed。详见 $REPORT"
  exit 1
fi
echo "✅ 契约满足"
exit 0
