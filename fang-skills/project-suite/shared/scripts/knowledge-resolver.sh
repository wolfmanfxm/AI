#!/bin/bash
# Knowledge Resolver v1.2.0
#
# 分桶 + hydrate + 候选集过滤。读取 knowledge-index.json，按 type 分桶产出 context-package.json。
# 逻辑实现见 knowledge-resolver.mjs（Node-only，无 Python 依赖）。
#
# 关键（见 runtime/knowledge-resolver.md 步骤 4-5）：
#   - constraints（rules + project-scope decisions）：恒全量，不参与 Top-K，不被 pattern 挤掉
#   - knowledge（patterns/components/api）：P2，受 candidates + Top-K 约束
#   - guidance（experience/playbooks + task-scope decisions）：P3/advisory，受 candidates + Top-K 约束
#   - recommendations（项目级应然建议，recommendations/）：advisory，与 knowledge 分开——
#     knowledge 说「现状是什么」，recommendations 说「新代码该往哪走」
#   - hydrate：读命中 source 的 frontmatter（constraint/statement/summary）→ 注入 pattern/constraints
#
# 候选集（#3）：Planner 的 # Reuse Analysis 产出命中的 source 路径 / capability 名 / tag / basename，
#   作为第 2 个参数传入（逗号分隔）。传了 candidates 才触发过滤 + Top-K；不传 = 全量（向后兼容）。
#   rank：priority → confidence↓ → tag-overlap↓ → source 字母序。
#   Top-K：knowledge 默认 5，guidance 默认 3。
#   全未命中 → stderr 显式告警（避免 garbage candidates 静默返回空 knowledge）。
#
# Lifecycle 插槽（暂不消费，见 runtime/knowledge/knowledge-decay.md）：
#   `.lifecycle/health.json` 存在 → 未来做降级（stale→warning / decaying→非 blocking / deprecated→排除）
#   `.lifecycle/health.json` 缺失 → 正常行为，**不推断 decay**（无可靠 Producer，不伪造衰减判断）
#
# Task Identity（见 runtime/mechanisms/task-identity.md）：
#   --task <task_id> 或 $PS_TASK_ID → 输出到 <dir>/runtime/tasks/<task_id>/context-package.json
#   未指定 task → 保留根路径 <dir>/context-package.json（legacy 回退，stderr 告警）
#
# Usage: bash shared/scripts/knowledge-resolver.sh [project-knowledge-dir] ["source1,source2,cap3,tag4"] [--task <task_id>]
# Output: <dir>/runtime/tasks/<task_id>/context-package.json  |  <dir>/context-package.json (legacy)

set -euo pipefail

KNOWLEDGE_DIR=".project-knowledge"
CANDIDATES=""
TASK_ID=""
POSITIONAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --task) TASK_ID="${2:-}"; shift 2 ;;
    *) POSITIONAL=$((POSITIONAL+1))
       if [ "$POSITIONAL" -eq 1 ]; then KNOWLEDGE_DIR="$1"
       elif [ "$POSITIONAL" -eq 2 ]; then CANDIDATES="$1"
       else echo "knowledge-resolver: unexpected arg '$1'" >&2; exit 64; fi
       shift ;;
  esac
done
[ -n "$TASK_ID" ] || TASK_ID="${PS_TASK_ID:-}"

mkdir -p "$KNOWLEDGE_DIR"
INDEX="${KNOWLEDGE_DIR}/knowledge-index.json"
if [ -n "$TASK_ID" ]; then
  OUT="${KNOWLEDGE_DIR}/runtime/tasks/${TASK_ID}/context-package.json"
  mkdir -p "$(dirname "$OUT")"
else
  OUT="${KNOWLEDGE_DIR}/context-package.json"
  echo "⚠️  knowledge-resolver: 未指定 --task，写入 legacy 根路径 $OUT。任务级隔离要求 --task <task_id>（见 runtime/mechanisms/task-identity.md）" >&2
fi
GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ ! -f "$INDEX" ]; then
  echo "No knowledge-index.json found. Run knowledge-compiler.sh first." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
node "$SCRIPT_DIR/knowledge-resolver.mjs" "$KNOWLEDGE_DIR" "$GENERATED_AT" "$INDEX" "$OUT" "$CANDIDATES" "$TASK_ID"
