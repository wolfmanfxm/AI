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
#   L0  YAML 可解析                  标准 parser 前置门禁（文本/regex 校验抓不到语法错误）
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

# ── L0: YAML 可解析（前置） ────────────────────────────────
echo "【L0】YAML 可解析（标准 parser）"
echo "----------------------------------------"
# ⚠️ 不要只吞退出码：check-yaml.sh 在**宿主无 YAML parser 时主动 `exit 0`** 并打印
#    「这是跳过，不是通过——门禁未生效」。父脚本 `>/dev/null 2>&1` 把该提示吞掉、只看 exit code
#    → 一个文件都没解析也打印「✅ 所有 .yaml 可被标准 parser 解析」（2026-09-18 修）。
YAML_OUT="$(bash "$SUITE_ROOT/shared/scripts/check-yaml.sh" 2>&1)"; YAML_RC=$?
if [ "$YAML_RC" -ne 0 ]; then
  red "  ❌ 有 .yaml 无法解析（运行 bash shared/scripts/check-yaml.sh 看清单）"
  FAIL=$((FAIL+1))
elif printf '%s' "$YAML_OUT" | grep -q "门禁未生效"; then
  yellow "  ⚠️ L0 跳过：宿主无 YAML 解析器，**没有一个文件被解析**——不是「全部可解析」"
  WARN=$((WARN+1))
else
  green "  ✅ 所有 .yaml 可被标准 parser 解析"
  PASS=$((PASS+1))
fi

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

