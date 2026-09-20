#!/bin/bash
# Knowledge Pipeline Closed-Loop Test v1.0
#
# 验证主知识链的端到端闭环（最关键的 Knowledge 链，此前只靠静态声明保证）：
#
#   fixture project-knowledge
#       ↓ knowledge-compiler.sh
#   knowledge-index.json   （校验结构 + lifecycle Accepted 过滤）
#       ↓ knowledge-resolver.sh
#   context-package.json   （校验结构 + 分桶正确）
#
# 额外覆盖：
#   - lifecycle 过滤：Candidate 的 analyzer 产出文件不进 index；用户手写 rules 恒入
#   - change-detection：knowledge.json 的 status 变化（Candidate→Accepted）触发重扫
#   - change-detection：重命名（内容不变）也触发重扫（路径参与摘要）；编译器身份变化也触发重扫
#   - 契约守卫：rules/decisions 缺 constraint 必须硬失败 + 补齐后恢复（真实项目断链的回归锁）
#
# Usage: bash shared/scripts/check-knowledge-pipeline.sh
# Exit:  0 = 闭环通过；1 = 有断言失败

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

PASS=0; FAIL=0
pass() { green "  ✅ $1"; PASS=$((PASS+1)); }
fail() { red   "  ❌ $1"; FAIL=$((FAIL+1)); }

FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/kc-fixture.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

# ⚠️ 必须与契约的 KD_INDEXED（9 个 indexed 目录）**逐一对应**——此前漏了 `recommendations`，
#    于是 compiler 的 `emit_one "recommendations" …` 从未被本闭环测试执行过：
#    该桶若写错（能力名/类型/优先级），测试照样全绿（2026-09-18 补）。
mkdir -p "$FIXTURE/rules" "$FIXTURE/decisions" "$FIXTURE/patterns" \
         "$FIXTURE/components" "$FIXTURE/api" "$FIXTURE/architecture" \
         "$FIXTURE/experience" "$FIXTURE/playbooks" "$FIXTURE/recommendations" \
         "$FIXTURE/runtime"

# --- fixture：用户手写（rules/decisions）+ analyzer 产出（patterns/components/api/architecture） ---
cat > "$FIXTURE/rules/form-standard.md" <<'EOF'
---
constraint: 所有表单必须用 FormWrapper
---
# 表单规范
EOF

cat > "$FIXTURE/decisions/ARCHITECTURE-api.md" <<'EOF'
---
scope: task
constraint: 本次用 baseService 前缀
---
# API 决策
EOF

cat > "$FIXTURE/patterns/table.md" <<'EOF'
---
summary: DataTable + schema 表格
confidence: 92
---
# 表格模式
EOF

cat > "$FIXTURE/patterns/upload.md" <<'EOF'
---
summary: 上传模式
confidence: 65
---
# 上传模式
EOF

cat > "$FIXTURE/components/catalog.md" <<'EOF'
---
summary: Dialog 组件
---
# 组件编目
EOF

cat > "$FIXTURE/api/order.md" <<'EOF'
---
summary: 订单 API
---
# 订单接口
EOF

cat > "$FIXTURE/architecture/overview.md" <<'EOF'
---
summary: 架构总览
---
# 架构
EOF

cat > "$FIXTURE/experience/gotcha.md" <<'EOF'
# 经验
EOF

cat > "$FIXTURE/playbooks/runbook.md" <<'EOF'
# 手册
EOF

cat > "$FIXTURE/recommendations/use-composable.md" <<'EOF'
---
statement: 新代码优先抽 composable，而不是复制模板
---
# 建议
EOF

cat > "$FIXTURE/runtime/knowledge.json" <<'EOF'
{"files":{
  "patterns/table.md":{"status":"Accepted","occurrences":3},
  "patterns/upload.md":{"status":"Candidate","occurrences":1},
  "components/catalog.md":{"status":"Accepted","occurrences":2},
  "api/order.md":{"status":"Accepted","occurrences":2},
  "architecture/overview.md":{"status":"Accepted","occurrences":2}
}}
EOF

INDEX="$FIXTURE/knowledge-index.json"
PKG="$FIXTURE/context-package.json"

