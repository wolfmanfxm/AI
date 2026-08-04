#!/bin/bash
# Cross-Run Reliability Checker v1.0
# Compares two .project-runtime/ snapshots to measure skill stability.
#
# Usage: bash shared/scripts/check-reliability.sh <snapshot-A> <snapshot-B> [skill-name]
#   snapshot-A/B: directories containing state.json + manifest.json + output files
#   skill-name:    optional, filter to one skill

set -euo pipefail

SNAPSHOT_A="${1:-}"
SNAPSHOT_B="${2:-}"
SKILL_FILTER="${3:-}"

if [ -z "$SNAPSHOT_A" ] || [ -z "$SNAPSHOT_B" ]; then
  echo "Usage: bash check-reliability.sh <snapshot-A-dir> <snapshot-B-dir> [skill-name]"
  echo ""
  echo "Snapshots are directories containing .project-runtime/ files from two different runs."
  echo "Create a snapshot: cp -r .project-runtime/ snapshots/run-$(date +%Y%m%d-%H%M%S)/"
  exit 1
fi

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

STATE_A="$SNAPSHOT_A/state.json"
STATE_B="$SNAPSHOT_B/state.json"
PASS=0; WARN=0; FAIL=0

echo "========================================"
echo " Cross-Run Reliability Report"
echo " Run A: $SNAPSHOT_A"
echo " Run B: $SNAPSHOT_B"
echo "========================================"
echo ""

# ═══ Dimension 1: Structural — output file count ═══
count_a=$(find "$SNAPSHOT_A" -type f -name "*.md" -o -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
count_b=$(find "$SNAPSHOT_B" -type f -name "*.md" -o -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
if [ "$count_a" -gt 0 ] && [ "$count_b" -gt 0 ]; then
  delta=$((count_b - count_a))
  pct=$(( delta * 100 / (count_a > 0 ? count_a : 1) ))
  abs_pct=${pct#-}
  if [ "$abs_pct" -le 20 ]; then
    green "  ✅ Structural: ${count_a} → ${count_b} files (Δ${pct}% ≤ 20%)"
    ((PASS++))
  else
    yellow "  ⚠️  Structural: ${count_a} → ${count_b} files (Δ${pct}% > 20%)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Structural: insufficient data (A:$count_a B:$count_b)"
  ((WARN++))
fi

# ═══ Dimension 2: Confidence stability ═══
if [ -f "$STATE_A" ] && [ -f "$STATE_B" ]; then
  conf_a=$(grep -o '"confidence": [0-9]*' "$STATE_A" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
  conf_b=$(grep -o '"confidence": [0-9]*' "$STATE_B" 2>/dev/null | grep -o '[0-9]*' | head -1 || echo "0")
  delta=$((conf_a - conf_b))
  abs_delta=${delta#-}
  if [ "$abs_delta" -le 15 ]; then
    green "  ✅ Confidence: ${conf_a} → ${conf_b} (Δ${delta} ≤ 15)"
    ((PASS++))
  else
    yellow "  ⚠️  Confidence: ${conf_a} → ${conf_b} (Δ${delta} > 15)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Confidence: state.json missing in one snapshot"
  ((WARN++))
fi

# ═══ Dimension 3: Stage completion ═══
if [ -f "$STATE_A" ] && [ -f "$STATE_B" ]; then
  completed_a=$(grep -c '"status": "completed"' "$STATE_A" 2>/dev/null || echo 0)
  completed_b=$(grep -c '"status": "completed"' "$STATE_B" 2>/dev/null || echo 0)
  if [ "$completed_a" -eq "$completed_b" ]; then
    green "  ✅ Stage: same completed count ($completed_a)"
    ((PASS++))
  else
    yellow "  ⚠️  Stage: ${completed_a} → ${completed_b} completed (mismatch)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Stage: state.json missing"
  ((WARN++))
fi

# ═══ Dimension 4: Fixture checksums (compare .md files content stability) ═══
md5_a=$(find "$SNAPSHOT_A" -name "*.md" -type f -exec md5 -q {} \; 2>/dev/null | sort | md5 2>/dev/null || echo "n/a")
md5_b=$(find "$SNAPSHOT_B" -name "*.md" -type f -exec md5 -q {} \; 2>/dev/null | sort | md5 2>/dev/null || echo "n/a")
# Count matching specific fixture files
fixture_matches=0; fixture_total=0
for fixture in "context.json" "graph.json" "PLAN.md" "ARCHITECTURE.md"; do
  fa="$SNAPSHOT_A/$fixture"; fb="$SNAPSHOT_B/$fixture"
  if [ -f "$fa" ] && [ -f "$fb" ]; then
    ((fixture_total++))
    if [ "$(md5 -q "$fa" 2>/dev/null || echo "")" = "$(md5 -q "$fb" 2>/dev/null || echo "")" ]; then
      ((fixture_matches++))
    fi
  fi
done
if [ "$fixture_total" -gt 0 ]; then
  if [ "$fixture_matches" -eq "$fixture_total" ]; then
    green "  ✅ Fixture: ${fixture_matches}/${fixture_total} checksums match (inputs stable)"
    ((PASS++))
  else
    yellow "  ⚠️  Fixture: ${fixture_matches}/${fixture_total} checksums match (inputs changed)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Fixture: no fixture files found to compare"
  ((WARN++))
fi

# ═══ Dimension 5: Output section count stability ═══
sections_a=$(find "$SNAPSHOT_A" -name "*.md" -type f -exec grep -c "^## " {} \; 2>/dev/null | awk '{s+=$1}END{print s+0}')
sections_b=$(find "$SNAPSHOT_B" -name "*.md" -type f -exec grep -c "^## " {} \; 2>/dev/null | awk '{s+=$1}END{print s+0}')
if [ "$sections_a" -gt 0 ] && [ "$sections_b" -gt 0 ]; then
  delta=$((sections_b - sections_a))
  abs_delta=${delta#-}
  if [ "$abs_delta" -le 1 ]; then
    green "  ✅ Output sections: ${sections_a} → ${sections_b} (Δ${delta} ≤ 1)"
    ((PASS++))
  else
    yellow "  ⚠️  Output sections: ${sections_a} → ${sections_b} (Δ${delta} > 1)"
    ((WARN++))
  fi
else
  yellow "  ⚠️  Output sections: insufficient data"
  ((WARN++))
fi

echo ""
echo "========================================"
echo " Verdict"
echo "========================================"
echo " Passed:  $PASS/5"
echo " Warning: $WARN/5"
echo " Failed:  $FAIL/5"
echo ""

if [ "$FAIL" -gt 0 ]; then
  red "❌ RELIABILITY CHECK FAILED"
  exit 2
elif [ "$WARN" -gt 2 ]; then
  yellow "⚠️  RELIABILITY LOW — ${WARN}/5 warnings, investigate"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  yellow "⚠️  RELIABILITY ADEQUATE — ${WARN}/5 minor warnings"
  exit 1
else
  green "✅ RELIABILITY HIGH — all dimensions within threshold"
  exit 0
fi
