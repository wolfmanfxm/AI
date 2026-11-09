#!/bin/bash
# Telemetry Collector v1.1
# Aggregates execution metrics from .project-knowledge/runtime/ across sessions.
# No external service needed — reads local state files.
#
# Execution metrics are timeline-first (append-only source of truth), with
# state.json as a legacy fallback for projects that predate timeline.jsonl.
#
# Usage: bash shared/scripts/collect-metrics.sh [project-root]
# Output: <project-root>/.project-knowledge/reports/telemetry-report.md
#
# 报告落在**被采集项目**的知识库内，不写进 project-suite 包——它是项目运行产物，
# 与 skill 能力无关，且不同项目的数据不能互相覆盖。

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
REPORT_DIR="$PROJECT_ROOT/.project-knowledge/reports"

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

mkdir -p "$REPORT_DIR"

# ═══ Collect data ═══
#
# 执行指标（次数/状态/confidence/skills）与时长**同源**：优先用 timeline。
# 旧实现只从 state.json 数执行次数、从 timeline 数时长 → 只有 timeline 的项目
# （协议的正常形态：timeline 是执行事实的唯一 append-only 记录）报告「Executions: 0」，
# 而同一份报告又写「Total timeline entries: 1」。现改为：
#   ① timeline 有有效记录 → 全部执行指标取自 timeline（source=timeline）
#   ② timeline 无记录/不可读 → 回退 state.json（兼容旧项目，source=state.json）
#   ③ 两者皆无 → 0，并显式标注 source=none

metrics_source="none"
total_executions=0; completed=0; partial=0; blocked_count=0; failed_count=0
avg_confidence=0; confidence_samples=0; skills_used=""
total_timeline_entries=0; min_dur=0; max_dur=0; avg_dur=0; dur_count=0

# 2. Timeline metrics（v2 JSONL 优先，回退 v1 对象）
#
# timeline-stats.mjs 在读取时聚合（不信任落盘 aggregates），--shell 输出
# KEY=value 行供这里解析；默认五字段输出保持不变，其它消费者不受影响。
TIMELINE_SOURCE=""
for candidate in "$TIMELINE_JSONL" "$TIMELINE_JSON" "$TIMELINE_LEGACY"; do
  if [ -f "$candidate" ]; then TIMELINE_SOURCE="$candidate"; break; fi
done

if [ -n "$TIMELINE_SOURCE" ]; then
  tl_total=0; tl_completed=0; tl_degraded=0; tl_blocked=0; tl_failed=0
  tl_avg_conf=0; tl_conf_samples=0; tl_skills=""

  tl_output=$(node "$SCRIPT_DIR/timeline-stats.mjs" "$TIMELINE_SOURCE" --shell 2>/dev/null || true)
  if [ -n "$tl_output" ]; then
    while IFS='=' read -r key value; do
      case "$key" in
        TOTAL_RUNS)         tl_total="$value" ;;
        COMPLETED)          tl_completed="$value" ;;
        DEGRADED)           tl_degraded="$value" ;;
        BLOCKED)            tl_blocked="$value" ;;
        FAILED)             tl_failed="$value" ;;
        AVG_CONFIDENCE)     tl_avg_conf="$value" ;;
        CONFIDENCE_SAMPLES) tl_conf_samples="$value" ;;
        SKILLS)             tl_skills="$value" ;;
        DURATION_SAMPLES)   dur_count="$value" ;;
        MIN_SECONDS)        min_dur="$value" ;;
        MAX_SECONDS)        max_dur="$value" ;;
        AVG_SECONDS)        avg_dur="$value" ;;
      esac
    done <<< "$tl_output"
    total_timeline_entries="$tl_total"
  fi

  if [ "$tl_total" -gt 0 ]; then
    metrics_source="timeline"
    total_executions="$tl_total"
    completed="$tl_completed"
    # timeline 的 degraded 对应报告里的 Partial/Interrupted
    partial="$tl_degraded"
    blocked_count="$tl_blocked"
    failed_count="$tl_failed"
    avg_confidence="$tl_avg_conf"
    confidence_samples="$tl_conf_samples"
    skills_used="$tl_skills"
  fi
fi

# 1. Execution history from state.json（仅在 timeline 无有效记录时回退）
if [ "$metrics_source" = "none" ] && [ -f "$STATE_FILE" ]; then
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
    confidence_samples=$count
  fi

  # Skills used
  skills_used=$(grep -oE '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' | sort -u | tr '\n' ',' | sed 's/,$//' || true)
  metrics_source="state.json"
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

if [ "$confidence_samples" -gt 0 ]; then
  avg_confidence_display="${avg_confidence}%"
else
  avg_confidence_display="n/a (no samples)"
fi

# ═══ Write report ═══

cat > "$REPORT" << EOF
# Telemetry Report

> Generated: $TODAY | Source: \`.project-knowledge/runtime/\` | No external service

## Summary

| Metric | Value |
|--------|-------|
| Execution metrics source | $metrics_source |
| Total executions | $total_executions |
| Completed | $completed |
| Partial/Interrupted | $partial |
| Blocked (confidence gate) | $blocked_count |
| Failed | $failed_count |
| Avg confidence | ${avg_confidence_display} |
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

- **Confidence trend**: $(if [ "$confidence_samples" -gt 0 ]; then echo "avg ${avg_confidence}% — $(if [ "$avg_confidence" -ge 80 ]; then echo "healthy"; elif [ "$avg_confidence" -ge 60 ]; then echo "needs attention"; else echo "critical"; fi)"; else echo "no confidence samples"; fi)
- **Reliability**: $completed/$total_executions completed (${success_pct}%)
- **Interruptions**: $partial partial/interrupted — checkpoint protocol should enable resume

---

> This report is generated locally from \`.project-knowledge/runtime/\` files.
> For cross-project or team-level aggregation, feed this data into your observability stack.
EOF

echo "Telemetry report: $REPORT"
echo "  Source: $metrics_source | Executions: $total_executions | Completed: $completed | Avg confidence: ${avg_confidence_display}"
echo "  Skills: ${skills_used:-none}"
