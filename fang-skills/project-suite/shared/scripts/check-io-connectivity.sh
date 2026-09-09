#!/bin/bash
# I/O Connectivity Checker v1.0
#
# 语义一致性检查：只查「能接通」，不查「完全相等」。
# 三层 I/O 是三个不同视图（见 ADR-004 / SUITE_SPEC §0），本脚本不要求它们字面一致，
# 只验证：
#   1. type 合法性 —— interface.inputs/outputs 的 type 必须是合法类型
#      （13 个 artifact type + context-package 知识注入标记）
#   2. input source 连通 —— 若 input.source 是某 skill，该 skill 顶层 produces
#      必须含「映射到该 type 的 Capability」（Producer → Consumer 能接通）
#   3. output → produces —— skill 自己的 output type 必须能映射到其顶层 produces 的 Capability
#
# Usage: bash shared/scripts/check-io-connectivity.sh
# Exit:  0 = 全部能接通；1 = 存在语义不通（错标 type / 来源断链 / 产出无 Capability）

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

# Capability → Artifact Type（bash 3.2 兼容，用 case 而非关联数组）
type_to_cap() {
  case "$1" in
    knowledge)        echo KnowledgeBase ;;
    recommendation)   echo Recommendation ;;
    context)          echo Context ;;
    graph)            echo Graph ;;
    planning)         echo Plan ;;
    design)           echo Architecture ;;
    implementation)   echo Code ;;
    test)             echo Test ;;
    review)           echo Review ;;
    refactored-code)  echo RefactoredCode ;;
    documentation)    echo Documentation ;;
    release)          echo Release ;;
    *)                echo "" ;;
  esac
}

# 合法 type：13 artifact type + 1 知识注入标记（state/request 无 Capability，仅作类型）
VALID_TYPES="knowledge recommendation context graph planning design implementation test review refactored-code documentation release state request context-package"

# 非 skill 的 source（外部输入，不查 produces）
NON_SKILL_SOURCES="user git knowledge-resolver knowledge-compiler runtime ALL"

# 某 skill 顶层 produces（逗号分隔，无空格）
produces_of() {
  grep -E '^produces:' "$SKILLS_DIR/$1/skill.yaml" | sed 's/^produces: *\[//;s/\] *$//' | tr -d ' '
}

FAIL=0
red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

echo "========================================"
echo " I/O Connectivity Check（能接通 ≠ 相等）"
echo "========================================"
echo ""

for sy in "$SKILLS_DIR"/*/skill.yaml; do
  s=$(basename "$(dirname "$sy")")

  # interface 块内所有含 type: 的条目（inputs 有 source，outputs 无 source）
  lines=$(sed -n '/^interface:/,$p' "$sy" | grep -E 'type: [a-z-]+')

  while IFS= read -r line; do
    type=$(echo "$line" | grep -oE 'type: [a-z-]+' | sed 's/type: //' | head -1)
    source=$(echo "$line" | grep -oE 'source: [A-Za-z-]+' | sed 's/source: //')
    [ -z "$type" ] && continue

    # 1. type 合法性
    if ! echo " $VALID_TYPES " | grep -q " $type "; then
      red "  ❌ $s: 非法 type '$type'（不在 artifact-types 也不在 context-package 标记）"
      FAIL=$((FAIL+1)); continue
    fi

    if [ -n "$source" ]; then
      # 2. input：source 是 skill 时，查它的 produces 能否提供该 type 的 Capability
      if ! echo " $NON_SKILL_SOURCES " | grep -q " $source "; then
        cap=$(type_to_cap "$type")
        if [ -n "$cap" ] && ! echo ",$(produces_of "$source")," | grep -q ",$cap,"; then
          red "  ❌ $s: input '$type' 来源 $source，但 $source.produces 无 Capability '$cap'（断链）"
          FAIL=$((FAIL+1))
        fi
      fi
    else
      # 3. output：自身 produces 能否提供该 type 的 Capability
      cap=$(type_to_cap "$type")
      if [ -n "$cap" ] && ! echo ",$(produces_of "$s")," | grep -q ",$cap,"; then
        red "  ❌ $s: output type '$type' 无法映射到自身 produces 的 '$cap'（产出无对应 Capability）"
        FAIL=$((FAIL+1))
      fi
    fi
  done <<< "$lines"
done

echo ""
if [ "$FAIL" -gt 0 ]; then
  red "❌ I/O CONNECTIVITY FAILED — $FAIL 处语义不通"
  exit 1
else
  green "✅ I/O CONNECTIVITY PASSED — type 合法、source→produces 能接通、output 有对应 Capability"
  exit 0
fi
