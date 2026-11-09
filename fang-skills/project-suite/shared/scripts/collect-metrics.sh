#!/bin/bash
# Telemetry Collector v1.0
# Aggregates execution metrics from .project-knowledge/runtime/ across sessions.
# No external service needed — reads local state files.
#
# Usage: bash shared/scripts/collect-metrics.sh [project-root]
# Output: reports/telemetry-report.md

set -euo pipefail
PROJECT_ROOT="${1:-.}"
RUNTIME_DIR="$PROJECT_ROOT/.project-knowledge/runtime"
STATE_FILE="$RUNTIME_DIR/state.json"
# timeline 的唯一权威路径是 runtime/metrics/timeline.jsonl（v2，append-only）。
# 后两个是历史路径：metrics/timeline.json（v1 对象形态）与 runtime/timeline.json
# （更早的 collector 路径，与协议文档从未对齐）。读取时按顺序探测，写入只走 jsonl。
TIMELINE_JSONL="$RUNTIME_DIR/metrics/timeline.jsonl"
TIMELINE_JSON="$RUNTIME_DIR/metrics/timeline.json"
TIMELINE_LEGACY="$RUNTIME_DIR/timeline.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="$SUITE_ROOT/reports"
mkdir -p "$REPORT_DIR"

REPORT="$REPORT_DIR/telemetry-report.md"
TODAY=$(date +%Y-%m-%d)

# ═══ Guard: 前置检查 RUNTIME_DIR ═══
#
# 为什么需要：本脚本对**没有 .project-knowledge/runtime/ 的项目**运行时会**静默 exit 1**
#   （stdout/stderr 全空、不留报告），根因是两个抑制器合谋——
#   `manifest_count=$(find "$RUNTIME_DIR" … 2>/dev/null | wc -l)`：
#   ① `2>/dev/null` 吞掉 find 的报错；② `set -o pipefail` 让 find 的 exit 1 穿透管道；
#   最终 `set -e` 在无声中终止脚本。CI 里表现为「任务失败但无任何日志」。
#
# 处理原则：**响亮失败，而不是把「没有数据」伪装成「0 次执行」**——
#   后者正是本项目一直在清理的「假绿」问题（见 docs/roadmap.md G3）。
if [ ! -d "$RUNTIME_DIR" ]; then
  echo "❌ collect-metrics: 未找到 $RUNTIME_DIR" >&2
  echo "   该项目尚未执行过任何 skill，没有可采集的遥测数据。" >&2
  echo "   当前 project-root: $(cd "$PROJECT_ROOT" 2>/dev/null && pwd || echo "$PROJECT_ROOT")" >&2
  echo "   用法: bash shared/scripts/collect-metrics.sh <project-root>" >&2
  exit 1
fi

# ═══ Collect data ═══

