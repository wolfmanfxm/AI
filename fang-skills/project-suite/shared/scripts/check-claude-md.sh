#!/bin/bash
# Project Entry Gate — 项目级 CLAUDE.md
#
# 断言项目根的 agent 自动化入口存在且**确实指向知识库**：
#   <project-root>/.claude/CLAUDE.md
#
# 为什么要它：
#   入口的创建/追加动作若被写成「更新一个已存在文件的统计数字」，就**预设了文件已存在**——
#   文件缺失时静默跳过、永不报错，结果是入口从不出现在新项目上：知识库存在，但没人被自动告知。
#   故本门禁断言的是**产出**（`<root>/.claude/CLAUDE.md` 真的存在、真的指向知识库），
#   不是「有没有执行过某个更新动作」。入口的写入三态（不存在→创建 / 无 KB 引用→追加 /
#   已有引用→只刷标记）由 analyzer 在 finish-workflow.md 步骤 13 执行，本脚本只做产出断言。
#
# 本脚本与 check-kb-contract.sh 是**互补**的两半：
#   check-kb-contract.sh   管 .project-knowledge/ 内部（契约目录 + 根产物）= 知识是否成型
#   check-claude-md.sh     管 .project-knowledge/ 之外（项目根入口）= 知识是否**被送达 agent**
# 缺前者 = 知识链断在结构；缺后者 = 知识链断在入口。
#
# Usage: bash shared/scripts/check-claude-md.sh <project-root>
# Exit:  0 = 入口满足, 1 = 有违约项, 2 = 参数不是含 .project-knowledge/ 的项目根
#
# ⚠️ 参数守卫：本脚本把报告写在 <项目根>/.project-knowledge/ 内（生成产物一律进知识库）。
#    故参数必须是「含 .project-knowledge/ 的目录」——误传 src/ 之类的子目录会把报告落错位置。

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${1:-.}"

if [ ! -d "$PROJECT_ROOT/.project-knowledge" ]; then
  echo "❌ 参数应为**项目根**（须含 .project-knowledge/），收到：$PROJECT_ROOT" >&2
  echo "   本脚本会在参数目录的 .project-knowledge/ 内写 claude-md-report.md。" >&2
  echo "   Usage: bash shared/scripts/check-claude-md.sh <project-root>" >&2
  exit 2
fi
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

CLAUDE_DIR="$PROJECT_ROOT/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
ST_JSON="$PROJECT_ROOT/.project-knowledge/statistics.json"
REPORT="$PROJECT_ROOT/.project-knowledge/claude-md-report.md"

ISSUES=0

{
  echo "# Project Entry Report (.claude/CLAUDE.md)"
  echo "> $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "> 断言：项目根 agent 入口存在且指向知识库"
  echo ""
} > "$REPORT"

# ── 1. 文件必须存在（**大小写精确**）──────────────────────────────────
# 与 check-kb-contract.sh 同理：`[ -f .claude/claude.md ]` 在 macOS 不敏感 APFS 上为真，
# 在 CI/Linux 上 404。故比对 `ls` 的真实文件名，而不是用 test 去猜。
ACTUAL="$(ls -1 "$CLAUDE_DIR" 2>/dev/null || true)"
MISSING=0
if [ -z "$ACTUAL" ]; then
  MISSING=1
  WHY="整个 .claude/ 目录不存在"
elif ! printf '%s\n' "$ACTUAL" | grep -qx -- "CLAUDE.md"; then
  MISSING=1
  alt="$(printf '%s\n' "$ACTUAL" | grep -ix -- "CLAUDE.md" || true)"
  if [ -n "$alt" ]; then WHY="存在 \`$alt\` 但**大小写不符**（CI/Linux 上会 404）"
  else WHY=".claude/ 下无 CLAUDE.md"; fi
fi

if [ "$MISSING" -eq 1 ]; then
  {
    echo "## ❌ agent 入口缺失"
    echo ""
    echo "$WHY"
    echo ""
    echo "**动作**：按 suite 内 \`skills/project-analyzer/references/finish-workflow.md\` 步骤 13"
    echo "创建 \`<项目根>/.claude/CLAUDE.md\`——知识库指针 + 「开发前必读」路由表 + \`kb-stats\` 标记。"
    echo ""
  } >> "$REPORT"
  ISSUES=$((ISSUES + 1))
else
  echo "## ✅ 入口文件存在" >> "$REPORT"
  echo "" >> "$REPORT"
fi

