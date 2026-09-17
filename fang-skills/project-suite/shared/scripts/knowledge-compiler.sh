#!/bin/bash
# Knowledge Compiler v1.1.0
#
# 汇总、分类、索引知识。扫描全部知识源，打上统一 Knowledge Metadata，生成 knowledge-index.json。
#
# 职责（见 runtime/knowledge/knowledge-compiler.md）：
#   - graph.json（analyzer 产出结构事实）不是 Compiler 输入，由 Planner/Architect/Generator 经 graph-query 直接查询
#   - rules/decisions/experience/playbooks（用户手写强制约束）必须扫进来，恒入 index
#   - 只存 metadata，不复制 Markdown 正文
#   - lifecycle 过滤：仅 analyzer 产出的目录（patterns/components/api/architecture）
#     读 runtime/knowledge.json，排除 status 明确为「非 Accepted」的 source
#
# Usage: bash shared/scripts/knowledge-compiler.sh [project-knowledge-dir]
#         project-knowledge-dir 默认 .project-knowledge（相对 cwd）——产物一律写在这个目录内，
#         不写项目根目录
# Output: <dir>/knowledge-index.json
#         <dir>/knowledge-index.hash（change-detection 摘要：编译器身份 + 每源路径与内容摘要折叠而成）

set -euo pipefail

KNOWLEDGE_DIR="${1:-.project-knowledge}"
mkdir -p "$KNOWLEDGE_DIR"
OUT="${KNOWLEDGE_DIR}/knowledge-index.json"
GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STATUS_FILE="${KNOWLEDGE_DIR}/runtime/knowledge.json"
GENERATED_BY="knowledge-compiler"
SCHEMA_VERSION="1.1.0"
COMPILER_ID="${GENERATED_BY}/${SCHEMA_VERSION}"

# --- 自校验（先于任何写盘）：rules/decisions 必须有 constraint，缺失则 exit 1，绝不落盘 invalid index/hash ---
MISSING_CONSTRAINT=0
for f in $(find "$KNOWLEDGE_DIR/rules" "$KNOWLEDGE_DIR/decisions" -name "*.md" -not -name "index.md" -type f 2>/dev/null | sort); do
  if ! sed -n '1,15p' "$f" | grep -q '^constraint:'; then
    echo "❌ 缺少 constraint: ${f#"$KNOWLEDGE_DIR"/}"
    MISSING_CONSTRAINT=$((MISSING_CONSTRAINT + 1))
  fi
done
if [ "$MISSING_CONSTRAINT" -gt 0 ]; then
  echo "❌ ${MISSING_CONSTRAINT} 个 rules/decisions 缺少 constraint 字段（REQUIRED，拒绝生成 index）"
  exit 1
fi
echo "✅ 所有 rules/decisions 均含 constraint"

# --- change-detection：源文件无变化则复用 index，不重扫（改 rule 不重跑 analyzer） ---
# 摘要 = 编译器身份 + 每源 `<路径, 内容摘要>`，折叠成一个 shasum 后存入 .hash。三项都要参与：
#   1. 路径参与 → 重命名（内容不变）也触发重扫，避免 index 的 source 指向已不存在的路径
#   2. 编译器身份参与 → schemaVersion 变更时旧 index 不会被误判为「无变化」而沿用
#   3. knowledge.json 参与 → lifecycle status 变化（Candidate→Accepted）也触发重扫
# ⚠️ 边界（勿扩张）：本文件只承载「当前 index 是否要重扫」这一个判定，只存最终摘要。
#    不落逐源清单、不塞配置/resolver/routing/consumer 状态——那会把它变成第二个 metadata registry。
#    逐源事实等出现真实消费方时再抽成正式产物（当前无 Consumer，不预建）。
HASH_FILE="${KNOWLEDGE_DIR}/knowledge-index.hash"
SOURCE_HASH="$(
  {
    printf 'compiler: %s\n' "$COMPILER_ID"
    cd "$KNOWLEDGE_DIR" || exit 1
    # 单次批量 shasum —— 逐源单独调用 shasum 会让热路径慢 33x（101 源实测 4.7s vs 0.2s）
    # -print0/-z/-0 保证空格等特殊字符不被分词；空输入必须先挡掉——
    # xargs 无输入会以无参运行 shasum，此时 shasum 会去读 stdin（交互场景下挂住）
    MD_COUNT="$(find . -name "*.md" -not -name "index.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$MD_COUNT" -gt 0 ]; then
      find . -name "*.md" -not -name "index.md" -type f -print0 2>/dev/null | LC_ALL=C sort -z |
        xargs -0 shasum -a 256
    fi
    if [ -f runtime/knowledge.json ]; then shasum -a 256 runtime/knowledge.json; fi
  } | shasum -a 256 | cut -d' ' -f1
)"

