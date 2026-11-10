#!/bin/bash
# Knowledge Index Check v1.0
#
# Context Resolver 的前置检查。存在的意义：`knowledge-index.json` 缺失时，
# Resolver 会 exit 1（不是降级）；而旧协议把「Resolver 未实现」写成可以降级读 markdown，
# 于是 agent 绕过 Resolver 也能跑完——知识链断了却没人报错。
#
# 本脚本把「索引是否可用」变成一个显式前置条件：
#   - 缺失 / 非法 → exit 1，并给出确切的修复命令
#   - 存在但比最新的 .md 旧 → warning（不阻断：知识可能只是刚改过）
#
# Usage: bash shared/scripts/check-knowledge-index.sh [<project-root>|<knowledge-dir>]
# Exit: 0 = 可用；1 = 缺失/非法；2 = 参数错误
set -uo pipefail

TARGET="${1:-.}"
if [ -d "$TARGET/.project-knowledge" ]; then
  KD="$TARGET/.project-knowledge"
elif [ -d "$TARGET" ] && { [ -f "$TARGET/knowledge-index.json" ] || [ -f "$TARGET/manifest.json" ]; }; then
  KD="$TARGET"
else
  echo "❌ check-knowledge-index: 找不到知识库目录: $TARGET" >&2
  echo "   用法: bash shared/scripts/check-knowledge-index.sh <project-root>|<knowledge-dir>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX="$KD/knowledge-index.json"
COMPILER="$SCRIPT_DIR/knowledge-compiler.sh"

if [ ! -f "$INDEX" ]; then
  echo "❌ $INDEX 不存在" >&2
  echo "   Context Resolver 依赖它；这不是「降级读 markdown」的理由。" >&2
  echo "   修复: bash $COMPILER \"$KD\"" >&2
  echo "   若编译器因 compiler_enforced 字段缺失而拒绝，先补齐对应 frontmatter，再重跑。" >&2
  exit 1
fi

CHECK_OUT="$(node -e '
  const fs=require("fs");
  const p=process.argv[1];
  let d;
  try { d=JSON.parse(fs.readFileSync(p,"utf8")); }
  catch (e) { console.log("INVALID\t"+e.message); process.exit(0); }
  if (!d || typeof d!=="object" || Array.isArray(d)) { console.log("INVALID\t不是 JSON 对象"); process.exit(0); }
  if (!d.capabilities || typeof d.capabilities!=="object" || Array.isArray(d.capabilities)) {
    console.log("INVALID\t缺少 capabilities 对象"); process.exit(0);
  }
  // capabilities 有两代形态：v1.1 的 {group: {description, files:[...]}} 与
  // 早期直接是数组。只按数组计数会把 afc 的 8 组、几十个条目算成 0，
  // 从而误报「索引为空」。
  let total=0, groups=0;
  for (const v of Object.values(d.capabilities)) {
    groups++;
    if (Array.isArray(v)) total+=v.length;
    else if (v && typeof v==="object" && Array.isArray(v.files)) total+=v.files.length;
  }
  const stamp=typeof d.generatedAt==="string"?d.generatedAt:"";
  console.log("OK\t"+total+"\t"+stamp+"\t"+(d.schemaVersion||"")+"\t"+groups);
' "$INDEX" 2>/dev/null)"

STATE="$(printf '%s' "$CHECK_OUT" | cut -f1)"
if [ "$STATE" != "OK" ]; then
  echo "❌ $INDEX 非法: $(printf '%s' "$CHECK_OUT" | cut -f2)" >&2
  echo "   修复: bash $COMPILER \"$KD\"" >&2
  exit 1
fi

TOTAL="$(printf '%s' "$CHECK_OUT" | cut -f2)"
STAMP="$(printf '%s' "$CHECK_OUT" | cut -f3)"
SCHEMA="$(printf '%s' "$CHECK_OUT" | cut -f4)"
CAPABILITY_GROUPS="$(printf '%s' "$CHECK_OUT" | cut -f5)"

echo "OK knowledge-index.json schema=$SCHEMA entries=$TOTAL groups=$CAPABILITY_GROUPS generatedAt=$STAMP"

if [ "$TOTAL" -eq 0 ]; then
  echo "  ⚠️ 索引为空：Resolver 会产出空 context-package。若知识库确有 .md，检查它们的 frontmatter 是否满足 compiler_enforced 字段。" >&2
fi

# 陈旧检测：索引比最新的知识 .md 还旧 → 提示重编译（不阻断）
NEWEST=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ -z "$NEWEST" ] || [ "$f" -nt "$NEWEST" ]; then NEWEST="$f"; fi
done < <(find "$KD" -name '*.md' \
  -not -path '*/runtime/*' -not -path '*/reports/*' -not -path '*/proposals/*' -not -path '*/candidates/*' \
  -not -name '*-report.md' -not -name 'REVIEW-*' -not -name 'TEST-REPORT*' -not -name 'REFACTOR*' \
  2>/dev/null)

if [ -n "$NEWEST" ] && [ "$NEWEST" -nt "$INDEX" ]; then
  echo "  ⚠️ 索引早于 $NEWEST —— 可能已过期，建议重跑 knowledge-compiler.sh" >&2
fi

exit 0