# ── 2. 指向知识库 + 3. kb-stats 标记与 statistics.json 一致 ────────────
if [ "$MISSING" -eq 0 ]; then
  # 2a. 必须提到 .project-knowledge/
  if ! grep -q -- '\.project-knowledge/' "$CLAUDE_MD"; then
    {
      echo "## ❌ 未引用知识库"
      echo ""
      echo "文件存在，但不含任何 \`.project-knowledge/\` 引用——agent 被自动加载后"
      echo "仍不知道知识库在哪。**存在 ≠ 送达。**"
      echo ""
    } >> "$REPORT"
    ISSUES=$((ISSUES + 1))
  fi

  # 2b. 必须给出 index.md 入口链接
  if ! grep -q -- '\.project-knowledge/index\.md' "$CLAUDE_MD"; then
    {
      echo "## ❌ 缺 index.md 入口链接"
      echo ""
      echo "找不到 \`.project-knowledge/index.md\` 链接——导航入口未落进 CLAUDE.md。"
      echo ""
    } >> "$REPORT"
    ISSUES=$((ISSUES + 1))
  fi

  # 3. kb-stats 标记 ← 把「统计数字更新」从不可核的散文变成可核的断言
  marker="$(grep -o 'kb-stats:[^>]*' "$CLAUDE_MD" 2>/dev/null | head -1 || true)"
  m_files="$(printf '%s' "$marker" | grep -o 'files=[0-9][0-9]*' | head -1 | cut -d= -f2 || true)"
  m_lines="$(printf '%s' "$marker" | grep -o 'lines=[0-9][0-9]*' | head -1 | cut -d= -f2 || true)"

  if [ -z "$marker" ] || [ -z "$m_files" ] || [ -z "$m_lines" ]; then
    {
      echo "## ❌ 缺 kb-stats 标记或标记不完整"
      echo ""
      echo "要求首行含：\`<!-- kb-stats: files=<N> lines=<M> generated=<ISO8601> -->\`"
      echo ""
      echo "没有这个标记，「统计数字不更新」就只能靠人眼看——正是它此前退化后无人察觉的原因。"
      echo "标记让门禁能机械比对，无需解析散文格式。"
      echo ""
    } >> "$REPORT"
    ISSUES=$((ISSUES + 1))
  elif [ ! -f "$ST_JSON" ]; then
    {
      echo "## ⚠️ 有标记但无法核对"
      echo ""
      echo "statistics.json 不存在，无法比对 kb-stats 数字。"
      echo ""
    } >> "$REPORT"
    ISSUES=$((ISSUES + 1))
  else
    st_num() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" "$ST_JSON" | head -1; }
    st_files="$(st_num totalSourceFiles)"
    st_lines="$(st_num totalLines)"
    drift=""
    [ -n "$st_files" ] && [ "$m_files" != "$st_files" ] && drift="$drift files(标记 $m_files ≠ statistics $st_files)"
    [ -n "$st_lines" ] && [ "$m_lines" != "$st_lines" ] && drift="$drift lines(标记 $m_lines ≠ statistics $st_lines)"
    if [ -n "$drift" ]; then
      {
        echo "## ❌ kb-stats 与 statistics.json 不一致（统计数字过期）"
        echo ""
        echo "| 字段 | CLAUDE.md 标记 | statistics.json |"
        echo "|------|----------------|-----------------|"
        [ -n "$st_files" ] && echo "| files | $m_files | $st_files |"
        [ -n "$st_lines" ] && echo "| lines | $m_lines | $st_lines |"
        echo ""
        echo "**动作**：按 finish-workflow.md 步骤 13 用本次 statistics.json 重写首行标记。"
        echo ""
      } >> "$REPORT"
      ISSUES=$((ISSUES + 1))
    else
      echo "## ✅ kb-stats 与 statistics.json 一致（files=$m_files lines=$m_lines）" >> "$REPORT"
      echo "" >> "$REPORT"
    fi
  fi
fi

# ── Summary ────────────────────────────────────────────────────────────
{
  echo "## Summary"
  echo ""
  echo "| Check | Status |"
  echo "|-------|--------|"
  echo "| 项目根 .claude/CLAUDE.md | $([ "$MISSING" -eq 1 ] && echo '❌ 缺失' || echo '✅') |"
  echo "| 合计 | $([ "$ISSUES" -eq 0 ] && echo '✅ 入口满足' || echo "⛔ $ISSUES 项违约") |"
} >> "$REPORT"

echo "Report: $REPORT"
if [ "$ISSUES" -gt 0 ]; then
  echo "⛔ 项目级 agent 入口未满足（$ISSUES 项）——知识库存在但未被送达 agent。详见 $REPORT"
  exit 1
fi
echo "✅ 入口满足"
exit 0
