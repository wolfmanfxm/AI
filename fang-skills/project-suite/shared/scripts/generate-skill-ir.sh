#!/bin/bash
# Skill IR Generator v2.0
# 从 skill.yaml + SKILL.md 蒸馏出机器可读的 10 字段 IR。
# 只提取机器真正需要的字段：id / version / mode / description / produces / consumes / depends_on / stages / last_reviewed / boundary

set -euo pipefail
SUITE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

gen() {
  local dir="$1" name=$(basename "$dir")
  local y="$dir/skill.yaml" m="$dir/SKILL.md"
  [ ! -f "$y" ] && return

  local id version mode produces consumes depends_on stages last_reviewed boundary

  # From skill.yaml — simple grep for flat fields
  id=$(grep "^id:" "$y" | sed 's/^id: *//')
  version=$(grep "^version:" "$y" | sed 's/^version: *"//;s/"//' | tr -d ' ')
  mode=$(grep "^mode:" "$y" | sed 's/^mode: *//')
  produces=$(grep "^produces:" "$y" | sed 's/^produces: *//' | tr -d '[] ')
  consumes=$(grep "^consumes:" "$y" | sed 's/^consumes: *//' | tr -d '[] ')
  depends_on=$(grep "^depends_on:" "$y" | sed 's/^depends_on: *//' | tr -d '[] ')
  boundary=$(grep "^boundary:" "$y" | sed 's/^boundary: *//')
  last_reviewed=$(grep "last_reviewed:" "$y" | grep -o '"[^"]*"' | tr -d '"')
  stages=$(grep "stages:" "$y" | grep -o '\[.*\]' | tr -d '[]' | sed 's/, */, /g' | sed 's/^ *//;s/ *$//')

  # From SKILL.md — YAML multi-line description
  local desc="" in_desc=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^description:"; then
      in_desc=1
      local t=$(echo "$line" | sed 's/^description: >[ ]*//' | sed 's/^description: *//')
      [ -n "$t" ] && desc="$t"
      continue
    fi
    [ "$in_desc" -eq 0 ] && continue
    echo "$line" | grep -qE "^[a-z]+:|^---" && break
    local t=$(echo "$line" | sed 's/^  *//')
    [ -n "$t" ] && desc="$desc $t"
  done < <(head -15 "$m")
  desc=$(echo "$desc" | sed 's/^ *//;s/ *$//')

  # Extract verification checks count from verifier.md
  local verify_checks=0
  [ -f "$dir/prompts/verifier.md" ] && verify_checks=$(grep -c "| V" "$dir/prompts/verifier.md" 2>/dev/null || echo 0)

  # Extract exit conditions from execution.md
  local exit_count=0
  [ -f "$dir/prompts/execution.md" ] && exit_count=$(grep -c "^- " "$dir/prompts/execution.md" 2>/dev/null | head -1 || echo 0)

  # Extract failure conditions from skill.yaml interface block
  local failure_modes=$(grep -c "condition:" "$y" 2>/dev/null || echo 0)

  # Produce clean IR
  cat > "$dir/skill-ir.yaml" << EOF
# Skill IR: $id — machine-readable, regenerated on skill.yaml change
id: $id
version: "$version"
mode: $mode
description: "$desc"
boundary: "$boundary"
produces: [${produces}]
consumes: [${consumes}]
depends_on: [${depends_on}]
stages: [${stages}]
verification: { checks: ${verify_checks}, source: prompts/verifier.md }
evidence: { format: knowledge-object.schema.json, source: knowledge-graph.yaml }
exit_criteria: { conditions: ${exit_count}, source: prompts/execution.md }
failure_conditions: { modes: ${failure_modes}, levels: "WARNING→retry, DEGRADED→continue, BLOCKED→ask, FATAL→stop" }
last_reviewed: "${last_reviewed}"
EOF
  echo "  ✅ $name"
}

TARGET="${1:-all}"
echo "Skill IR Generator v2.0"
if [ "$TARGET" = "all" ]; then
  for d in "$SKILLS_DIR"/*/; do gen "$d"; done
else
  gen "$SKILLS_DIR/project-$TARGET" 2>/dev/null || gen "$SKILLS_DIR/$TARGET"
fi
echo "Done."
