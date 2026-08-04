#!/bin/bash
# Conformance Checker v1.0 — SUITE_SPEC G1-G12 automated verification
# Usage: bash shared/scripts/check-conformance.sh
# Exit code: 0 = all pass, 1 = warnings found, 2 = errors found

set -euo pipefail
SUITE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"
ERRORS=0
WARNINGS=0

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

echo "========================================"
echo " Conformance Checker v1.0"
echo " Target: $SKILLS_DIR"
echo "========================================"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  echo "--- $skill ---"

  # G1: SKILL.md exists and ≤120 lines
  if [ -f "$skill_dir/SKILL.md" ]; then
    lines=$(wc -l < "$skill_dir/SKILL.md")
    if [ "$lines" -le 120 ]; then
      green "  G1 PASS: SKILL.md ${lines}行 ≤120"
    else
      yellow "  G1 WARN: SKILL.md ${lines}行 >120"
      ((WARNINGS++))
    fi
  else
    red "  G1 FAIL: SKILL.md missing"
    ((ERRORS++))
  fi

  # G2: skill.yaml exists and has required fields
  if [ -f "$skill_dir/skill.yaml" ]; then
    required_fields=("id:" "version:" "mode:" "owner:" "priority:" "produces:" "consumes:" "boundary:")
    missing_fields=()
    for field in "${required_fields[@]}"; do
      if ! grep -q "$field" "$skill_dir/skill.yaml"; then
        missing_fields+=("$field")
      fi
    done
    if [ ${#missing_fields[@]} -eq 0 ]; then
      green "  G2 PASS: skill.yaml fields complete"
    else
      yellow "  G2 WARN: skill.yaml missing: ${missing_fields[*]}"
      ((WARNINGS++))
    fi
  else
    red "  G2 FAIL: skill.yaml missing"
    ((ERRORS++))
  fi

  # G3: boundary.md has ≥3 anti-patterns (in boundary.md OR SKILL.md)
  anti_count=0
  [ -f "$skill_dir/references/boundary.md" ] && anti_count=$(grep -c "❌" "$skill_dir/references/boundary.md" | tr -d '\n' || echo 0)
  skill_anti=0
  [ -f "$skill_dir/SKILL.md" ] && skill_anti=$(grep -c "❌" "$skill_dir/SKILL.md" | tr -d '\n' || echo 0)
  total_anti=$((anti_count + skill_anti))
  if [ "$total_anti" -ge 3 ]; then
    green "  G3 PASS: ${total_anti} anti-patterns (boundary:${anti_count} + SKILL:${skill_anti}) ≥3"
  else
    # Check for waiver
    if grep -q "waivers:" "$skill_dir/skill.yaml" 2>/dev/null && grep -q "G3" "$skill_dir/skill.yaml" 2>/dev/null; then
      # Extract expires date from inline waiver: { gate: G3, reason: "...", expires: "YYYY-MM-DD", ... }
      expires=$(grep "gate: G3" "$skill_dir/skill.yaml" 2>/dev/null | grep -o 'expires: "[^"]*"' | grep -o '"[^"]*"' | tr -d '"' || echo "")
      if [ -n "$expires" ]; then
        expires_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        if [ "$now_epoch" -lt "$expires_epoch" ]; then
          green "  G3 WAIVED: only ${total_anti} anti-patterns, waiver active until $expires"
        else
          yellow "  G3 WAIVER EXPIRED: expired $expires, only ${total_anti} anti-patterns"
          ((WARNINGS++))
        fi
      else
        green "  G3 WAIVED: ${total_anti} anti-patterns, waiver active (no expiry)"
      fi
    else
      yellow "  G3 WARN: only ${total_anti} anti-patterns, need ≥3"
      ((WARNINGS++))
    fi
  fi

  # G4: At least 1 CHECKPOINT
  cps=0
  if [ -f "$skill_dir/SKILL.md" ]; then
    cps=$(grep -c "CHECKPOINT" "$skill_dir/SKILL.md" || echo 0)
  fi
  # Also count CHECKPOINT in prompts/
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "CHECKPOINT" "$prompt" || echo 0)
      cps=$((cps + pc))
    fi
  done
  if [ "$cps" -ge 1 ]; then
    green "  G4 PASS: ${cps} CHECKPOINT(s) found"
  else
    yellow "  G4 WARN: no CHECKPOINT found"
    ((WARNINGS++))
  fi

  # G5: 职责边界表 with ✅/❌
  if grep -q "✅" "$skill_dir/references/boundary.md"; then
    green "  G5 PASS: boundary table found"
  else
    yellow "  G5 WARN: no ✅/❌ boundary table in boundary.md"
    ((WARNINGS++))
  fi

  # G6: frontmatter has description + trigger words
  desc=$(head -10 "$skill_dir/SKILL.md" | grep "description:" 2>/dev/null || echo "")
  if echo "$desc" | grep -q "触发词\|trigger" && echo "$desc" | grep -q "产出"; then
    green "  G6 PASS: description has trigger+output"
  else
    yellow "  G6 WARN: description missing trigger or output keywords"
    ((WARNINGS++))
  fi

  # G7: registered in capabilities.yaml
  if grep -q "$skill" "$SUITE_ROOT/runtime/registry/capabilities.yaml" 2>/dev/null; then
    green "  G7 PASS: registered in capabilities.yaml"
  else
    yellow "  G7 WARN: not found in capabilities.yaml"
    ((WARNINGS++))
  fi

  # G8: 完成后下一步 section
  if grep -q "完成后下一步" "$skill_dir/SKILL.md"; then
    green "  G8 PASS: next-step hint found"
  else
    yellow "  G8 WARN: no next-step hint"
    ((WARNINGS++))
  fi

  # G9: failure-handling.md exists
  if [ -f "$skill_dir/references/failure-handling.md" ]; then
    green "  G9 PASS: failure-handling.md exists"
  else
    yellow "  G9 WARN: failure-handling.md missing"
    ((WARNINGS++))
  fi

  # G10: Stage prompts exist for each declared stage
  stages=$(grep "stages:" "$skill_dir/skill.yaml" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ' | sed 's/^ *//')
  stage_count=0
  missing_stages=()
  for stage in $stages; do
    if [ -f "$skill_dir/prompts/$stage.md" ]; then
      ((stage_count++))
    else
      missing_stages+=("$stage")
    fi
  done
  if [ ${#missing_stages[@]} -eq 0 ]; then
    green "  G10 PASS: ${stage_count}/${stage_count} stage prompts exist"
  else
    yellow "  G10 WARN: missing prompts: ${missing_stages[*]}"
    ((WARNINGS++))
  fi

  # G11: @engine declarations in stage prompts
  engine_count=0
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "@engine:" "$prompt" || echo 0)
      engine_count=$((engine_count + pc))
    fi
  done
  if [ "$engine_count" -ge "$stage_count" ]; then
    green "  G11 PASS: ${engine_count} @engine declarations in prompts"
  else
    yellow "  G11 WARN: only ${engine_count}/${stage_count} stages have @engine"
    ((WARNINGS++))
  fi

  # G12: interface.rollback exists
  if grep -q "rollback:" "$skill_dir/skill.yaml"; then
    green "  G12 PASS: interface.rollback exists"
  else
    yellow "  G12 WARN: interface.rollback missing"
    ((WARNINGS++))
  fi

  echo ""
done

# ═══ G17: Review Cadence (cross-skill check) ═══
echo "--- review-cadence ---"
current_date=$(date +%s)
for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  yaml_file="$skill_dir/skill.yaml"
  if [ -f "$yaml_file" ]; then
    last_reviewed=$(grep "last_reviewed:" "$yaml_file" | sed 's/.*"\(.*\)".*/\1/' || echo "")
    cadence_days=$(grep "review_cadence_days:" "$yaml_file" | grep -o '[0-9]*' || echo "90")
    if [ -n "$last_reviewed" ]; then
      # Convert to epoch on macOS
      if [[ "$OSTYPE" == "darwin"* ]]; then
        review_epoch=$(date -j -f "%Y-%m-%d" "$last_reviewed" +%s 2>/dev/null || echo 0)
      else
        review_epoch=$(date -d "$last_reviewed" +%s 2>/dev/null || echo 0)
      fi
      days_since=$(( (current_date - review_epoch) / 86400 ))
      if [ "$days_since" -gt "$cadence_days" ]; then
        yellow "  G17 WARN: $skill last reviewed ${days_since}d ago (cadence: ${cadence_days}d)"
        ((WARNINGS++))
      else
        green "  G17 PASS: $skill reviewed ${days_since}d ago ≤ ${cadence_days}d"
      fi
    else
      yellow "  G17 WARN: $skill missing last_reviewed field"
      ((WARNINGS++))
    fi
  fi
done

echo ""

echo "========================================"
echo " Summary"
echo "========================================"
echo " Errors:   $ERRORS"
echo " Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  red "❌ CONFORMANCE FAILED — $ERRORS error(s) must be fixed"
  exit 2
elif [ "$WARNINGS" -gt 0 ]; then
  yellow "⚠️  CONFORMANCE WARNING — $WARNINGS warning(s), review recommended"
  exit 1
else
  green "✅ CONFORMANCE PASSED — all gates green"
  exit 0
fi