echo "=== 1. compiler → knowledge-index.json（结构 + lifecycle 过滤） ==="
if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null; then
  if node -e '
    const fs=require("fs");
    const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const errs=[];
    for (const k of ["schemaVersion","generatedBy","generatedAt","capabilities"]) if(!(k in idx)) errs.push("missing "+k);
    if (idx.generatedBy!=="knowledge-compiler") errs.push("generatedBy ≠ knowledge-compiler");
    const pats=(idx.capabilities.patterns||{}).files||[];
    if (!pats.some(f=>f.source==="patterns/table.md")) errs.push("patterns/table.md(Accepted) 应入 index");
    if (pats.some(f=>f.source==="patterns/upload.md")) errs.push("patterns/upload.md(Candidate) 不应入 index");
    const rules=(idx.capabilities.rules||{}).files||[];
    if (!rules.some(f=>f.source==="rules/form-standard.md")) errs.push("rules/form-standard.md 应恒入 index（用户手写）");
    // recommendations 桶此前 fixture 里根本没建目录 → 该 emit_one 从未被执行过（2026-09-18 补）
    const recs=(idx.capabilities.recommendations||{}).files||[];
    if (!recs.some(f=>f.source==="recommendations/use-composable.md")) errs.push("recommendations/use-composable.md 未进 index");

    // 产物 vs 契约互校：index 里出现的每个 type 必须在该 schema 的 enum 内（2026-09-18 补）。
    // 此前 recommendation 已真实进 index，而 knowledge-index.schema.json 的 enum 不含它，
    // 无任何断言报出来——正是这类「契约没跟上产物」的静默漂移。
    // 不引 JSON Schema 引擎，只取 enum 做集合比对（保持本套检查的轻量断言风格）。
    const schema=JSON.parse(fs.readFileSync(process.argv[2],"utf8"));
    const ENUM=schema.properties.capabilities.additionalProperties.properties.files.items.properties.type.enum;
    const seen=new Set();
    for (const c of Object.values(idx.capabilities)) for (const f of (c.files||[])) if (f.type) seen.add(f.type);
    if (!seen.size) errs.push("index 里没有任何 type —— 断言退化，无法互校契约");
    for (const t of seen) if (!ENUM.includes(t)) errs.push("index 出现 type=" + t + "，但 knowledge-index.schema.json 的 enum 不含它（产物 vs 契约漂移）");

    if (errs.length){ console.error(errs.join("\n")); process.exit(1); }
    console.log("index 结构合法 + Candidate 被过滤 + rules 恒入 + type 全覆盖于 schema enum");
  ' "$INDEX" "$SUITE_ROOT/runtime/state/schemas/knowledge-index.schema.json"; then
    pass "compiler: index 结构合法 + lifecycle 过滤正确"
  else
    fail "compiler: index 断言失败（见上）"
  fi
else
  fail "compiler: 运行失败（exit=$?）"
fi

echo ""
echo "=== 2. resolver → context-package.json（结构 + 分桶） ==="
if bash "$SCRIPT_DIR/knowledge-resolver.sh" "$FIXTURE" >/dev/null; then
  if node -e '
    const fs=require("fs");
    const pkg=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const errs=[];
    for (const k of ["schemaVersion","generatedBy","generatedAt","context"]) if(!(k in pkg)) errs.push("missing "+k);
    if (pkg.generatedBy!=="knowledge-resolver") errs.push("generatedBy ≠ knowledge-resolver");
    const ctx=pkg.context||{};
    if (!Array.isArray(ctx.rules)) errs.push("context.rules 应为数组");
    if (!Array.isArray(ctx.knowledge)) errs.push("context.knowledge 应为数组");
    if (!Array.isArray(ctx.guidance)) errs.push("context.guidance 应为数组");
    const know=(ctx.knowledge||[]).map(e=>e.source);
    if (!know.includes("patterns/table.md")) errs.push("patterns/table.md 应在 knowledge 桶");
    if (know.includes("patterns/upload.md")) errs.push("patterns/upload.md(Candidate) 不应进入 context-package");
    const ruleSrc=(ctx.rules||[]).map(e=>e.source);
    if (!ruleSrc.includes("rules/form-standard.md")) errs.push("rules/form-standard.md 应进入 context.rules");
    // ⚠️ recommendation 的**消费端**断言（2026-09-18 补）：
    //    此前本文件只断言「recommendation 进了 knowledge-index.json」（Producer 侧），
    //    没有断言「它进了 context.recommendations[]」（Consumer 侧）——于是 resolver 缺分支、
    //    schema 缺字段、recommendation 被塞进 knowledge 桶，全程无人报错。
    const recSrc=(ctx.recommendations||[]).map(e=>e.source);
    if (!recSrc.includes("recommendations/use-composable.md"))
      errs.push("recommendations/use-composable.md 应进入 context.recommendations");
    if (know.includes("recommendations/use-composable.md"))
      errs.push("recommendation 被错误塞进 knowledge 桶（应独立成桶）");
    if (errs.length){ console.error(errs.join("\n")); process.exit(1); }
    console.log("context-package 结构合法 + 分桶正确");
  ' "$PKG"; then
    pass "resolver: context-package 结构合法 + 分桶正确"
  else
    fail "resolver: context-package 断言失败（见上）"
  fi
