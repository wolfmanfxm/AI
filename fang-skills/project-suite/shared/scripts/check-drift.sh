#!/bin/bash
# Drift Detector v1.0
# Checks for contract drift: when a skill's actual behavior diverges from its declared contract.
#
# Checks（本脚本只做**静态**可判定的事）：
#   1. produces 声明存在且非空 —— ⚠️ **不验证**「是否真的产出」，见下方 Drift 1 注释
#   2. SKILL.md description vs produces —— 描述声明的能力是否超出 produces
#   3. Referenced files still exist — prompt/reference 链接是否死链
#   4. Stage count vs template — 阶段数是否在合理区间
#   5. @adapter 引用 vs adapter-registry
#
# ⚠️ 2026-09-18 修正：Drift 1/2/5 此前均为**假检查**——Drift 1/5 会在没有任何比对的情况下打印 ✅，
#    Drift 2 只取到 `description: >` 这一行、关键词永不命中。三者现在要么真查、要么明确降级为
#    「仅声明存在性」，不再输出无依据的 ✅。
#
# Usage: bash shared/scripts/check-drift.sh

set -euo pipefail
# 内部错误（set -e 下未保护的命令返回非 0）→ exit 2，与「发现 drift」exit 1、「无 drift」exit 0 区分。
trap 'echo -e "\033[31m  ❌ Internal checker error — 未保护命令在 set -e 下返回非 0\033[0m" >&2; exit 2' ERR
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

DRIFT_COUNT=0; PASS=0; WARN=0

# 取 SKILL.md frontmatter 里 description 的**完整多行块**（YAML `>` 折叠块）。
# ⚠️ 原实现是 `head -10 "$md" | grep "description:"` —— 只拿到 `description: >` 这一行本身，
#    折叠块内容一行都没取到，于是 Drift 2 的关键词永不可能命中（假检查，2026-09-18 修）。
skill_description() {
  awk '
    /^description:/ { in_d=1; sub(/^description: *>?[ ]*/, ""); print; next }
    in_d && (/^[a-z]+:|^---/) { exit }
    in_d { sub(/^[ ]+/, ""); print }
  ' "$1" 2>/dev/null || true
}

# 剥掉「负边界」段：`不用于：…` / `不适用于：…` / `Not for: …` 起至块尾。
# 负边界是**故意声明不做什么**，其中的关键词（如 Architect 的「不用于…直接实现代码」中的「代码」）
# 不代表产出能力。不剥掉的话，一旦给 description 加负边界，Drift 2 就会把正确声明误报成 drift。
strip_negative_boundary() {
  sed -E '/^[[:space:]]*(不用于|不适用于|Not for)[[:space:]]*[:：]/,$d'
}

