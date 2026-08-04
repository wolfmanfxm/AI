#!/bin/bash
# Skill IR Generator v1.0
# Reads skill.yaml + SKILL.md → produces skill-ir.yaml (machine-readable intermediate representation)
#
# Usage: bash shared/scripts/generate-skill-ir.sh [skill-name]
#   skill-name: analyzer | generator | ... | "all" (default)
# Output: skills/<name>/skill-ir.yaml

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"

generate_ir() {
  local skill_dir="$1"
  local skill=$(basename "$skill_dir")
  local yaml="$skill_dir/skill.yaml"
  local md="$skill_dir/SKILL.md"
  local ir="$skill_dir/skill-ir.yaml"

  [ ! -f "$yaml" ] && return

  # Extract fields from skill.yaml
  local id=$(grep "^id:" "$yaml" | sed 's/.*: //')
  local version=$(grep "^version:" "$yaml" | sed 's/.*: "\(.*\)".*/\1/' || grep "^version:" "$yaml" | sed 's/.*: //')
  local mode=$(grep "^mode:" "$yaml" | sed 's/.*: //')
  local priority=$(grep "^priority:" "$yaml" | sed 's/.*: //')
  local produces=$(grep "^produces:" "$yaml" | sed 's/.*\[\(.*\)\].*/\1/')
  local consumes=$(grep "^consumes:" "$yaml" | sed 's/.*\[\(.*\)\].*/\1/')
  local depends_on=$(grep "^depends_on:" "$yaml" | sed 's/.*\[\(.*\)\].*/\1/')
  local boundary=$(grep "^boundary:" "$yaml" | sed 's/.*: //')
  local last_reviewed=$(grep "last_reviewed:" "$yaml" | sed 's/.*"\(.*\)".*/\1/')
  local cadence=$(grep "review_cadence_days:" "$yaml" | grep -o '[0-9]*')
  local description=$(head -10 "$md" | grep "description:" | sed 's/.*description: >//' | head -1 | sed 's/^ *//')

  # Extract from interface block
  local stages=$(grep "stages:" "$yaml" | grep -o '\[.*\]' | tr -d '[]')
  local rollback_method=$(grep "method:" "$yaml" | grep -A1 "rollback:" | grep "method:" | sed 's/.*method: //' | tr -d ' ,')
  local recovery_method=$(grep "method:" "$yaml" | grep -A1 "recovery:" | grep "method:" | sed 's/.*method: //' | tr -d ' ,')
  local min_conf=$(grep "min_confidence_for_pass:" "$yaml" | grep -o '[0-9]*')
  local review_below=$(grep "requires_review_below:" "$yaml" | grep -o '[0-9]*')
  local block_below=$(grep "blocks_downstream_below:" "$yaml" | grep -o '[0-9]*')
  local reliability=$(grep "structural_stability:" "$yaml" | sed 's/.*structural_stability: //' | tr -d ' ,')
  local conf_delta=$(grep "expected_confidence_delta:" "$yaml" | grep -o '[0-9]*')

  # Count fixtures
  local fixture_count=$(grep -c "fixture: true" "$yaml" 2>/dev/null || echo 0)
  local input_count=$(grep -c "\- { name:" "$yaml" 2>/dev/null || echo 0)
  local trigger_count_cn=$(grep -c "" "$yaml" 2>/dev/null)  # count triggers_cn items
  trigger_count_cn=$(grep "triggers_cn:" "$yaml" | grep -o '\[.*\]' | tr ',' '\n' | wc -l | tr -d ' ')

  # Count stage prompts
  local prompt_count=0
  for s in $(echo "$stages" | tr ',' ' '); do
    [ -f "$skill_dir/prompts/$s.md" ] && ((prompt_count++))
  done

  cat > "$ir" << EOF
# Skill IR: $id
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Generator: shared/scripts/generate-skill-ir.sh

id: $id
version: $version
mode: $mode
priority: $priority

description: "$description"

boundary: "$boundary"

capabilities:
  produces: [$produces]
  consumes: [$consumes]

dependencies:
  depends_on: [$depends_on]

interface:
  stages: [$stages]
  stage_prompts: $prompt_count
  inputs: $input_count
  fixtures: $fixture_count

quality:
  confidence_pass: $min_conf
  review_below: $review_below
  block_below: $block_below
  rollback: ${rollback_method:-manifest_resume}
  recovery: ${recovery_method:-manifest_resume}

reliability:
  stability: ${reliability:-medium}
  confidence_delta: ${conf_delta:-10}

governance:
  last_reviewed: "${last_reviewed:-unknown}"
  review_cadence_days: ${cadence:-90}

triggers:
  cn_count: $trigger_count_cn
EOF

  echo "  ✅ $skill → $ir"
}

echo "========================================"
echo " Skill IR Generator"
echo "========================================"

TARGET="${1:-all}"

if [ "$TARGET" = "all" ]; then
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] && generate_ir "$skill_dir"
  done
else
  generate_ir "$SKILLS_DIR/project-$TARGET"
fi

echo ""
echo "Done. Run: cat skills/*/skill-ir.yaml"
