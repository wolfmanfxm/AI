#!/bin/bash
# I/O Connectivity Checker v1.0
#
# 语义一致性检查：只查「能接通」，不查「完全相等」。
# 三层 I/O 是三个不同视图（见 ADR-004 / SUITE_SPEC §0），本脚本不要求它们字面一致，
# 只验证：
#   1. type 合法性 —— interface.inputs/outputs 的 type 必须是合法类型
#      （runtime/artifacts/artifact-types.yaml 的 types + context-package 知识注入标记）
#   2. input source 连通 —— 若 input.source 是某 skill，该 skill 顶层 produces
#      必须含「映射到该 type 的 Capability」（Producer → Consumer 能接通）
#   3. output → produces —— skill 自己的 output type 必须能映射到其顶层 produces 的 Capability
#   4. knowledge directory contract —— .project-knowledge/ 目录契约（shared/schemas/knowledge-directories.yaml）
#      不变量：I1 扫描列表（由 compiler 自查）／I2 analyzer 写入 ⊆ 声明／I3 无死产出／生成片段新鲜度
#              I4 契约要求的 Producer 字段必须已在 analyzer 的字段表声明（防「要求了但没告诉产出者」）
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

# 合法 type：**从 SSOT 解析**，不再手抄副本
# （2026-09-18 修：此前这里是 artifact-types.yaml 的一份手抄副本，脚本注释里自己写着
#  「增删 artifact type 时两处都要改」——那正是本仓库反复在剿的「新建 SSOT 又复制一份」。）
ARTIFACT_TYPES_FILE="$SUITE_ROOT/runtime/artifacts/artifact-types.yaml"
VALID_TYPES="$(sed -n '/^types:/,/^[a-z]/p' "$ARTIFACT_TYPES_FILE" 2>/dev/null \
               | grep -oE '^  [a-z][a-z-]*:' | tr -d ' :' | tr '\n' ' ' || true)"
# context-package 不是 artifact type，是 Interface 层专用标记（见 ADR-004），故单独补上。
VALID_TYPES="${VALID_TYPES}context-package"
# 解析失败必须响亮失败：VALID_TYPES 只剩标记时，下面每条 type 都会判非法 → 全部报红（不静默放行）
case " $VALID_TYPES " in
  *" knowledge "*) : ;;
  *) red "  ❌ 无法从 $ARTIFACT_TYPES_FILE 解析出 types（SSOT 结构变了？）—— 本门禁失效，拒绝给出结论"
     exit 1 ;;
esac

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
echo "【4】Knowledge Directory Contract（.project-knowledge/ 目录契约）"
echo "----------------------------------------"

KD_CONTRACT="$SUITE_ROOT/shared/schemas/knowledge-directories.yaml"
KD_FRAGMENT="$SCRIPT_DIR/knowledge-directories.generated.sh"

# 4.0 生成物新鲜度：shell 片段必须与契约同步（契约改了但消费方没跟上 = 静默漂移）
if [ ! -f "$KD_FRAGMENT" ]; then
  red "  ❌ 缺 $KD_FRAGMENT（运行 node shared/scripts/generate-knowledge-dirs.mjs）"
  FAIL=$((FAIL+1))
elif node "$SCRIPT_DIR/generate-knowledge-dirs.mjs" --check >/dev/null 2>&1; then
  green "  ✅ 生成片段与契约同步"
else
  red "  ❌ 生成片段与契约不同步（运行 node shared/scripts/generate-knowledge-dirs.mjs）"
  FAIL=$((FAIL+1))
fi

if [ -f "$KD_FRAGMENT" ]; then
  # shellcheck source=/dev/null
  . "$KD_FRAGMENT"
fi

# 4.1 I3：不得存在「有 producer、无 consumer」的死产出
if [ -n "${KD_DEAD:-}" ]; then
  red "  ❌ I3 违反：以下目录既不入 index 又非人读（死产出）: $KD_DEAD"
  red "     → 二选一：declared 为人读产物（human_readable: true），或停掉它的 producer"
  FAIL=$((FAIL+1))
else
  green "  ✅ I3：每个声明目录都有 consumer（indexed_by_compiler ∨ human_readable）"
fi

# 4.2 I2：analyzer 规格里声明的写入目录必须 ⊆ 契约声明的目录
#     来源：knowledge-builder.md 的 Coverage Gate 表 目标文件列（形如 architecture/modules.md、patterns/*.md）
KB="$SKILLS_DIR/project-analyzer/prompts/knowledge-builder.md"
UNDECLARED=""
if [ -f "$KB" ]; then
  # 只取表格的「目标文件」列（第 3 列）——整行抓会把 Always/Never 之类词当成目录名
  for d in $(sed -n '/## Coverage Gate/,/^## /p' "$KB" | grep '^|' | awk -F'|' 'NF>=4 {print $3}' \
             | grep -oE '^[[:space:]]*[a-z][a-z-]*/' | tr -d ' /' | sort -u); do
    echo " ${KD_ALL:-} " | grep -q " $d " || UNDECLARED="$UNDECLARED $d"
  done