if [ -f "$OUT" ] && [ -f "$HASH_FILE" ] && [ "$(cat "$HASH_FILE")" = "$SOURCE_HASH" ]; then
  echo "No change — reuse $OUT"
  exit 0
fi

# --- lifecycle 过滤（仅作用于 analyzer 产出的目录）---
# 读 knowledge.json（analyzer 产出），把 status 明确为「非 Accepted」的 source 加入排除清单。
# 只过滤 analyzer 产出的目录（patterns/components/api/architecture）；
# rules/decisions/experience/playbooks 是用户手写的权威约束，恒入 index，不受 lifecycle 过滤。
# knowledge.json 缺失 → 排除清单为空 → 不过滤（bootstrap 向后兼容，不丢未分类文件）。
EXCLUDED_FILE="$(mktemp "${TMPDIR:-/tmp}/kc-excluded.XXXXXX")"
trap 'rm -f "$EXCLUDED_FILE"' EXIT
node -e '
  const fs = require("fs");
  const p = process.argv[1];
  if (!fs.existsSync(p)) process.exit(0);
  let j;
  try { j = JSON.parse(fs.readFileSync(p, "utf8")); } catch { process.exit(0); }
  for (const [src, meta] of Object.entries(j.files || {})) {
    const st = String((meta && meta.status) || "").toLowerCase();
    if (st && st !== "accepted") console.log(src);
  }
' "$STATUS_FILE" > "$EXCLUDED_FILE" 2>/dev/null || : > "$EXCLUDED_FILE"

# 目录 → (capability, description, type, enforcement, priority)
# 确定性：capability 按目录分组（语义聚类留给 analyzer/LLM，本脚本只做确定性的分类+打标签）
# 映射规则见 knowledge-compiler.md「元数据映射」

detect_scope() {
  # 决策 scope：优先 frontmatter `scope:`，否则按文件名约定（ARCHITECTURE-* → task，其余 → project）
  local f="$1" s
  s="$(sed -n '1,15p' "$f" | grep -m1 '^scope:' | sed 's/^scope:[[:space:]]*//' | tr -d '[:space:]"' 2>/dev/null || true)"
  if [ -z "$s" ]; then
    case "$(basename "$f")" in
      ARCHITECTURE-*) s="task" ;;
      *) s="project" ;;
    esac
  fi
  printf '%s' "$s"
}