else
  fail "resolver: 运行失败（exit=$?）"
fi

echo ""
echo "=== 3. change-detection：status 晋升（Candidate→Accepted）触发重扫 ==="
cat > "$FIXTURE/runtime/knowledge.json" <<'EOF'
{"files":{
  "patterns/table.md":{"status":"Accepted","occurrences":3},
  "patterns/upload.md":{"status":"Accepted","occurrences":3},
  "components/catalog.md":{"status":"Accepted","occurrences":2},
  "api/order.md":{"status":"Accepted","occurrences":2},
  "architecture/overview.md":{"status":"Accepted","occurrences":2}
}}
EOF
if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null; then
  if node -e '
    const fs=require("fs");
    const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const pats=(idx.capabilities.patterns||{}).files||[];
    if (!pats.some(f=>f.source==="patterns/upload.md")) { console.error("upload.md 晋升 Accepted 后应入 index（hash 未包含 knowledge.json？）"); process.exit(1); }
    console.log("status 晋升 → 重扫生效");
  ' "$INDEX"; then
    pass "change-detection: knowledge.json status 变化触发重扫"
  else
    fail "change-detection: 断言失败（见上）"
  fi
else
  fail "change-detection: compiler 运行失败（exit=$?）"
fi

echo ""
echo "=== 4. change-detection：重命名与编译器身份都触发重扫 ==="

# 4a: 无变化 → 复用
out="$(bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" 2>&1 || true)"
case "$out" in
  *"No change"*) pass "4a 源无变化 → 复用已有 index" ;;
  *)             fail "4a 源无变化时应输出 'No change'（判定键失效）" ;;
esac

# 4b: 仅重命名（内容一字不改）→ 必须重扫，且 index 的 source 跟随更新
#     旧实现把全部源内容拼成一个 hash，路径不参与 → 重命名不触发重扫，index 的 source 指向不存在路径
mv "$FIXTURE/patterns/table.md" "$FIXTURE/patterns/table-renamed.md"
if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null; then
  if node -e '
    const fs=require("fs");
    const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const srcs=((idx.capabilities.patterns||{}).files||[]).map(f=>f.source);
    const errs=[];
    if (!srcs.includes("patterns/table-renamed.md")) errs.push("重命名后的 source 未进 index");
    if (srcs.includes("patterns/table.md")) errs.push("旧 source 仍在 index（重命名未触发重扫）");
    if (errs.length){ console.error(errs.join("\n")); process.exit(1); }
    console.log("重命名触发重扫，source 已跟随");
  ' "$INDEX"; then
    pass "4b 重命名（内容不变）触发重扫，index source 跟随更新"
  else
    fail "4b 断言失败（见上）"
  fi
else
  fail "4b compiler 运行失败（exit=$?）"
fi

# 4c: 编译器身份参与判定 —— 用「改过 SCHEMA_VERSION 的编译器副本」模拟版本升级
#     身份不参与的话，schemaVersion 变更后旧 index 会被误判为「无变化」而沿用（AFC 项目实测过这种漂移）
#     注意：本步会让 fixture 的 .hash 变成副本写入的值，故必须是 section 4 的最后一步
PATCHED="$FIXTURE/knowledge-compiler-stale.sh"
sed 's|^SCHEMA_VERSION=".*"|SCHEMA_VERSION="0.0.0-stale"|' "$SCRIPT_DIR/knowledge-compiler.sh" > "$PATCHED"
if ! grep -q '^SCHEMA_VERSION="0.0.0-stale"' "$PATCHED"; then
  fail "4c 无法在编译器副本中改写 SCHEMA_VERSION（脚本常量被改名？）"
else
  out="$(bash "$PATCHED" "$FIXTURE" 2>&1 || true)"
  case "$out" in
    *"No change"*) fail "4c 编译器身份变化时应重扫，实际判定为「无变化」" ;;
    *)             pass "4c 编译器身份（schemaVersion）变化触发重扫" ;;
  esac