echo "========================================"
echo " Drift Detection Report"
echo "========================================"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  yaml="$skill_dir/skill.yaml"
  md="$skill_dir/SKILL.md"
  [ ! -f "$yaml" ] && continue

  echo "--- $skill ---"

  # Drift 1: produces 声明存在且非空。
  # ⚠️ 这里**不验证**「是否真的产出交付物」——实际交付物只在**跑过的项目**里存在
  #    （PLAN.md 只在跑过 planner 的项目里才有），静态仓里无法判定。该断言的正规归属是
  #    eval 仓的 benchmark（见 docs/eval-contract.md 的分工）。
  #    原实现在此打印 `✅ produces: [...]` 却没有任何比对，是**假信号**（2026-09-18 降级为信息项）。
  produces=$(grep "^produces:" "$yaml" | sed 's/.*\[\(.*\)\].*/\1/' || echo "")
  if [ -z "$produces" ]; then
    yellow "  ⚠️  No produces declared"
    WARN=$((WARN+1))
  else
    echo "  ℹ️  produces: [$produces]（仅声明存在性；交付物是否真的产出属 eval 仓职责）"
  fi

  # Drift 2: description 声明的能力是否超出 produces
  #          先取**完整**折叠块，再剥掉负边界段（见上方 strip_negative_boundary 的说明）。
  #
  # ⚠️ 关键词必须是**生产性措辞**，不能是裸的「代码 / Code」——2026-09-18 实测：修好取块后，
  #    裸关键词一次报出 4 条**全部误报**（analyzer/documenter/reviewer/tester）：
  #    它们的描述里出现「代码」是因为**对代码做事**（审查代码、为代码写文档/测试），
  #    而非**产出代码**。命中率 0/4 → 收紧为明确的生产性短语。
  desc=$(skill_description "$md" | strip_negative_boundary)
  if printf '%s' "$desc" | grep -qE "生成代码|写代码|实现代码|编写代码|产出代码|新增代码|generate code|write code|implement code"; then
    if ! echo "$produces" | grep -q "Code\|RefactoredCode"; then
      yellow "  ⚠️  Description 声称产出代码，但 produces ≠ [Code]"
      DRIFT_COUNT=$((DRIFT_COUNT+1))
    fi
  fi
  # 同类收紧：裸「文档 / document」会把「读文档」「文档已更新」也算进来 → 只看生产性措辞
  if printf '%s' "$desc" | grep -qE "生成文档|编写文档|产出文档|写文档|generate docs|write documentation"; then
    if ! echo "$produces" | grep -q "Documentation"; then
      yellow "  ⚠️  Description 声称产出文档，但 produces ≠ [Documentation]"
      DRIFT_COUNT=$((DRIFT_COUNT+1))
    fi
  fi

  # Drift 3: prompt and reference links — do they resolve?
  # ⚠️ 原正则只匹配 `../` 开头的链接（`\(\.[^)]*\.md\)`），同目录链接（如 `(prompts/discovery.md)`）
  #    **完全没查**，但输出却写「All SKILL.md links resolve」——实测把 `prompts/discovery.md`
  #    改成 `prompts/NOPE.md`，四个检查全绿放行（2026-09-18 修）。
  #    现覆盖一切相对 .md 链接（排除含 `:` 的绝对 URL 与含 `#` 的锚点）。
  dead_links=0
  # while read -r 逐行读：link label 可能含空格（如 [Complexity Gate](...)），for..in $(..) 会按空白拆散导致误报死链。
  while IFS= read -r link; do
    path=$(echo "$link" | sed -E 's/^\[[^]]*\]\(//; s/\)$//')
    # Resolve relative to skill dir
    abs_path="$skill_dir/$path"
    if [ ! -f "$abs_path" ]; then
      dead_links=$((dead_links+1))
    fi
  done < <(grep -ohE '\[[^]]*\]\([^):#]*\.md\)' "$md" 2>/dev/null || true)
  if [ "$dead_links" -gt 0 ]; then
    yellow "  ⚠️  ${dead_links} dead link(s) in SKILL.md"
    DRIFT_COUNT=$((DRIFT_COUNT+1))
    WARN=$((WARN+1))
  else
    green "  ✅ All SKILL.md links resolve"
    PASS=$((PASS+1))
  fi

  # Drift 4: stages count — does it match the template expectations?
  stages=$(grep "stages:" "$yaml" | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | wc -l | tr -d ' ' || true)
  min_stages=3; max_stages=7
  if [ "$stages" -ge "$min_stages" ] && [ "$stages" -le "$max_stages" ]; then
    green "  ✅ Stage count: ${stages} (${min_stages}-${max_stages})"
    PASS=$((PASS+1))
  else
    yellow "  ⚠️  Stage count: ${stages} (expected ${min_stages}-${max_stages})"
    WARN=$((WARN+1))
  fi

  # Drift 5 已删除（2026-09-18）。原实现有两处错：
  #   1. 计数错——`grep -A20 "^interface:" | grep "name:"` 把 **inputs 和 outputs 一起数了**，
  #      却输出 `✅ interface.outputs: N output(s) match produces`，N 是假的、match 也没查。
  #   2. 重复——「output type → produces Capability」的真检查已在 check-io-connectivity.sh
  #      的第 3 项做了（那才是真正读 type 映射的版本）。此处不再保留一个更弱的副本。
  # 保留这段注释是为了让「为什么少了一项」可追溯，而不是静默消失。

  echo ""
done

echo "========================================"
# Drift 6: @adapter references vs registry
adapter_refs=$(grep -roh '@adapter:[a-z]*\.[a-z]*' skills/ --include="*.md" 2>/dev/null | sort -u || true)
adapter_mismatch=0
for ref in $adapter_refs; do
  domain=$(echo "$ref" | sed 's/@adapter://' | cut -d. -f1)
  if ! grep -q "$domain:" runtime/tool-adapters/adapter-registry.yaml 2>/dev/null; then
    echo "  ❌ Unregistered adapter: $ref"
    adapter_mismatch=$((adapter_mismatch+1))
  fi
done
if [ "$adapter_mismatch" -eq 0 ]; then
  [ -n "$adapter_refs" ] && echo "  ✅ All @adapter: references match registry ($(echo "$adapter_refs" | wc -l | tr -d ' ') unique)" || echo "  ℹ️  No @adapter: refs yet (P0-P2 migration pending)"
fi

echo " Summary"
echo "========================================"
echo " Passed:  $PASS"
echo " Warnings: $WARN"
echo " Drifts:  $DRIFT_COUNT"
echo ""

if [ "$DRIFT_COUNT" -gt 0 ]; then
  yellow "⚠️  DRIFT DETECTED — ${DRIFT_COUNT} potential contract drift(s)"
  echo "   Review the warnings above and update skill.yaml/SKILL.md to match."
  exit 1
else
  green "✅ NO DRIFT — contracts match implementation"
  exit 0
fi
