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
mkdir -p "$FIXTURE/rules" "$FIXTURE/patterns" "$FIXTURE/decisions" "$FIXTURE/recommendations" "$FIXTURE/runtime"

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
cat > "$FIXTURE/recommendations/use-composable.md" <<'EOF'
---
statement: 新代码优先抽 composable，而不是复制模板
---
# 建议
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
  for (const b of ["rules", "knowledge", "guidance", "recommendations"]) {
    if (!(b in ctx)) { errs.push("missing context." + b); continue; }
    if (!Array.isArray(ctx[b])) errs.push("context." + b + " 应为数组");
  }
  // 分桶内容正确：rule 进 rules，pattern 进 knowledge
  if (!(ctx.rules || []).some(e => e.source === "rules/form-standard.md")) errs.push("rule 未进 rules 桶");
  if (!(ctx.knowledge || []).some(e => e.source === "patterns/table.md")) errs.push("pattern 未进 knowledge 桶");
  // Recommendation 端到端：Producer(analyzer) → index → resolver → context.recommendations[]
  if (!(ctx.recommendations || []).some(e => e.source === "recommendations/use-composable.md"))
    errs.push("recommendation 未走通端到端（应出现在 context.recommendations）");
  if ((ctx.knowledge || []).some(e => e.source === "recommendations/use-composable.md"))
    errs.push("recommendation 被错误塞进 knowledge 桶（应独立成桶）");
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
# ── 6. Verification Reachability：按 Host 的真实路径走一遍 ─────────
# 与 check-conformance G19 的区别：G19 是「grep 提示词文件里有没有引用」；
# 本步**按 Host 实际使用的 `interface.stages` 逐阶段加载 prompt**，断言验证子流程
# 确实落在这条路径上。前者证明「有引用」，后者证明「沿声明路径走能得到它」。
#
# ⚠️ 这仍是 **wiring 级**，不是行为级：它证明不了「verifier 真的拦住了坏产出」。
#    行为级证据属 eval 仓（见 docs/eval-contract.md），见 benchmark/pressure-tests/verification-reachability.yaml。
echo "【6】Verification Reachability：沿 interface.stages 走一遍"
echo "----------------------------------------"
node -e '
  const fs = require("fs"), path = require("path");
  const root = process.argv[1];
  const errs = [];
  let checked = 0;
  for (const name of fs.readdirSync(root).filter(d => fs.statSync(path.join(root,d)).isDirectory())) {
    const dir = path.join(root, name);
    const y = path.join(dir, "skill.yaml");
    if (!fs.existsSync(y)) continue;
    const yml = fs.readFileSync(y, "utf8");
    const mode = (yml.match(/verification:\s*\{\s*mode:\s*([a-z-]+)/) || [])[1] || "";
    if (!["direct-verify","candidate-verify-accept","none"].includes(mode))
      { errs.push(`${name}: verification.mode 非法或缺失 ("${mode}")`); continue; }
    if (mode === "none") continue;

    // 沿 Host 的路径：interface.stages → prompts/<stage>.md
    const stages = ((yml.match(/stages:\s*\[([^\]]*)\]/) || [])[1] || "")
      .split(",").map(s => s.trim()).filter(Boolean);
    const loaded = stages.map(s => path.join(dir, "prompts", s + ".md")).filter(fs.existsSync);
    const refsVerifier = f => /\]\([^)]*verifier\.md\)/.test(fs.readFileSync(f, "utf8"));

    const vfile = path.join(dir, "prompts", "verifier.md");
    if (!fs.existsSync(vfile)) { errs.push(`${name} (${mode}): 缺 prompts/verifier.md`); continue; }

    const ok = mode === "direct-verify"
      ? loaded.some(f => f.endsWith("validation.md") && refsVerifier(f))
      : loaded.some(f => f.endsWith("execution.md") && refsVerifier(f));
    if (!ok) errs.push(`${name} (${mode}): 沿 stages 走一遍，没有任何阶段 prompt 引用 verifier.md`);
    checked++;
  }
  if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
  console.log(`沿 interface.stages 走查通过：${checked} 个需验证的 skill，验证子流程均可达`);
' "$SUITE_ROOT/skills" \
  && pass "Verification Reachability：沿 interface.stages 走查，验证子流程均可达" \
  || fail "Verification Reachability：有 skill 的验证子流程在声明路径上不可达（见上）"

echo ""
# ── 7. Graph Contract：结构 + mutation + 查询语义 ────────────────
# graph.json = analyzer → graph-query → 5 个下游 Skill 的真实数据契约（见 artifact-types.yaml）。
# 校验器与 check-graph-contract.sh 共用 shared/scripts/graph-validate.mjs，避免「两把尺子」。
# 最高价值的是 mutation（dangling edge / knowledge 字段回流 / 旧 schemaVersion）——
# JSON Schema 不易表达、却是 graph 的真正业务约束。
echo "【7】Graph Contract：结构 + mutation + 查询语义"
echo "----------------------------------------"
GV="$SUITE_ROOT/shared/scripts/graph-validate.mjs"
GF="$FIXTURE/graph.json"
cat > "$GF" <<'EOF'
{
  "schemaVersion": "3.0.0",
  "capabilities": ["module", "file"],
  "generatedAt": "2026-11-09T00:00:00Z",
  "project": "fixture",
  "nodes": [
    { "id": "module-user", "type": "module", "label": "user", "domain": "user-management", "files": ["src/views/user/"] },
    { "id": "view-user", "type": "view", "label": "UserView", "layer": "view", "files": ["src/views/user/index.vue"] },
    { "id": "component-user", "type": "component", "label": "UserTable", "layer": "component", "files": ["src/components/UserTable.vue"] },
    { "id": "api-user", "type": "api", "label": "userApi", "layer": "api", "files": ["src/api/user.ts"] },
    { "id": "infra-http", "type": "infrastructure", "label": "http", "layer": "infrastructure", "files": ["src/utils/http.ts"] }
  ],
  "edges": [
    { "from": "view-user", "to": "component-user", "relation": "imports" },
    { "from": "component-user", "to": "api-user", "relation": "uses" },
    { "from": "api-user", "to": "infra-http", "relation": "depends_on" }
  ]
}
EOF
if node "$GV" "$GF" --strict >/dev/null 2>&1; then
  pass "graph.json 结构合法（v3.0.0 / 节点白名单 / 边引用 / id 唯一）"