fi

echo ""
echo "=== 5. 契约守卫：rules/decisions 缺 constraint 必须硬失败 ==="

# 本用例是真实项目断链的回归锁。
# 实测（round11）：真实项目的 rules/decisions 常缺 constraint（人工产出 / analyzer 产出都可能漏），
# 编译器 exit 1 → 不生成 knowledge-index.json → 整条知识链中断；而旧 fixture 恰好带着 constraint，
# 于是「测试全绿、真实项目全挂」。此处锁定守卫必须存在，防止退化为静默产出不完整 index。
GUARD_FILE="$FIXTURE/rules/no-constraint-probe.md"
cat > "$GUARD_FILE" <<'EOF'
---
id: rules-no-constraint-probe
generatedBy: manual
lifecycle: confirmed
confidence: 90
---
# 无 constraint 的规则（探针）
EOF

out="$(bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" 2>&1 || true)"
case "$out" in
  *"缺少 constraint"*no-constraint-probe*)
    pass "5a 缺 constraint 的 rule → 编译器拒绝生成 index 且点名文件（守卫有效）" ;;
  *)
    fail "5a 缺 constraint 的 rule 未被拒绝/未点名文件（守卫失效，会静默产出不完整 index）" ;;
esac

cat > "$GUARD_FILE" <<'EOF'
---
id: rules-no-constraint-probe
generatedBy: manual
lifecycle: confirmed
confidence: 90
constraint: "探针约束（补齐后应可编译）"
---
# 补齐 constraint 的规则（探针）
EOF

if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null 2>&1; then
  pass "5b 补齐 constraint 后恢复正常编译（契约可被 Producer 满足）"
else
  fail "5b 补齐 constraint 后仍编译失败（Producer 无法满足该契约）"
fi
rm -f "$GUARD_FILE"

# 5c: 字段写在 frontmatter 后段（超过第 15 行）也必须被读到
#     实测（round13）：真实项目的 decisions 文件 `sources:` 列了多条，补齐的 constraint 落到第 17/19/24 行；
#     旧实现用 `sed -n '1,15p'` 硬窗口读字段 → **写了但读不到** → 「补齐成功」与「拒绝生成 index」同时成立，
#     链路依旧断着而两边日志都正常。frontmatter 没有行数上限，这里锁住「无硬窗口」。
LONG_FM="$FIXTURE/rules/long-frontmatter-probe.md"
{
  echo '---'
  echo 'id: rules-long-frontmatter-probe'
  echo 'generatedBy: manual'
  echo 'generatedAt: 2026-09-17T00:00:00Z'
  echo 'last_scan: 2026-09-17T00:00:00Z'
  echo 'lifecycle: confirmed'
  echo 'confidence: 95'
  echo 'sources:'
  for i in 1 2 3 4 5 6 7 8 9 10; do echo "  - probe/source-$i.ts"; done
  echo 'constraint: "长 frontmatter 探针约束（必须能被读到）"'
  echo '---'
  echo '# 长 frontmatter 探针'
} > "$LONG_FM"
PROBE_LINE="$(grep -n '^constraint:' "$LONG_FM" | cut -d: -f1)"

if bash "$SCRIPT_DIR/knowledge-compiler.sh" "$FIXTURE" >/dev/null 2>&1; then
  if node -e '
    const fs=require("fs");
    const idx=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const srcs=((idx.capabilities.rules||{}).files||[]).map(f=>f.source);
    process.exit(srcs.includes("rules/long-frontmatter-probe.md") ? 0 : 1);
  ' "$INDEX"; then
    pass "5c frontmatter 字段位于第 ${PROBE_LINE} 行仍被读到（无 15 行硬窗口）"
  else
    fail "5c 编译器未报错但探针未进 index（字段读了、文件没索引？）"
  fi
else
  fail "5c frontmatter 字段位于第 ${PROBE_LINE} 行未被读到 —— 硬窗口 bug 回归（字段写了但读不到）"
fi
rm -f "$LONG_FM"

echo ""
echo "========================================"
echo " Summary: Pass=$PASS  Fail=$FAIL"
echo "========================================"
if [ "$FAIL" -gt 0 ]; then
  red "❌ KNOWLEDGE PIPELINE CLOSED-LOOP FAILED"
  exit 1
else
  green "✅ KNOWLEDGE PIPELINE CLOSED-LOOP PASSED"
  exit 0
fi
