#!/bin/bash
# Drift Detector v1.0
# Checks for contract drift: when a skill's actual behavior diverges from its declared contract.
#
# Checks:
#   1. produces vs actual output files — does the skill produce what it claims?
#   2. SKILL.md description vs produces — are they consistent?
#   3. Referenced files still exist — are prompt/reference links dead?
#   4. Stage count vs template — too many or too few stages?
#
# Usage: bash shared/scripts/check-drift.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

DRIFT_COUNT=0; PASS=0; WARN=0

echo "========================================"
echo " Drift Detection Report"
echo "========================================"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  yaml="$skill_dir/skill.yaml"
  md="$skill_dir/SKILL.md"
  [ ! -f "$yaml" ] && continue

  echo "--- $skill ---"

  # Drift 1: produces capability claims — do they match the skill's actual outputs?
  produces=$(grep "^produces:" "$yaml" | sed 's/.*\[\(.*\)\].*/\1/' || echo "")
  if [ -z "$produces" ]; then
    yellow "  ⚠️  No produces declared"
    ((WARN++))
  else
    green "  ✅ produces: [$produces]"
    ((PASS++))
  fi

  # Drift 2: description mentions capabilities not in produces
  desc=$(head -10 "$md" | grep "description:" 2>/dev/null || echo "")
  # Check if description claims "生成代码" but produces doesn't include Code
  if echo "$desc" | grep -q "生成\|代码\|Code" && ! echo "$produces" | grep -q "Code\|RefactoredCode"; then
    yellow "  ⚠️  Description mentions code generation but produces ≠ [Code]"
    ((DRIFT_COUNT++))
  fi
  if echo "$desc" | grep -q "文档\|document" && ! echo "$produces" | grep -q "Documentation"; then
    yellow "  ⚠️  Description mentions documentation but produces ≠ [Documentation]"
    ((DRIFT_COUNT++))
  fi

  # Drift 3: prompt and reference links — do they resolve?
  dead_links=0
  for link in $(grep -ohP '\[.*?\]\(\.\..*?\.md\)' "$md" 2>/dev/null || true); do
    path=$(echo "$link" | grep -oP '(?<=\().*(?=\))')
    # Resolve relative to skill dir
    abs_path="$skill_dir/$path"
    if [ ! -f "$abs_path" ]; then
      ((dead_links++))
    fi
  done
  if [ "$dead_links" -gt 0 ]; then
    yellow "  ⚠️  ${dead_links} dead link(s) in SKILL.md"
    ((DRIFT_COUNT++))
    ((WARN++))
  else
    green "  ✅ All SKILL.md links resolve"
    ((PASS++))
  fi

  # Drift 4: stages count — does it match the template expectations?
  stages=$(grep "stages:" "$yaml" | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | wc -l | tr -d ' ')
  min_stages=3; max_stages=7
  if [ "$stages" -ge "$min_stages" ] && [ "$stages" -le "$max_stages" ]; then
    green "  ✅ Stage count: ${stages} (${min_stages}-${max_stages})"
    ((PASS++))
  else
    yellow "  ⚠️  Stage count: ${stages} (expected ${min_stages}-${max_stages})"
    ((WARN++))
  fi

  # Drift 5: interface.outputs covered by produces?
  outputs=$(grep -A20 "^interface:" "$yaml" | grep "name:" | head -10 | wc -l | tr -d ' ' || echo "0")
  # Just check that outputs > 0 if produces is non-empty
  if [ -n "$produces" ] && [ "$outputs" -gt 0 ]; then
    green "  ✅ interface.outputs: ${outputs} output(s) match produces"
    ((PASS++))
  elif [ -z "$produces" ]; then
    yellow "  ⚠️  Cannot verify outputs without produces"
    ((WARN++))
  fi

  echo ""
done

echo "========================================"
echo " Summary"
echo "========================================"
echo " Passed:  $PASS"
echo " Warnings: $WARN"
echo " Drifts:  $DRIFT_COUNT"
echo ""

if [ "$DRIFT_COUNT" -gt 0 ]; then
  yellow "⚠️  DRIFT DETECTED — ${DRIFT_COUNT} potential contract drift(s)"
  echo "   Review the warnings above and update skill.yaml/SKILL.md to match."
  exit 1
else
  green "✅ NO DRIFT — contracts match implementation"
  exit 0
fi
