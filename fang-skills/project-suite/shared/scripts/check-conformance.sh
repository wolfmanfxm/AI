#!/bin/bash
# Conformance Checker v1.0 — SUITE_SPEC G1-G17 automated verification
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

  # G1: SKILL.md exists and ≤130 lines
  if [ -f "$skill_dir/SKILL.md" ]; then
    lines=$(wc -l < "$skill_dir/SKILL.md")
    if [ "$lines" -le 130 ]; then
      green "  G1 PASS: SKILL.md ${lines}行 ≤130"
    else
      yellow "  G1 WARN: SKILL.md ${lines}行 >130"
      WARNINGS=$((WARNINGS+1))
    fi
  else
    red "  G1 FAIL: SKILL.md missing"
    ERRORS=$((ERRORS+1))
  fi

  # G2: skill.yaml exists and has required fields
  if [ -f "$skill_dir/skill.yaml" ]; then
    required_fields=("id:" "version:" "mode:" "owner:" "produces:" "consumes:" "boundary:")
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
      WARNINGS=$((WARNINGS+1))
    fi
  else
    red "  G2 FAIL: skill.yaml missing"
    ERRORS=$((ERRORS+1))
  fi

  # G3: boundary.md 反例表格行数（| N | 开头）+ SKILL.md 的禁止行 ≥3
  anti_count=0
  if [ -f "$skill_dir/references/boundary.md" ]; then
    anti_count=$(grep -cE "^\| [0-9]+ \|" "$skill_dir/references/boundary.md" 2>/dev/null || true)
  fi
  skill_anti=0
  if [ -f "$skill_dir/SKILL.md" ]; then
    skill_anti=$(grep -c "禁止:" "$skill_dir/SKILL.md" 2>/dev/null || true)
  fi
  total_anti=$((anti_count + skill_anti))
  if [ "$total_anti" -ge 3 ]; then
    green "  G3 PASS: ${total_anti} anti-patterns (boundary:${anti_count} + SKILL:${skill_anti}) ≥3"
  else
    # Check for waiver
    if grep -q "waivers:" "$skill_dir/skill.yaml" 2>/dev/null && grep -q "G3" "$skill_dir/skill.yaml" 2>/dev/null; then
      # Extract expires date from inline waiver: { gate: G3, reason: "...", expires: "YYYY-MM-DD", ... }
      expires=$(grep "gate: G3" "$skill_dir/skill.yaml" 2>/dev/null | grep -o 'expires: "[^"]*"' | grep -o '"[^"]*"' | tr -d '"' || echo "")
      if [ -n "$expires" ]; then
        expires_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null || true)
        now_epoch=$(date +%s)
        if [ "$now_epoch" -lt "$expires_epoch" ]; then
          green "  G3 WAIVED: only ${total_anti} anti-patterns, waiver active until $expires"
        else
          yellow "  G3 WAIVER EXPIRED: expired $expires, only ${total_anti} anti-patterns"
          WARNINGS=$((WARNINGS+1))
        fi
      else
        green "  G3 WAIVED: ${total_anti} anti-patterns, waiver active (no expiry)"
      fi
    else
      yellow "  G3 WARN: only ${total_anti} anti-patterns, need ≥3"
      WARNINGS=$((WARNINGS+1))
    fi
  fi

  # G4: At least 1 CHECKPOINT
  cps=0
  if [ -f "$skill_dir/SKILL.md" ]; then
    cps=$(grep -c "CHECKPOINT" "$skill_dir/SKILL.md" || true)
  fi
  # Also count CHECKPOINT in prompts/
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "CHECKPOINT" "$prompt" || true)
      cps=$((cps + pc))
    fi
  done
  if [ "$cps" -ge 1 ]; then
    green "  G4 PASS: ${cps} CHECKPOINT(s) found"
  else
    yellow "  G4 WARN: no CHECKPOINT found"
    WARNINGS=$((WARNINGS+1))
  fi

  # G5: 职责边界表 with ✅/❌
  if grep -q "✅" "$skill_dir/references/boundary.md"; then
    green "  G5 PASS: boundary table found"
  else
    yellow "  G5 WARN: no ✅/❌ boundary table in boundary.md"
    WARNINGS=$((WARNINGS+1))
  fi

  # G6: frontmatter has description + trigger words（多行 YAML，取 frontmatter 完整内容）
  desc=$(awk '/^---/{f++} f==1' "$skill_dir/SKILL.md" 2>/dev/null | sed -n '/description:/,$p' | tr '\n' ' ')
  if echo "$desc" | grep -q "触发词\|trigger" && echo "$desc" | grep -q "产出"; then
    green "  G6 PASS: description has trigger+output"
  else
    yellow "  G6 WARN: description missing trigger or output keywords"
    WARNINGS=$((WARNINGS+1))
  fi

  # G7: registered in skills.generated.yaml（per-skill 唯一派生源）
  if grep -qE "^  ${skill}:" "$SUITE_ROOT/runtime/registry/skills.generated.yaml" 2>/dev/null; then
    green "  G7 PASS: registered in skills.generated.yaml"
  else
    yellow "  G7 WARN: not found in skills.generated.yaml"
    WARNINGS=$((WARNINGS+1))
  fi

  # G8: 完成后 next-step hint
  if grep -q "完成后" "$skill_dir/SKILL.md"; then
    green "  G8 PASS: next-step hint found"
  else
    yellow "  G8 WARN: no next-step hint"
    WARNINGS=$((WARNINGS+1))
  fi

  # G9: 失败处理在 boundary.md
  if grep -q "失败兜底" "$skill_dir/references/boundary.md" 2>/dev/null; then
    green "  G9 PASS: failure handling in boundary.md"
  else
    yellow "  G9 WARN: failure handling missing"
    WARNINGS=$((WARNINGS+1))
  fi

  # G10: 无 runtime-specific 措辞
  if grep -qE "在 Claude Code|Claude Code skill|Cursor only" "$skill_dir/SKILL.md" 2>/dev/null; then
    yellow "  G10 WARN: runtime-specific wording found in SKILL.md"
    WARNINGS=$((WARNINGS+1))
  else
    green "  G10 PASS: runtime-neutral"
  fi

  # G11: prompts/ 至少 1 个文件
  prompt_count=$(find "$skill_dir/prompts" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$prompt_count" -ge 1 ]; then
    green "  G11 PASS: prompts/ has ${prompt_count} file(s)"
  else
    yellow "  G11 WARN: prompts/ empty"
    WARNINGS=$((WARNINGS+1))
  fi

  # G12: references/ 至少 2 个文件
  ref_count=$(find "$skill_dir/references" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ref_count" -ge 2 ]; then
    green "  G12 PASS: references/ has ${ref_count} file(s)"
  else
    yellow "  G12 WARN: references/ has <2 files"
    WARNINGS=$((WARNINGS+1))
  fi

  # G13: Stage prompts exist for each declared stage
  stages=$(grep "stages:" "$skill_dir/skill.yaml" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ' | sed 's/^ *//')
  stage_count=0
  missing_stages=()
  for stage in $stages; do
    if [ -f "$skill_dir/prompts/$stage.md" ]; then
      stage_count=$((stage_count+1))
    else
      missing_stages+=("$stage")
    fi
  done
  if [ ${#missing_stages[@]} -eq 0 ]; then
    green "  G13 PASS: ${stage_count}/${stage_count} stage prompts exist"
  else
    yellow "  G13 WARN: missing prompts: ${missing_stages[*]}"
    WARNINGS=$((WARNINGS+1))
  fi

  # G14: @template declarations in stage prompts
  template_count=0
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "@template:" "$prompt" || true)
      template_count=$((template_count + pc))
    fi
  done
  if [ "$template_count" -ge "$stage_count" ]; then
    green "  G14 PASS: ${template_count} @template declarations in prompts"
  else
    yellow "  G14 WARN: only ${template_count}/${stage_count} stages have @template"
    WARNINGS=$((WARNINGS+1))
  fi

  # G15: skill-policy.yaml 含 rollback
  if grep -q "rollback:" "$SUITE_ROOT/runtime/config/skill-policy.yaml"; then
    green "  G15 PASS: skill-policy.yaml has rollback"
  else
    yellow "  G15 WARN: skill-policy.yaml missing rollback"
    WARNINGS=$((WARNINGS+1))
  fi

  # G16: Skill Atlas 条目完整
  if grep -q "$skill" "$SUITE_ROOT/docs/skill-atlas.md" 2>/dev/null; then
    green "  G16 PASS: in skill-atlas.md"
  else
    yellow "  G16 WARN: not in skill-atlas.md"
    WARNINGS=$((WARNINGS+1))
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
        review_epoch=$(date -j -f "%Y-%m-%d" "$last_reviewed" +%s 2>/dev/null || true)
      else
        review_epoch=$(date -d "$last_reviewed" +%s 2>/dev/null || true)
      fi
      days_since=$(( (current_date - review_epoch) / 86400 ))
      if [ "$days_since" -gt "$cadence_days" ]; then
        yellow "  G17 WARN: $skill last reviewed ${days_since}d ago (cadence: ${cadence_days}d)"
        WARNINGS=$((WARNINGS+1))
      else
        green "  G17 PASS: $skill reviewed ${days_since}d ago ≤ ${cadence_days}d"
      fi
    else
      yellow "  G17 WARN: $skill missing last_reviewed field"
      WARNINGS=$((WARNINGS+1))
    fi
  fi
done

# ═══ G18: Scheduler Contract (cross-skill check) ═══
echo "--- scheduler-contract ---"
scheduler_file="$SUITE_ROOT/runtime/config/scheduler.yaml"
if [ -f "$scheduler_file" ]; then
  # G18a: 每个 skill 有 scheduler entry
  missing_sched=()
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill=$(basename "$skill_dir")
    if ! grep -qE "^  ${skill}:" "$scheduler_file"; then
      missing_sched+=("$skill")
    fi
  done
  if [ ${#missing_sched[@]} -eq 0 ]; then
    green "  G18a PASS: all skills have scheduler entry"
  else
    yellow "  G18a WARN: missing scheduler entry: ${missing_sched[*]}"
    WARNINGS=$((WARNINGS+1))
  fi

  # G18b: priority 唯一
  priority_dupes=$(grep -oE "priority: [0-9]+" "$scheduler_file" | grep -oE "[0-9]+" | sort | uniq -d)
  if [ -z "$priority_dupes" ]; then
    green "  G18b PASS: priority values unique"
  else
    yellow "  G18b WARN: duplicate priority: $priority_dupes"
    WARNINGS=$((WARNINGS+1))
  fi

  # G18c: decision_order 唯一
  order_dupes=$(grep -oE "decision_order: [0-9]+" "$scheduler_file" | grep -oE "[0-9]+" | sort | uniq -d)
  if [ -z "$order_dupes" ]; then
    green "  G18c PASS: decision_order values unique"
  else
    yellow "  G18c WARN: duplicate decision_order: $order_dupes"
    WARNINGS=$((WARNINGS+1))
  fi
else
  red "  G18 FAIL: scheduler.yaml missing"
  ERRORS=$((ERRORS+1))
fi

echo ""

# ── 声明链一致性检查（skill.yaml → skill-ir → registry → compatibility → benchmarks）──
# 任何一层不一致 → 报错。实际行为层（L5）排除，需 benchmark 手动验证。
echo "========================================"
echo " 声明链一致性（check-consistency.sh）"
echo "========================================"
if [ -f "$SUITE_ROOT/shared/scripts/check-consistency.sh" ]; then
  if bash "$SUITE_ROOT/shared/scripts/check-consistency.sh"; then
    green "  ✅ 声明链一致性通过"
  else
    red "  ❌ 声明链不一致（skill.yaml/skill-ir/registry/compatibility/benchmarks 某层漂移）"
    ERRORS=$((ERRORS+1))
  fi
else
  yellow "  ⚠️  check-consistency.sh 缺失，跳过一致性检查"
fi

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
