#!/bin/bash
# Event Timeline Viewer v1.0
# Reads .project-knowledge/runtime/events.jsonl and displays event timeline + stats
# Node-only（无 Python 依赖）
#
# Usage: bash shared/scripts/show-events.sh [project-root]

set -euo pipefail
PROJECT_ROOT="${1:-.}"
EVENTS_FILE="$PROJECT_ROOT/.project-knowledge/runtime/events.jsonl"

if [ ! -f "$EVENTS_FILE" ]; then
  echo "No events found. Run any project-suite skill to generate events."
  exit 0
fi

# JSON 字段抽取（Node，替代 python3）
jget() {
  node -e 'let v;try{const d=JSON.parse(require("fs").readFileSync(0,"utf8"));v=d[process.argv[1]]}catch(e){v=null}process.stdout.write(v==null?"?":String(v))' "$1" 2>/dev/null
}

echo "========================================"
echo " Event Timeline"
echo "========================================"
echo ""

# Parse and display events
while IFS= read -r line; do
  event=$(echo "$line" | jget event)
  skill=$(echo "$line" | jget skill)
  stage=$(echo "$line" | jget stage)
  ts=$(echo "$line" | jget timestamp)
  ts="${ts:0:19}"

  case "$event" in
    StageStarted)      icon="▶";  detail="";;
    StageCompleted)    conf=$(echo "$line" | jget confidence); icon="✅"; detail="(${conf}%)";;
    StageFailed)       icon="❌"; detail="";;
    ArtifactGenerated) file=$(echo "$line" | jget file_path); size=$(echo "$line" | jget file_size); icon="📄"; detail="$file (${size}B)";;
    PipelineAdvanced)  from=$(echo "$line" | jget from_stage); to=$(echo "$line" | jget to_stage); icon="→"; detail="$from → $to"; stage="";;
    GateTriggered)     level=$(echo "$line" | jget gate_level); icon="🚦"; detail="$level";;
    CheckpointReached) icon="🛑"; detail="";;
    RecoveryStarted)   icon="🔄"; detail="";;
    *)                 icon="•"; detail="";;
  esac
  printf "  %s %s  %-18s %-12s %s\n" "$ts" "$icon" "$event" "$stage" "$detail"
done < "$EVENTS_FILE"

echo ""
echo "========================================"
echo " Stats"
echo "========================================"

total=$(wc -l < "$EVENTS_FILE" | tr -d ' ')
echo "  Total events: $total"

for e in StageStarted StageCompleted StageFailed ArtifactGenerated GateTriggered CheckpointReached; do
  # `|| echo 0` 会在零匹配时补成两行 `0\n0`（grep -c 已打印过一个 0）→ 显示成乱码（2026-09-18 修）
  count=$(grep -c "\"event\":\"$e\"" "$EVENTS_FILE" 2>/dev/null || true); count=${count:-0}
  echo "  $e: $count"
done

# Calculate durations
echo ""
echo "  Stage Durations:"
node -e '
const fs = require("fs");
const lines = fs.readFileSync(process.argv[1], "utf8").split("\n").filter(Boolean);
const starts = {};
for (const line of lines) {
  let d; try { d = JSON.parse(line); } catch { continue; }
  const k = d.skill + "|" + d.stage;
  if (d.event === "StageStarted") starts[k] = d.timestamp;
  else if (d.event === "StageCompleted" && starts[k] != null) {
    const s = Date.parse(starts[k]), e = Date.parse(d.timestamp);
    if (!isNaN(s) && !isNaN(e)) {
      console.log(`    ${d.skill}/${d.stage}: ${Math.round((e - s) / 1000)}s`);
    }
    delete starts[k];
  }
}' "$EVENTS_FILE" 2>/dev/null || echo "    (no completed stages)"
