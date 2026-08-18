#!/bin/bash
# Consistency Checker v1.0
#
# 检查「声明链」各层一致性：
#   skill.yaml → skill-ir → registry → compatibility → benchmarks
#
# 第 6 层「实际行为」明确排除——行为验证需 spawn agent 跑真实任务（benchmark），无法自动。
# 本脚本只做「静态可判定」的一致性：字段/版本号/硬约束，任何一层不一致 → exit 1。
#
# Usage: bash shared/scripts/check-consistency.sh
#
# 覆盖层：
#   L1  skill.yaml ↔ skill-ir        字段一致性（id/version/produces/consumes/stages）
#   L2  skill.yaml ↔ registry        漂移检测（复用 generate-registry.mjs --check）
#   L3  skill.yaml ↔ compatibility   版本号 + skill 集合一致性
#   L4  benchmarks 硬约束            技术栈硬编码 / 已废弃的 benchmark 要求
#   L5  实际行为                      排除（标注需 benchmark 手动验证）

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

red()    { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }

FAIL=0; WARN=0; PASS=0

echo "========================================"
echo " Consistency Check（声明链一致性）"
echo "========================================"
echo ""

# ── L1: skill.yaml ↔ skill-ir ──────────────────────────────
echo "【L1】skill.yaml ↔ skill-ir 字段一致性"
echo "----------------------------------------"

grab_field() {
  # $1=file, $2=字段名（顶层，非缩进），提取值去掉引号
  grep "^$2:" "$1" 2>/dev/null | sed "s/^$2:[[:space:]]*//" | tr -d '"' | tr -d ' '
}

grab_stages() {
  # skill.yaml 的 stages 在 interface 块内（缩进），skill-ir 在顶层
  # $1=file, $2=是否缩进（"indent" 或 "top"）
  if [ "$2" = "indent" ]; then
    grep -E "^[[:space:]]+stages:" "$1" 2>/dev/null | sed 's/.*stages:[[:space:]]*//' | tr -d '[]' | tr -d ' '
  else
    grep "^stages:" "$1" 2>/dev/null | sed 's/^stages:[[:space:]]*//' | tr -d '[]' | tr -d ' '
  fi
}

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  sy="$skill_dir/skill.yaml"
  si="$skill_dir/skill-ir.yaml"
  [ -f "$sy" ] || continue

  if [ ! -f "$si" ]; then
    red "  ❌ $skill: skill-ir.yaml 缺失（未运行 generate-skill-ir.sh）"
    FAIL=$((FAIL+1)); continue
  fi

  mismatches=""
  for field in id version produces consumes; do
    a=$(grab_field "$sy" "$field")
    b=$(grab_field "$si" "$field")
    [ "$a" != "$b" ] && mismatches="$mismatches $field($a≠$b)"
  done
  # stages 单独处理（skill.yaml 缩进，skill-ir 顶层）
  sa=$(grab_stages "$sy" "indent")
  sb=$(grab_stages "$si" "top")
  [ "$sa" != "$sb" ] && mismatches="$mismatches stages($sa≠$sb)"

  if [ -n "$mismatches" ]; then
    red "  ❌ $skill: skill-ir 与 skill.yaml 不一致 —$mismatches"
    FAIL=$((FAIL+1))
  else
    green "  ✅ $skill"
    PASS=$((PASS+1))
  fi
done

echo ""
# ── L2: skill.yaml ↔ registry ──────────────────────────────
echo "【L2】skill.yaml ↔ registry 漂移"
echo "----------------------------------------"
if node "$SUITE_ROOT/shared/scripts/generate-registry.mjs" --check >/dev/null 2>&1; then
  green "  ✅ registry 无漂移"
  PASS=$((PASS+1))
else
  red "  ❌ registry 漂移（运行 node shared/scripts/generate-registry.mjs）"
  FAIL=$((FAIL+1))
fi

echo ""
# ── L3: skill.yaml ↔ compatibility ─────────────────────────
echo "【L3】skill.yaml ↔ compatibility 版本/集合一致性"
echo "----------------------------------------"
COMPAT="$SUITE_ROOT/runtime/registry/compatibility.yaml"

# 提取 current 块（精确限定：从 ^current: 到第一个 ^# 或 ^matrix: 为止）
compat_current=$(awk '/^current:/{f=1;next} /^[^ ]/{f=0} f' "$COMPAT")

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  sy="$skill_dir/skill.yaml"
  [ -f "$sy" ] || continue
  sy_ver=$(grep '^version:' "$sy" | sed 's/version: *"//;s/"//' | tr -d ' ')

  # 元执行器 pipeline-orchestrator 有意排除（generate-registry.mjs 也不纳入），跳过
  if [ "$skill" = "pipeline-orchestrator" ]; then
    continue
  fi

  # 从 current 块提取该 skill 的版本（精确匹配 current 块内的行）
  compat_ver=$(echo "$compat_current" | grep -E "^\s+${skill}:" | sed 's/.*"\(.*\)"/\1/' | tr -d ' ')

  if [ -z "$compat_ver" ]; then
    yellow "  ⚠️ $skill: compatibility.current 无此 skill（版本号未登记）"
    WARN=$((WARN+1))
  elif [ "$compat_ver" != "$sy_ver" ]; then
    red "  ❌ $skill: compatibility 版本 $compat_ver ≠ skill.yaml $sy_ver"
    FAIL=$((FAIL+1))
  else
    green "  ✅ $skill ($sy_ver)"
    PASS=$((PASS+1))
  fi
done

echo ""
# ── L4: benchmarks 硬约束 ──────────────────────────────────
echo "【L4】benchmarks 硬约束（技术栈硬编码 / 已废弃要求）"
echo "----------------------------------------"
BENCH="$SUITE_ROOT/docs/benchmarks.md"

# 已废弃的硬编码（与「技术栈由 context 决定」通用化设计冲突）
blocklist=(
  "\.vue"          # 硬编码 Vue SFC 扩展名
  "Vue SFC"        # 硬编码 Vue 组件
  "atomic_commits" # refactorer 已禁用 git commit 动作
)
L4_FAIL=0
for pattern in "${blocklist[@]}"; do
  if grep -n "$pattern" "$BENCH" >/dev/null 2>&1; then
    red "  ❌ benchmarks.md 含已废弃硬约束: $pattern"
    L4_FAIL=$((L4_FAIL+1))
  fi
done
if [ "$L4_FAIL" -eq 0 ]; then
  green "  ✅ benchmarks.md 无技术栈硬编码 / 无已废弃 git commit 要求"
  PASS=$((PASS+1))
else
  FAIL=$((FAIL+L4_FAIL))
fi

echo ""
# ── L5: 实际行为（排除）────────────────────────────────────
echo "【L5】实际行为"
echo "----------------------------------------"
yellow "  ⚠️ 排除——行为验证需 spawn agent 跑真实任务（benchmark），无法自动判定。"
yellow "     本层由 project-suite-eval/benchmark/ 手动验证，不在此脚本覆盖范围内。"

echo ""
echo "========================================"
echo " Summary"
echo "========================================"
echo "  Pass:    $PASS"
echo "  Warning: $WARN"
echo "  Fail:    $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  red "❌ CONSISTENCY CHECK FAILED — $FAIL 处不一致，需修复"
  exit 1
else
  if [ "$WARN" -gt 0 ]; then
    yellow "⚠️ CONSISTENCY CHECK PASSED with warnings — $WARN 处警告"
  else
    green "✅ CONSISTENCY CHECK PASSED — 声明链各层一致"
  fi
  exit 0
fi
