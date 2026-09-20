#!/bin/bash
# Skill IR Generator v2.1
# 从 skill.yaml + SKILL.md 蒸馏出机器可读的 10 字段 IR。
# 只提取机器真正需要的字段：id / version / mode / description / produces / consumes / stages / last_reviewed / boundary
#
# Usage:
#   bash shared/scripts/generate-skill-ir.sh            # 生成全部
#   bash shared/scripts/generate-skill-ir.sh <skill>    # 只生成一个（可省略 project- 前缀）
#   bash shared/scripts/generate-skill-ir.sh --check    # 只校验是否与源同步（漂移检测），不写盘
# Exit: --check 模式下有漂移 → 1

set -euo pipefail
SUITE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

CHECK=0
TARGET="all"
case "${1:-}" in
  --check) CHECK=1 ;;
  "")      ;;
  *)       TARGET="$1" ;;
esac

DRIFT=""
EMPTY_VERIFY=""

gen() {
  local dir="$1"
  local name=$(basename "$dir")
  local y="$dir/skill.yaml" m="$dir/SKILL.md"
  [ ! -f "$y" ] && return

  local id version mode produces consumes stages last_reviewed boundary

  # From skill.yaml — simple grep for flat fields
  id=$(grep "^id:" "$y" | sed 's/^id: *//')
  version=$(grep "^version:" "$y" | sed 's/^version: *"//;s/"//' | tr -d ' ')
  mode=$(grep "^mode:" "$y" | sed 's/^mode: *//')
  produces=$(grep "^produces:" "$y" | sed 's/^produces: *//' | tr -d '[] ')
  consumes=$(grep "^consumes:" "$y" | sed 's/^consumes: *//' | tr -d '[] ')
  boundary=$(grep "^boundary:" "$y" | sed 's/^boundary: *//')
  last_reviewed=$(grep "last_reviewed:" "$y" | grep -o '"[^"]*"' | tr -d '"')
  stages=$(grep "stages:" "$y" | grep -o '\[.*\]' | tr -d '[]' | sed 's/, */, /g' | sed 's/^ *//;s/ *$//')

  # From SKILL.md — YAML multi-line description
  # 用单个 awk 提取（原实现是逐行 `echo|grep`/`echo|sed` 的 while 循环，
  # 每行 spawn 3-5 个进程 → 10 个 skill 要 8s；--check 要跑进检查链，必须快）
  local desc
  desc=$(head -15 "$m" | awk '
    /^description:/ { in_d=1; sub(/^description: *>?[ ]*/, ""); printf "%s", $0; next }
    in_d && (/^[a-z]+:/ || /^---/) { exit }
    in_d { sub(/^[ ]+/, ""); printf " %s", $0 }
  ')
  desc=$(printf '%s' "$desc" | sed 's/^ *//;s/ *$//')

  # 校验项数：数「首格是 V<数字>」的表格行（形如 `| V1 | 名称 | 判据 | 修复 |`）。
  # ⚠️ 不能用 `grep -c "| V"` —— 那还会匹配判定表里的 `| Verify 1 失败 | ... |`，
  #    于是 analyzer 报 10 而它的校验项其实只有 6 个（实测 2026-09-17）。
  # 检查项的**唯一权威是 validation.md**（2026-09-18 收敛：verifier.md 不再重写检查表，
  # 只定义验证对象与判定规则）。此前从 verifier.md 数，收敛后会全部数成 0。
  local verify_checks=0
  if [ -f "$dir/prompts/validation.md" ]; then
    verify_checks=$(grep -cE '^\| V[0-9]+ \|' "$dir/prompts/validation.md" 2>/dev/null || true)
    # 有 validation.md 却数出 0 项 = 该文件没用家族统一的 `| V<n> |` 表格形状 → 报出来，不静默写 0
    [ "$verify_checks" -eq 0 ] && EMPTY_VERIFY="$EMPTY_VERIFY $name"
  fi

  # exit_criteria **已移除（2026-09-18）**：原 `conditions:` 数的是 execution.md 里**所有** `^- ` 行
  # （generator 报 23，而其 `## Exit` 真实只有 4 条；Phase 2 的 V1-V6、步骤子弹全被计入）。
  # 全仓零 Consumer（只有生成器自己写它）。没有消费者的派生字段不值得维护，而要「算准」就得写
  # 一个 Markdown 解析器——正是 SUITE_SPEC §0.1 要挡的形态。故整个字段删除，不做「修正计数」。

  # Extract failure conditions from skill.yaml interface block
  # ⚠️ 不要写 `$(grep -c X f || echo 0)`：零匹配时 grep 已打印 0 且 exit 1，`|| echo 0` 再补一个
  #    → 变量成两行 `0\n0` → 直接**写进 skill-ir.yaml 的 modes 字段**，产出坏 YAML（2026-09-18 修）。
  local failure_modes
  failure_modes=$(grep -c "condition:" "$y" 2>/dev/null || true); failure_modes=${failure_modes:-0}

  # Produce clean IR（先写临时文件：--check 模式需与现有文件逐字节比对）
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/skill-ir.XXXXXX")"
  cat > "$tmp" << EOF
# Skill IR: $id — machine-readable, regenerated on skill.yaml change
id: $id
version: "$version"
mode: $mode
description: "$desc"
boundary: "$boundary"
produces: [${produces}]
consumes: [${consumes}]
stages: [${stages}]
verification: { checks: ${verify_checks}, source: prompts/validation.md }
evidence: { format: knowledge-object.schema.json, source: graph.json }
failure_conditions: { modes: ${failure_modes}, levels: "WARNING→retry, DEGRADED→continue, BLOCKED→ask, FATAL→stop" }
last_reviewed: "${last_reviewed}"
EOF

  if [ "$CHECK" -eq 1 ]; then
    if [ ! -f "$dir/skill-ir.yaml" ]; then
      DRIFT="$DRIFT $name(缺失)"
    elif ! cmp -s "$tmp" "$dir/skill-ir.yaml"; then
      DRIFT="$DRIFT $name"
    fi
    rm -f "$tmp"
  else
    mv "$tmp" "$dir/skill-ir.yaml"
    echo "  ✅ $name"
  fi
}

if [ "$CHECK" -eq 1 ]; then
  echo "Skill IR Check"
  for d in "$SKILLS_DIR"/*/; do gen "$d"; done
  if [ -n "$DRIFT" ]; then
    echo "❌ skill-ir.yaml 与 skill.yaml 不同步:$DRIFT"
    echo "   → 运行 bash shared/scripts/generate-skill-ir.sh"
    exit 1
  fi
  echo "✅ 无漂移 — skill-ir.yaml 与 skill.yaml 一致"
  exit 0
fi

echo "Skill IR Generator v2.1"
if [ "$TARGET" = "all" ]; then
  for d in "$SKILLS_DIR"/*/; do gen "$d"; done
else
  gen "$SKILLS_DIR/project-$TARGET" 2>/dev/null || gen "$SKILLS_DIR/$TARGET"
fi
if [ -n "$EMPTY_VERIFY" ]; then
  echo "⚠️ 以下 skill 有 prompts/verifier.md，但 validation.md 里没有家族统一的 \`| V<n> |\` 校验表行，checks 记为 0:$EMPTY_VERIFY"
  echo "   → 补一张校验表，或确认该 skill 确实没有校验项（否则 0 是假的）"
fi
echo "Done."