# 1. Execution history from state.json
if [ -f "$STATE_FILE" ]; then
  # ⚠️ 不要写 `$(grep -c X f || echo 0)`：零匹配时 grep 已打印 0 且 exit 1，`|| echo 0` 再补一个
  #    → 变量成两行 `0\n0` → 指标数字报错/失真。
  # ⚠️ 必须容忍 JSON 的两种排版：文档样例 `"status": "completed"`（带空格）与
  #    JSON.stringify / timeline-append 产出的 `"status":"completed"`（无空格）。
  #    旧正则硬编码一个空格 → 对真实产物零匹配 → grep exit 1 → pipefail + set -e 让整个脚本静默退出。
  total_executions=$(grep -c '"skill"' "$STATE_FILE" 2>/dev/null || true); total_executions=${total_executions:-0}
  completed=$(grep -cE '"status"[[:space:]]*:[[:space:]]*"completed"' "$STATE_FILE" 2>/dev/null || true); completed=${completed:-0}
  partial=$(grep -cE '"status"[[:space:]]*:[[:space:]]*"partial"' "$STATE_FILE" 2>/dev/null || true); partial=${partial:-0}
  blocked_count=$(grep -c '"BLOCK' "$STATE_FILE" 2>/dev/null || true); blocked_count=${blocked_count:-0}

  # Avg confidence (extract numbers, average)
  confidences=$(grep -oE '"confidence"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "")
  if [ -n "$confidences" ]; then
    sum=0; count=0
    for c in $confidences; do sum=$((sum + c)); count=$((count + 1)); done
    avg_confidence=$((sum / (count > 0 ? count : 1)))
  else
    avg_confidence=0
  fi

  # Skills used
  skills_used=$(grep -oE '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' | sort -u | tr '\n' ',' | sed 's/,$//' || true)
else
  total_executions=0; completed=0; partial=0; blocked_count=0; avg_confidence=0; skills_used=""
fi

# 2. Timeline metrics（v2 JSONL 优先，回退 v1 对象）
#
# 旧实现在这里直接 JSON.parse 整个文件后按「顶层数组」遍历，但协议写的是
# {runs: []} 对象 → 永远得到 0 条 duration（假绿）。现统一交给 timeline-stats.mjs，
# 由它区分 .jsonl / v1 两种形态，且聚合在读取时计算，不信任落盘的 aggregates。
TIMELINE_SOURCE=""
for candidate in "$TIMELINE_JSONL" "$TIMELINE_JSON" "$TIMELINE_LEGACY"; do
  if [ -f "$candidate" ]; then TIMELINE_SOURCE="$candidate"; break; fi
done

if [ -n "$TIMELINE_SOURCE" ]; then
  durations=$(node "$SCRIPT_DIR/timeline-stats.mjs" "$TIMELINE_SOURCE" 2>/dev/null || echo "0 0 0 0 0")
  read -r total_timeline_entries min_dur max_dur avg_dur dur_count <<< "$durations"
else
  total_timeline_entries=0; min_dur=0; max_dur=0; avg_dur=0; dur_count=0
fi

# 3. Manifest stats（项目级 manifest.json + 任务级 manifest-<skill>.json）
manifest_count=$(find "$RUNTIME_DIR" -name "manifest*.json" 2>/dev/null | wc -l | tr -d ' ')

# ⚠️ 不能写成 $(( total_executions > 0 ? completed * 100 / total_executions : 0 ))：
#    bash 算术在求值 ternry 前就会对未选中分支的 `/ 0` 报错（实测 exit 1），
#    而没有 state.json 的真实项目 total_executions 恒为 0 → collect-metrics 直接崩溃。
if [ "$total_executions" -gt 0 ]; then
  success_pct=$(( completed * 100 / total_executions ))
else
  success_pct=0
fi

# ═══ Write report ═══

cat > "$REPORT" << EOF
# Telemetry Report

> Generated: $TODAY | Source: \`.project-knowledge/runtime/\` | No external service

## Summary

| Metric | Value |
|--------|-------|
| Total executions | $total_executions |
| Completed | $completed |
| Partial/Interrupted | $partial |
| Blocked (confidence gate) | $blocked_count |
| Avg confidence | ${avg_confidence}% |
| Skills used | ${skills_used:-none} |

## Duration (seconds)

| Metric | Value |
|--------|-------|
| Samples with timing | $dur_count |
| Min duration | ${min_dur}s |
| Max duration | ${max_dur}s |
| Avg duration | ${avg_dur}s |

## Timeline

| Metric | Value |
|--------|-------|
| Total timeline entries | $total_timeline_entries |
| Manifest files | $manifest_count |

## Missing Evidence (not collectable without external service)

| Item | Reason |
|------|--------|
| Token usage per session | Claude Code sessions don't expose token counts to file system |
| User satisfaction | No survey mechanism |
| Session count per day | No centralized counter |
| Concurrent sessions | No session registry |
| Error rate by type | Error details stay in session transcripts, not written to state |

## Interpretation

- **Confidence trend**: avg ${avg_confidence}% — $(if [ "$avg_confidence" -ge 80 ]; then echo "healthy"; elif [ "$avg_confidence" -ge 60 ]; then echo "needs attention"; else echo "critical"; fi)
- **Reliability**: $completed/$total_executions completed (${success_pct}%)
- **Interruptions**: $partial partial/interrupted executions — checkpoint protocol should enable resume

---

> This report is generated locally from \`.project-knowledge/runtime/\` files.
> For cross-project or team-level aggregation, feed this data into your observability stack.
EOF

echo "Telemetry report: $REPORT"
echo "  Executions: $total_executions | Completed: $completed | Avg confidence: ${avg_confidence}%"
echo "  Skills: ${skills_used:-none}"