# workflow-library 指派表：skill → 期望 stages（**有序**）
# 补于 2026-09-18：此前只查了「SKILL.md 表行集合 == interface.stages」，
# 于是 analyzer 的 skill.yaml 写成 [discovery, execution, delivery, validation]（先交付后验证），
# 与 skill-ir 自洽、与 SKILL.md 表也自洽，唯独与 workflow-library 的 standard 流程矛盾
# ——**局部 SSOT 正确，跨 Producer/Consumer 契约错误**，全部检查放行。
WL_MAP="$(node -e '
  const fs = require("fs");
  const t = fs.readFileSync(process.argv[1], "utf8");
  const blocks = [...t.matchAll(/^  ([a-z-]+):\n([\s\S]*?)(?=^  [a-z-]+:|\Z)/gm)];
  for (const [, name, body] of blocks) {
    const s = body.match(/stages:\s*\[([^\]]*)\]/), u = body.match(/used_by:\s*\[([^\]]*)\]/);
    if (!s || !u) continue;
    for (const sk of u[1].split(",").map(x => x.trim()).filter(Boolean))
      console.log(sk + " " + s[1].split(",").map(x => x.trim()).filter(Boolean).join(" "));
  }' "$SUITE_ROOT/runtime/registry/workflow-library.yaml" 2>/dev/null || true)"

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

  # SKILL.md 的 name: 必须 == 目录名（== skill.yaml id:）
  # 补于 2026-09-18 变异测试：把 name 改成 `project-relaser-TYPO`，一致性/合规/连通/漂移**四个检查全绿放行**。
  # 而 name 正是 Host 注册 skill 用的标识——改名会让它以错误身份被路由，其余声明却完全自洽。
  md_name=$(grep -m1 "^name:" "$skill_dir/SKILL.md" 2>/dev/null | sed 's/^name: *//' || true)
  [ "$md_name" != "$skill" ] && mismatches="$mismatches SKILL.md.name($md_name≠$skill)"

  # SKILL.md 工作流表行集合 == skill.yaml interface.stages
  # 补于 2026-09-18：此前 8 个 SKILL.md 的表里有 `Verify` 行，而 10/10 的 stages 都不含 verify、
  # stage-templates/ 也没有 verify.md —— Host 按 `for each stage in interface.stages` 推进时，
  # 这些 verifier.md **运行时永不被加载**。这条断言把「表行 ≠ stages」永久挡住。
  md_stages=$(grep -oE '^\| [A-Z][A-Za-z -]* \| \[prompts/' "$skill_dir/SKILL.md" 2>/dev/null \
              | sed 's/^| *//;s/ *|.*//' | tr 'A-Z' 'a-z' | tr ' ' '-' | sort -u | tr '\n' ' ' || true)
  yaml_stages=$(grep "stages:" "$sy" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' \
                | tr -d ' ' | grep -v '^$' | sort -u | tr '\n' ' ' || true)
  [ "$md_stages" != "$yaml_stages" ] && \
    mismatches="$mismatches SKILL.md表行≠stages（表:[${md_stages:-空}] stages:[${yaml_stages:-空}]）"

  # skill.yaml 的 stages 必须**有序等于** workflow-library 指派给它的 stages
  exp_stages="$(printf '%s\n' "$WL_MAP" | awk -v s="$skill" '$1==s { $1=""; sub(/^ /,""); print }')"
  if [ -n "$exp_stages" ]; then
    own_stages="$(grep "stages:" "$sy" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' | tr ',' ' ' \
                  | tr -s ' ' | sed 's/^ *//;s/ *$//' || true)"
    [ "$own_stages" != "$exp_stages" ] && \
      mismatches="$mismatches stages≠workflow-library（自身:[$own_stages] 指派:[$exp_stages]）"
  fi

  if [ -n "$mismatches" ]; then
    red "  ❌ $skill: skill-ir 与 skill.yaml 不一致 —$mismatches"
    FAIL=$((FAIL+1))
  else
    green "  ✅ $skill"
    PASS=$((PASS+1))
  fi
done

# L1 补：整文件新鲜度。上面的字段比对只覆盖 id/version/produces/consumes/stages——
# verification.checks / exit_criteria / failure_conditions / description / boundary 漂移查不到。
# 实证（2026-09-17）：analyzer 的 verifier.md 加了 Verify 6，skill-ir 仍写着旧的 checks: 9，
# 全仓绿灯放行了很久，直到手工重跑生成器才发现。故此处做整文件逐字节比对。
if bash "$SCRIPT_DIR/generate-skill-ir.sh" --check >/dev/null 2>&1; then
  green "  ✅ skill-ir 全字段新鲜（含 verification / exit_criteria / description）"
  PASS=$((PASS+1))
else
  red "  ❌ skill-ir 存在字段漂移（上面逐字段比对覆盖不到的那些）"
  red "     → 运行 bash shared/scripts/generate-skill-ir.sh"
  FAIL=$((FAIL+1))
fi

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
# ── L3.5: scheduler / policy 的 skill 集合 ──────────────────
echo "【L3.5】scheduler.skill_order / skill-policy 的 skill 集合完整性"
echo "----------------------------------------"
SCHED="$SUITE_ROOT/runtime/config/scheduler.yaml"
POLICY="$SUITE_ROOT/runtime/config/skill-policy.yaml"

# skills 目录集合（规范）
skills_set=$(ls "$SKILLS_DIR" | sort | tr '\n' ' ')

# scheduler.skill_order 集合
sched_set=$(grep -E "^\s+(project|pipeline)-" "$SCHED" 2>/dev/null | sed 's/:.*//' | tr -d ' ' | sort | tr '\n' ' ')

# skill-policy 的顶层 skill 键集合
policy_set=$(grep -E "^[a-z].*:$" "$POLICY" 2>/dev/null | sed 's/:$//' | sort | tr '\n' ' ')

# 对比 scheduler
for s in $skills_set; do
  echo "$sched_set" | grep -qw "$s" || { red "  ❌ $s: scheduler.skill_order 缺调度条目"; FAIL=$((FAIL+1)); }
done
for s in $sched_set; do
  echo "$skills_set" | grep -qw "$s" || { red "  ❌ $s: scheduler.skill_order 指向不存在的 skill"; FAIL=$((FAIL+1)); }
done

# 对比 policy
for s in $skills_set; do
  echo "$policy_set" | grep -qw "$s" || { red "  ❌ $s: skill-policy.yaml 缺策略条目"; FAIL=$((FAIL+1)); }
done
for s in $policy_set; do
  echo "$skills_set" | grep -qw "$s" || { red "  ❌ $s: skill-policy.yaml 指向不存在的 skill"; FAIL=$((FAIL+1)); }
done

# 若两组都无差异
sched_ok=$( [ "$(echo "$sched_set" | tr ' ' '\n' | sort)" = "$(echo "$skills_set" | tr ' ' '\n' | sort)" ] && echo 1 || echo 0 )
policy_ok=$( [ "$(echo "$policy_set" | tr ' ' '\n' | sort)" = "$(echo "$skills_set" | tr ' ' '\n' | sort)" ] && echo 1 || echo 0 )
if [ "$sched_ok" = "1" ] && [ "$policy_ok" = "1" ]; then
  green "  ✅ scheduler.skill_order 与 skill-policy 集合完整（10/10）"
  PASS=$((PASS+1))
fi

echo ""
# ── L3.6: I/O 连通性（能接通 ≠ 相等）──────────────────
echo "【L3.6】I/O 连通性（type 合法 / source→produces / output→Capability）"
echo "----------------------------------------"
if bash "$SUITE_ROOT/shared/scripts/check-io-connectivity.sh" >/dev/null 2>&1; then
  green "  ✅ I/O 语义连通"
  PASS=$((PASS+1))
else
  red "  ❌ I/O 语义不通（错标 type / 来源断链 / 产出无 Capability）"
  FAIL=$((FAIL+1))
fi

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