fi
if [ -n "$UNDECLARED" ]; then
  red "  ❌ I2 违反：analyzer 规格写出未声明的目录:$UNDECLARED"
  red "     → 在 shared/schemas/knowledge-directories.yaml 声明它，或停止产出"
  FAIL=$((FAIL+1))
else
  green "  ✅ I2：analyzer 规格的写入目录均已在契约中声明"
fi

# 4.3 I4：契约要求的 Producer 字段，必须出现在 analyzer 的 frontmatter 字段表里
#     —— 这正是 2026-09-17 实测到的缺口成因：knowledge-builder 说 statement 必写，
#        而权威字段表 output-format.md 根本没列它 → 产出者按字段表走 → 真实项目 0/12 合规。
OF="$SKILLS_DIR/project-analyzer/prompts/output-format.md"
MISSING_SPEC=""
for pair in ${KD_REQUIRED:-}; do
  f="${pair##*:}"
  grep -q "| \`$f\`" "$OF" 2>/dev/null || MISSING_SPEC="$MISSING_SPEC $f"
done
if [ -n "$MISSING_SPEC" ]; then
  # 同一字段可能被多个目录要求，去重后再报
  UNIQ_SPEC="$(printf '%s\n' $MISSING_SPEC | sort -u | tr '\n' ' ' | sed 's/ *$//')"
  red "  ❌ I4 违反：契约要求 Producer 写这些字段，但 output-format.md 的字段表未声明: $UNIQ_SPEC"
  red "     → Producer 会按字段表产出，缺声明 = 字段永远不会被写"
  FAIL=$((FAIL+1))
else
  green "  ✅ I4：契约的 required_frontmatter 字段均已在 output-format.md 字段表声明"
fi

# 4.4 I2 扩面：**所有** skill 规格（不止 analyzer）里指向知识目录的路径都必须已在契约中声明
#     4.2 只覆盖 analyzer，于是 releaser 把 CHANGELOG 写到项目根目录这类漂移无人拦截。
#     匹配 `.project-knowledge/<seg>/` 这种**显式带前缀**的写法——也正是要推的写法。
#
#     ⚠️ 本断言**抓不到「裸写文件名」**（如 `CHANGELOG.md` 不带任何目录前缀）——那类只能靠人工评审，
#        不要指望这条兜住（2026-09-17 releaser 的 CHANGELOG 漂移即属该类型）。
#     ⚠️ 扫描面排除 docs/：ADR 是冻结的历史记录，目录改名后扫它必然误报。
KD_NON_KNOWLEDGE="runtime"   # .project-knowledge/runtime/ 是运行时状态目录（state/timeline），非知识目录，
                             # 不在契约范围内。显式排除而**不**在契约里声明——声明了会被 I3 判为「死产出」
                             # （既不入 index 也不给人读），反而要用假值骗过 I3。
SCAN_DIRS="skills runtime workflow-protocol shared"
UNDECLARED_PATHS=""
for seg in $(grep -rhoE '\.project-knowledge/[a-z][a-z-]*/' $SCAN_DIRS 2>/dev/null \
             | sed 's|\.project-knowledge/||;s|/$||' | sort -u); do
  echo " ${KD_ALL:-} " | grep -q " $seg " && continue
  echo " $KD_NON_KNOWLEDGE " | grep -q " $seg " && continue
  loc="$(grep -rn -- "\.project-knowledge/$seg/" $SCAN_DIRS 2>/dev/null | head -1 | cut -d: -f1,2)"
  UNDECLARED_PATHS="$UNDECLARED_PATHS ${seg}(${loc:-?})"
done
if [ -n "$UNDECLARED_PATHS" ]; then
  red "  ❌ I2 扩面违反：规格里指向了未声明的知识目录:$UNDECLARED_PATHS"
  red "     → 在 shared/schemas/knowledge-directories.yaml 声明它，或停止产出"
  FAIL=$((FAIL+1))
else
  green "  ✅ I2 扩面：全 skill 规格里出现的知识目录均已声明（非知识目录 $KD_NON_KNOWLEDGE 已排除）"
fi

echo ""
if [ "$FAIL" -gt 0 ]; then
  red "❌ I/O CONNECTIVITY FAILED — $FAIL 处语义不通"
  exit 1
else
  green "✅ I/O CONNECTIVITY PASSED — type 合法、source→produces 能接通、output 有对应 Capability、知识目录契约一致"
  exit 0
fi
