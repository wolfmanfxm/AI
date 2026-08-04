#!/bin/bash
# Telemetry Collector v1.0
# Aggregates execution metrics from .project-runtime/ across sessions.
# No external service needed — reads local state files.
#
# Usage: bash shared/scripts/collect-metrics.sh [project-root]
# Output: reports/telemetry-report.md

set -euo pipefail
PROJECT_ROOT="${1:-.}"
RUNTIME_DIR="$PROJECT_ROOT/.project-runtime"
STATE_FILE="$RUNTIME_DIR/state.json"
TIMELINE_FILE="$RUNTIME_DIR/timeline.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="$SUITE_ROOT/reports"
mkdir -p "$REPORT_DIR"

REPORT="$REPORT_DIR/telemetry-report.md"
TODAY=$(date +%Y-%m-%d)

# ═══ Collect data ═══

# 1. Execution history from state.json
if [ -f "$STATE_FILE" ]; then
  total_executions=$(grep -c '"skill"' "$STATE_FILE" 2>/dev/null || echo 0)
  completed=$(grep -c '"status": "completed"' "$STATE_FILE" 2>/dev/null || echo 0)
  partial=$(grep -c '"status": "partial"' "$STATE_FILE" 2>/dev/null || echo 0)
  blocked_count=$(grep -c '"BLOCK' "$STATE_FILE" 2>/dev/null || echo 0)

  # Avg confidence (extract numbers, average)
  confidences=$(grep -o '"confidence": [0-9]*' "$STATE_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "")
  if [ -n "$confidences" ]; then
    sum=0; count=0
    for c in $confidences; do sum=$((sum + c)); count=$((count + 1)); done
    avg_confidence=$((sum / (count > 0 ? count : 1)))
  else
    avg_confidence=0
  fi

  # Skills used
  skills_used=$(grep -o '"skill": "[^"]*"' "$STATE_FILE" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' | sort -u | tr '\n' ',' | sed 's/,$//')
else
  total_executions=0; completed=0; partial=0; blocked_count=0; avg_confidence=0; skills_used=""
fi

# 2. Timeline metrics
if [ -f "$TIMELINE_FILE" ]; then
  total_timeline_entries=$(grep -c '"startedAt"' "$TIMELINE_FILE" 2>/dev/null || echo 0)

  # Extract durations (finishedAt - startedAt in seconds, if both present)
  durations=$(python3 -c "
import json, sys
try:
    with open('$TIMELINE_FILE') as f:
        entries = json.load(f)
    durations = []
    for e in entries if isinstance(entries, list) else []:
        if 'startedAt' in e and 'finishedAt' in e:
            from datetime import datetime
            try:
                start = datetime.fromisoformat(e['startedAt'].replace('Z','+00:00'))
                end = datetime.fromisoformat(e['finishedAt'].replace('Z','+00:00'))
                durations.append((end - start).total_seconds())
            except: pass
    if durations:
        print(f'{min(durations):.0f} {max(durations):.0f} {sum(durations)/len(durations):.0f} {len(durations)}')
    else:
        print('0 0 0 0')
except: print('0 0 0 0')
" 2>/dev/null || echo "0 0 0 0")
  read min_dur max_dur avg_dur dur_count <<< "$durations"
else
  total_timeline_entries=0; min_dur=0; max_dur=0; avg_dur=0; dur_count=0
fi

# 3. Manifest stats (check if any manifests exist)
manifest_count=$(find "$RUNTIME_DIR" -name "manifest.json" 2>/dev/null | wc -l | tr -d ' ')

# ═══ Write report ═══

cat > "$REPORT" << EOF
# Telemetry Report

> Generated: $TODAY | Source: \`.project-runtime/\` | No external service

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

- **Confidence trend**: avg ${avg_confidence}% — ${if [ "$avg_confidence" -ge 80 ]; then echo "healthy"; elif [ "$avg_confidence" -ge 60 ]; then echo "needs attention"; else echo "critical"; fi}
- **Reliability**: $completed/$total_executions completed ($(( total_executions > 0 ? completed * 100 / total_executions : 0 ))%)
- **Interruptions**: $partial partial/interrupted executions — checkpoint protocol should enable resume

---

> This report is generated locally from \`.project-runtime/\` files.
> For cross-project or team-level aggregation, feed this data into your observability stack.
EOF

echo "Telemetry report: $REPORT"
echo "  Executions: $total_executions | Completed: $completed | Avg confidence: ${avg_confidence}%"
echo "  Skills: ${skills_used:-none}"
