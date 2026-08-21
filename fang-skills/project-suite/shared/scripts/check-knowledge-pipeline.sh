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
#
# Usage: bash shared/scripts/check-knowledge-pipeline.sh
# Exit:  0 = 闭环通过；1 = 有断言失败

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

red()   { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

PASS=0; FAIL=0
pass() { green "  ✅ $1"; PASS=$((PASS+1)); }
fail() { red   "  ❌ $1"; FAIL=$((FAIL+1)); }

FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/kc-fixture.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/rules" "$FIXTURE/decisions" "$FIXTURE/patterns" \
         "$FIXTURE/components" "$FIXTURE/api" "$FIXTURE/architecture" \
         "$FIXTURE/experience" "$FIXTURE/playbooks" "$FIXTURE/runtime"

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
    if (errs.length){ console.error(errs.join("\n")); process.exit(1); }
    console.log("index 结构合法 + Candidate 被过滤 + rules 恒入");
  ' "$INDEX"; then
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