else
  fail "graph.json 结构校验失败（合法 fixture 不应报错）"
fi

# mutation：写坏 graph.json → 同一校验器必须红。
# ⚠️ 每次从干净基线 GF_BASE 重建，避免 mutation 间状态串扰。
GF_BASE="$(
  node -e 'const g=require(process.argv[1]); process.stdout.write(JSON.stringify(g));' "$GF"
)"
mutate_and_check() {  # $1=描述  $2=node 写坏逻辑（面对 $GF）
  printf '%s' "$GF_BASE" > "$GF"                # 重建干净基线
  if node -e "$2" "$GF" > "$GF.tmp" 2>/dev/null && mv "$GF.tmp" "$GF"; then
    if node "$GV" "$GF" --strict >/dev/null 2>&1; then
      fail "mutation「$1」本应被抓到却通过 —— graph 校验退化"
    else
      pass "mutation「$1」被拒绝（校验守卫生效）"
    fi
  else
    fail "mutation「$1」运行失败（test harness 自身问题）"
  fi
}
mutate_and_check "缺失 nodes 数组" \
  'const g=require(process.argv[1]); delete g.nodes; process.stdout.write(JSON.stringify(g));'
mutate_and_check "node.type 非法(badger)" \
  'const g=require(process.argv[1]); g.nodes[0].type="badger"; process.stdout.write(JSON.stringify(g));'
mutate_and_check "knowledge object 节点(type=pattern)" \
  'const g=require(process.argv[1]); g.nodes[0].type="pattern"; process.stdout.write(JSON.stringify(g));'
mutate_and_check "合法 type 上带 statement（知识字段回流）" \
  'const g=require(process.argv[1]); g.nodes[1].statement="x"; process.stdout.write(JSON.stringify(g));'
mutate_and_check "节点 dependsOn 数组（双关系表示）" \
  'const g=require(process.argv[1]); g.nodes[1].dependsOn=[]; process.stdout.write(JSON.stringify(g));'
mutate_and_check "module 缺 domain" \
  'const g=require(process.argv[1]); delete g.nodes[0].domain; process.stdout.write(JSON.stringify(g));'
mutate_and_check "重复 node.id" \
  'const g=require(process.argv[1]); g.nodes[1].id=g.nodes[0].id; process.stdout.write(JSON.stringify(g));'
mutate_and_check "dangling edge.to 悬空" \
  'const g=require(process.argv[1]); g.edges[0].to="node-并不存在"; process.stdout.write(JSON.stringify(g));'
mutate_and_check "legacy schemaVersion 2.0.0" \
  'const g=require(process.argv[1]); g.schemaVersion="2.0.0"; process.stdout.write(JSON.stringify(g));'

# 还原干净基线，供查询语义测试使用。
printf '%s' "$GF_BASE" > "$GF"

# 7b. findImpacted 方向：A.vue → B.ts；改 B.ts 必须返回 A.vue（消费者），
# 而不是返回 B.ts 的依赖。用 files[] + 节点级影响，不建 file 节点。
IMPACTED="$(jq --argjson files '["src/components/UserTable.vue"]' '
  [ .nodes[] | select(
      (((.files // []) | map(select(. as $f | $files | index($f))) | length) > 0)
      or ((.id as $i | $files | index($i)) != null)
    ) | .id ] as $changed
  | [ .edges[] | select(.to as $t | $changed | index($t)) | .from ] | unique
' "$GF")"
if printf '%s' "$IMPACTED" | grep -q '"view-user"'; then
  pass "findImpacted(B.ts) 返回消费者 A.vue（方向正确）"
else
  fail "findImpacted 方向错误：期望 view-user，实际 $IMPACTED"
fi

# 7c. findTransitiveDeps 真正递归 3 层：view-user → component-user → api-user → infra-http
DEPS="$(jq --arg id 'view-user' '
  def walk($frontier; $seen; $depth):
    if $depth == 0 or ($frontier | length) == 0 then $seen
    else
      ([ $frontier[] as $n | .edges[] | select(.from == $n) | .to ] | unique) as $next
      | ([ $seen[], $next[] ] | unique) as $newseen
      | walk($next; $newseen; $depth - 1)
    end;
  walk([$id]; [$id]; 3) | .[] | select(. != $id)
' "$GF")"
DEPS_MISSING=""
for want in component-user api-user infra-http; do
  printf '%s' "$DEPS" | grep -q "\"$want\"" || DEPS_MISSING="$DEPS_MISSING $want"
done
if [ -z "$DEPS_MISSING" ]; then
  pass "findTransitiveDeps 真正递归 3 层（component-user/api-user/infra-http）"
else
  fail "findTransitiveDeps 缺层:$DEPS_MISSING（实际: $DEPS）"
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
