#!/bin/bash
# Event Timeline Viewer v1.0
# Reads .project-runtime/events.jsonl and displays event timeline + stats
#
# Usage: bash shared/scripts/show-events.sh [project-root]

set -euo pipefail
PROJECT_ROOT="${1:-.}"
EVENTS_FILE="$PROJECT_ROOT/.project-runtime/events.jsonl"

if [ ! -f "$EVENTS_FILE" ]; then
  echo "No events found. Run any project-suite skill to generate events."
  exit 0
fi

echo "========================================"
echo " Event Timeline"
echo "========================================"
echo ""

# Parse and display events
while IFS= read -r line; do
  event=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('event','?'))" 2>/dev/null || echo "parse_error")
  skill=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('skill','?'))" 2>/dev/null || echo "?")
  stage=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('stage','?'))" 2>/dev/null || echo "?")
  ts=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('timestamp','?')[:19])" 2>/dev/null || echo "?")

  case "$event" in
    StageStarted)      icon="▶";  detail="";;
    StageCompleted)    conf=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('confidence','?'))" 2>/dev/null); icon="✅"; detail="(${conf}%)";;
    StageFailed)       icon="❌"; detail="";;
    ArtifactGenerated) file=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_path','?'))" 2>/dev/null); size=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_size','?'))" 2>/dev/null); icon="📄"; detail="$file (${size}B)";;
    PipelineAdvanced)  from=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('from_stage','?'))" 2>/dev/null); to=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('to_stage','?'))" 2>/dev/null); icon="→"; detail="$from → $to"; stage="";;
    GateTriggered)     level=$(echo "$line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('gate_level','?'))" 2>/dev/null); icon="🚦"; detail="$level";;
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
  count=$(grep -c "\"event\":\"$e\"" "$EVENTS_FILE" 2>/dev/null || echo 0)
  echo "  $e: $count"
done

# Calculate durations
echo ""
echo "  Stage Durations:"
python3 -c "
import json, sys
starts = {}
with open('$EVENTS_FILE') as f:
    for line in f:
        d = json.loads(line)
        if d['event'] == 'StageStarted':
            starts[(d['skill'],d['stage'])] = d['timestamp']
        elif d['event'] == 'StageCompleted' and (d['skill'],d['stage']) in starts:
            from datetime import datetime
            start = datetime.fromisoformat(starts[(d['skill'],d['stage'])].replace('Z','+00:00'))
            end = datetime.fromisoformat(d['timestamp'].replace('Z','+00:00'))
            dur = (end - start).total_seconds()
            print(f'    {d[\"skill\"]}/{d[\"stage\"]}: {dur:.0f}s')
            del starts[(d['skill'],d['stage'])]
" 2>/dev/null || echo "    (no completed stages)"
