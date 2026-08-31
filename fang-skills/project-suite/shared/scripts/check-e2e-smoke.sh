#!/bin/bash
# End-to-End Smoke Test v1.0
#
# 全套主链的最小 E2E —— 不跑真实 Agent，只验证 wiring（输入 → 正确 Skill → 正确 Context → 正确 Consumer）。
# 这是「声明 ≠ 实现」最容易断裂的四段，本脚本把它们串成一条可断言的链：
#
#   1. 输入 → 正确 Skill        （capability-routing.yaml 的 intent→provider 映射）
#   2. Knowledge → 正确 Context （compiler → resolver → context-package.json 分桶）
#   3. Context → 正确 Consumer  （generator/planner/reviewer 的 interface 声明消费 context-package.json）
#   4. schema → 全通过          （context-package.json 符合 context-package.schema.json 结构）
#
# Usage: bash shared/scripts/check-e2e-smoke.sh
# Exit:  0 = 主链 wiring 通过；1 = 有断裂

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

PASS=0; FAIL=0
pass() { green "  ✅ $1"; PASS=$((PASS+1)); }
fail() { red   "  ❌ $1"; FAIL=$((FAIL+1)); }

ROUTING="$SUITE_ROOT/runtime/registry/capability-routing.yaml"
SCHEMA="$SUITE_ROOT/runtime/contracts/context-package.schema.json"

echo "========================================"
echo " E2E Smoke Test（主链 wiring）"
echo "========================================"
echo ""

# ── 1. 输入 → 正确 Skill（intent → provider 映射）────────────────
echo "【1】Skill Routing：intent → provider"
echo "----------------------------------------"
node -e '
  const fs = require("fs");
  const content = fs.readFileSync(process.argv[1], "utf8");
  const routing = content.split(/^matching:/m)[0];          // 只取 routing 段
  const routes = [
    ["生成代码", "project-generator"],
    ["代码审查", "project-reviewer"],
    ["任务拆解", "project-planner"],
  ];
  const blocks = routing.split(/^  [A-Za-z]+:/m).filter(b => b.trim());
  const errs = [];
  for (const [intent, provider] of routes) {
    const block = blocks.find(b => b.includes(intent));
    if (!block) { errs.push(`"${intent}" 不在任何 routing 块`); continue; }
    if (!block.includes("provider: " + provider)) errs.push(`"${intent}" 未路由到 ${provider}`);
  }
  if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
  console.log("intent → provider 映射正确");
' "$ROUTING" \
  && pass "Skill Routing：intent → provider 映射正确" \
  || fail "Skill Routing：intent → provider 映射断裂（见上）"

echo ""
# ── 2. Knowledge → 正确 Context（compiler → resolver）─────────────
echo "【2】Knowledge Chain：compiler → resolver → context-package"
echo "----------------------------------------"
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/e2e-fixture.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT
mkdir -p "$FIXTURE/rules" "$FIXTURE/patterns" "$FIXTURE/decisions" "$FIXTURE/runtime"

cat > "$FIXTURE/rules/form-standard.md" <<'EOF'
---
constraint: 所有表单必须用 FormWrapper
---
# 表单规范
EOF
cat > "$FIXTURE/patterns/table.md" <<'EOF'
---
summary: DataTable + schema 表格
confidence: 92
---
# 表格模式
EOF
cat > "$FIXTURE/decisions/ARCHITECTURE-api.md" <<'EOF'
---
scope: task
constraint: 本次用 baseService 前缀
---
# API 决策
EOF
echo '{"files":{"patterns/table.md":{"status":"Accepted","occurrences":3}}}' > "$FIXTURE/runtime/knowledge.json"

PKG="$FIXTURE/context-package.json"
if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null 2>&1 \
   && bash "$SCRIPT_DIR/knowledge-resolver.sh" "$FIXTURE" >/dev/null 2>&1 \
   && [ -f "$PKG" ]; then
  pass "compiler → resolver → context-package.json 产出成功"
else
  fail "knowledge chain 运行失败"
fi

echo ""
# ── 3. Context → 正确 Consumer（interface 声明消费）───────────────
echo "【3】Consumer Contract：下游 skill 声明消费 context-package.json"
echo "----------------------------------------"
for s in project-generator project-planner project-reviewer; do
  if grep -q "context-package.json" "$SUITE_ROOT/skills/$s/skill.yaml"; then
    pass "$s 声明消费 context-package.json"
  else
    fail "$s 未声明 context-package.json"
  fi
done

echo ""
# ── 4. schema → 全通过（context-package 符合 schema 结构）─────────
echo "【4】Schema Conformance：context-package.json ↔ context-package.schema.json"
echo "----------------------------------------"
node -e '
  const fs = require("fs");
  const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const schema = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
  const errs = [];
  // 顶层 required（来自 schema）
  for (const k of schema.required || []) if (!(k in pkg)) errs.push("missing top-level " + k);
  if (pkg.generatedBy !== "knowledge-resolver") errs.push("generatedBy ≠ knowledge-resolver");
  // context 对象 required
  const ctx = pkg.context || {};
  for (const k of (schema.properties.context.required || [])) if (!(k in ctx)) errs.push("missing context." + k);
  // 三个分桶必须是数组（schema.properties.context.properties 声明了它们）
  for (const b of ["rules", "knowledge", "guidance"]) {
    if (!(b in ctx)) { errs.push("missing context." + b); continue; }
    if (!Array.isArray(ctx[b])) errs.push("context." + b + " 应为数组");
  }
  // 分桶内容正确：rule 进 rules，pattern 进 knowledge
  if (!(ctx.rules || []).some(e => e.source === "rules/form-standard.md")) errs.push("rule 未进 rules 桶");
  if (!(ctx.knowledge || []).some(e => e.source === "patterns/table.md")) errs.push("pattern 未进 knowledge 桶");
  if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
  console.log("context-package.json 符合 schema 结构 + 分桶正确");
' "$PKG" "$SCHEMA" \
  && pass "context-package.json 符合 schema 结构 + 分桶正确" \
  || fail "schema 结构校验失败（见上）"

echo ""
# ── 5. Resolver 健壮性：basename 命中 + garbage 显式告警 ──────────
echo "【5】Resolver 健壮性：basename 命中 + garbage 显式告警"
echo "----------------------------------------"
# basename candidate 命中（回归：candidates 支持 basename，避免误判为空）
if bash "$SCRIPT_DIR/knowledge-resolver.sh" "$FIXTURE" "table" >/dev/null 2>&1 \
   && node -e 'const p=require(process.argv[1]).context; process.exit(p.knowledge.some(e=>e.source==="patterns/table.md")?0:1)' "$PKG"; then
  pass "basename candidate 命中（table → patterns/table.md）"
else
  fail "basename candidate 未命中"
fi

# garbage candidate 显式告警（回归：不静默返回空 knowledge）
WARN_OUT="$(bash "$SCRIPT_DIR/knowledge-resolver.sh" "$FIXTURE" "nonexistent" 2>&1 || true)"
if echo "$WARN_OUT" | grep -q "未命中"; then
  pass "garbage candidate 显式告警（非静默空）"
else
  fail "garbage candidate 未告警"
fi

echo ""
echo "========================================"
echo " Summary: Pass=$PASS  Fail=$FAIL"
echo "========================================"
if [ "$FAIL" -gt 0 ]; then
  red "❌ E2E SMOKE TEST FAILED — 主链有断裂"
  exit 1
else
  green "✅ E2E SMOKE TEST PASSED — 主链 wiring 完整"
  exit 0
fi
