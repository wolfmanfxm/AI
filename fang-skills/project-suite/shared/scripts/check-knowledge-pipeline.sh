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