emit_files() {
  # 参数: dir type enforcement priority filter_lifecycle(0/1)
  # 输出一行 JSON 数组元素，用 '\n' 分隔（不含外层方括号）
  # decisions/ 特殊：按 scope 逐文件覆盖 enforcement/priority（task → advisory/P2，project → blocking/P1）
  local dir="$1" type="$2" enforcement="$3" priority="$4" filter_lifecycle="${5:-0}"
  local n=0
  for f in $(find "$KNOWLEDGE_DIR/$dir" -name "*.md" -type f 2>/dev/null | sort); do
    # 跳过目录导航索引（index.md 是聚合导航，不是知识对象）
    [ "$(basename "$f")" = "index.md" ] && continue
    local rel="${f#"$KNOWLEDGE_DIR"/}"
    # lifecycle 过滤：仅 analyzer 产出的目录，跳过 status 明确非 Accepted 的 source
    if [ "$filter_lifecycle" = "1" ] && [ -s "$EXCLUDED_FILE" ] && grep -qxF "$rel" "$EXCLUDED_FILE" 2>/dev/null; then
      continue
    fi
    local en="$enforcement" pri="$priority" scope=""
    if [ "$type" = "decision" ]; then
      scope="$(detect_scope "$f")"
      if [ "$scope" = "task" ]; then en="advisory"; pri="P2"; else en="blocking"; pri="P1"; fi
    fi
    [ "$n" -gt 0 ] && printf ',\n'
    if [ -n "$scope" ]; then
      printf '      {"source": "%s", "type": "%s", "scope": "%s", "enforcement": "%s", "priority": "%s"}' \
        "$rel" "$type" "$scope" "$en" "$pri"
    else
      printf '      {"source": "%s", "type": "%s", "enforcement": "%s", "priority": "%s"}' \
        "$rel" "$type" "$en" "$pri"
    fi
    n=$((n + 1))
  done
}

emit_capability() {
  # 参数: capability description dir type enforcement priority filter_lifecycle(0/1)
  # 只在目录存在且非空时输出一个 capability 对象（含外层方括号+files）
  local cap="$1" desc="$2" dir="$3" type="$4" enforcement="$5" priority="$6" filter_lifecycle="${7:-0}"
  local body
  body="$(emit_files "$dir" "$type" "$enforcement" "$priority" "$filter_lifecycle")"
  if [ -n "$body" ]; then
    printf '    "%s": {\n' "$cap"
    printf '      "description": "%s",\n' "$desc"
    printf '      "files": [\n%s\n      ]\n' "$body"
    printf '    }'
  fi
}

# 依次输出各 capability，处理逗号分隔
FIRST=1
emit_one() {
  local out
  out="$(emit_capability "$1" "$2" "$3" "$4" "$5" "$6" "$7")"
  [ -z "$out" ] && return 0
  [ "$FIRST" -eq 0 ] && printf ',\n'
  printf '%s' "$out"
  FIRST=0
}

{
  printf '{\n'
  printf '  "schemaVersion": "%s",\n' "$SCHEMA_VERSION"
  printf '  "generatedBy": "%s",\n' "$GENERATED_BY"
  printf '  "generatedAt": "%s",\n' "$GENERATED_AT"
  printf '  "capabilities": {\n'

  emit_one "rules"       "用户手写的强制编码规则"          "rules"       "rule"       "blocking"     "P1" 0
  emit_one "decisions"   "用户手写的架构决策 ADR"           "decisions"   "decision"   "blocking"     "P1" 0
  emit_one "patterns"    "代码发现的模式（analyzer 产出）"   "patterns"    "pattern"    "recommended"  "P2" 1
  emit_one "components"  "组件编目"                        "components"  "component"  "recommended"  "P2" 1
  emit_one "api"         "API 接口文档"                     "api"         "api"        "recommended"  "P2" 1
  emit_one "architecture" "架构总览"                        "architecture" "pattern"   "recommended"  "P2" 1
  emit_one "experience"  "项目经验教训"                     "experience"  "experience" "advisory"     "P3" 0
  emit_one "playbooks"   "操作手册"                         "playbooks"   "playbook"   "recommended"  "P3" 0
  emit_one "recommendations" "项目级应然建议（新代码改进，非现状规范）" "recommendations" "recommendation" "advisory" "P2" 0

  printf '\n  }\n'
  printf '}\n'
} > "${OUT}.tmp"
mv "${OUT}.tmp" "$OUT"

printf '%s' "$SOURCE_HASH" > "$HASH_FILE"

EXCLUDED_COUNT="$(wc -l < "$EXCLUDED_FILE" | tr -d ' ')"
echo "Generated: $OUT"
echo "  capabilities: rules decisions patterns components api architecture experience playbooks recommendations"
echo "  lifecycle-filtered (non-Accepted): ${EXCLUDED_COUNT}"
