#!/usr/bin/env bash
#
# check_compliance.sh - SUITE_SPEC G1-G12 quality gate checker
#
# Usage:
#   ./check_compliance.sh                    # Check all 9 skills
#   ./check_compliance.sh project-analyzer   # Check one skill
#   ./check_compliance.sh -h | --help        # Show help
#
# Exit code:
#   0 = all PASS (warnings are OK)
#   1 = at least one FAIL

set -euo pipefail

# ---------- Auto-detect SUITE_DIR relative to script location ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUITE_DIR="$SCRIPT_DIR"
SKILLS_DIR="$SUITE_DIR/skills"
REGISTRY="$SUITE_DIR/runtime/registry/capabilities.yaml"

# ---------- ANSI colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ---------- Counters ----------
TOTAL=0
PASSED=0
FAILED=0
WARNED=0
HAS_FAIL=0

# ---------- Help ----------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $(basename "$0") [skill-name]"
    echo ""
    echo "Checks SUITE_SPEC G1-G12 quality gates for project-suite skills."
    echo "If no skill name is given, all 9 skills are checked."
    echo ""
    echo "Gates:"
    echo "  G1   SKILL.md exists and <= 120 lines"
    echo "  G2   skill.yaml exists with required fields (id, version, mode, produces, consumes)"
    echo "  G3   references/boundary.md has >= 3 anti-pattern rows"
    echo "  G4   SKILL.md contains at least 1 CHECKPOINT marker"
    echo "  G5   boundary.md has >= 3 rows in duty table"
    echo "  G6   SKILL.md frontmatter contains description:"
    echo "  G7   skill id appears in capabilities.yaml"
    echo "  G8   SKILL.md contains next-step section"
    echo "  G9   references/failure-handling.md exists (WARN)"
    echo "  G10  SKILL.md does not contain banned phrase (WARN)"
    echo "  G11  prompts/ has >= 1 .md file"
    echo "  G12  references/ has >= 2 .md files"
    exit 0
fi

# ---------- Result helpers ----------
pass() {
    local gate="$1" msg="$2"
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    printf "  ${GREEN}PASS${RESET}  %-5s %s\n" "$gate" "$msg"
}

fail() {
    local gate="$1" msg="$2"
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    HAS_FAIL=1
    printf "  ${RED}FAIL${RESET}  %-5s %s\n" "$gate" "$msg"
}

warn() {
    local gate="$1" msg="$2"
    TOTAL=$((TOTAL + 1))
    WARNED=$((WARNED + 1))
    printf "  ${YELLOW}WARN${RESET}  %-5s %s\n" "$gate" "$msg"
}

# ---------- Check one skill ----------
check_skill() {
    local skill_name="$1"
    local skill_dir="$SKILLS_DIR/$skill_name"

    printf "\n${BOLD}${CYAN}=== %s ===${RESET}\n" "$skill_name"

    # Verify skill directory exists
    if [[ ! -d "$skill_dir" ]]; then
        fail "---" "skill directory not found: $skill_dir"
        return
    fi

    local skill_md="$skill_dir/SKILL.md"
    local skill_yaml="$skill_dir/skill.yaml"
    local boundary_md="$skill_dir/references/boundary.md"
    local failure_md="$skill_dir/references/failure-handling.md"
    local prompts_dir="$skill_dir/prompts"
    local refs_dir="$skill_dir/references"

    # ---- G1: SKILL.md exists and <= 120 lines ----
    if [[ -f "$skill_md" ]]; then
        local line_count
        line_count=$(wc -l < "$skill_md" | tr -d ' ')
        if [[ "$line_count" -le 120 ]]; then
            pass "G1" "SKILL.md exists (${line_count} lines <= 120)"
        else
            fail "G1" "SKILL.md exceeds 120 lines (${line_count} lines)"
        fi
    else
        fail "G1" "SKILL.md not found"
    fi

    # ---- G2: skill.yaml exists with required fields ----
    if [[ -f "$skill_yaml" ]]; then
        local missing_fields=""
        for field in id version mode produces consumes; do
            if ! grep -q "^${field}:" "$skill_yaml"; then
                missing_fields="${missing_fields} ${field}"
            fi
        done
        if [[ -z "$missing_fields" ]]; then
            pass "G2" "skill.yaml has all required fields"
        else
            fail "G2" "skill.yaml missing fields:${missing_fields}"
        fi
    else
        fail "G2" "skill.yaml not found"
    fi

    # ---- G3: boundary.md has >= 3 anti-pattern rows ----
    if [[ -f "$boundary_md" ]]; then
        local anti_count
        anti_count=$(grep -c "^| [0-9]" "$boundary_md" 2>/dev/null || echo "0")
        if [[ "$anti_count" -ge 3 ]]; then
            pass "G3" "boundary.md has ${anti_count} anti-pattern rows (>= 3)"
        else
            fail "G3" "boundary.md has only ${anti_count} anti-pattern rows (need >= 3)"
        fi
    else
        fail "G3" "references/boundary.md not found"
    fi

    # ---- G4: SKILL.md contains at least 1 CHECKPOINT ----
    if [[ -f "$skill_md" ]]; then
        local cp_count
        cp_count=$(grep -c "CHECKPOINT" "$skill_md" 2>/dev/null || echo "0")
        if [[ "$cp_count" -ge 1 ]]; then
            pass "G4" "SKILL.md has ${cp_count} CHECKPOINT marker(s)"
        else
            fail "G4" "SKILL.md has no CHECKPOINT marker"
        fi
    else
        fail "G4" "SKILL.md not found (cannot check CHECKPOINT)"
    fi

    # ---- G5: boundary.md duty table has >= 3 rows ----
    if [[ -f "$boundary_md" ]]; then
        # Count table data rows between "✅ 本阶段职责" header and next blank line or ## heading
        # Skip the header row and separator row, count only data rows starting with |
        local duty_count
        duty_count=$(awk '
            /✅ 本阶段职责/ { found=1; next }
            found && /^\|[-|]+\|/ { next }
            found && /^\|/ { count++ }
            found && (/^$/ || /^##/) { exit }
            END { print count+0 }
        ' "$boundary_md")
        if [[ "$duty_count" -ge 3 ]]; then
            pass "G5" "boundary.md duty table has ${duty_count} rows (>= 3)"
        else
            fail "G5" "boundary.md duty table has only ${duty_count} rows (need >= 3)"
        fi
    else
        fail "G5" "references/boundary.md not found (cannot check duty table)"
    fi

    # ---- G6: SKILL.md frontmatter contains "description:" ----
    if [[ -f "$skill_md" ]]; then
        # Check within YAML frontmatter (between first --- and second ---)
        local has_desc
        has_desc=$(awk '
            /^---$/ { fm++; next }
            fm == 1 && /^description:/ { print "yes"; exit }
            fm == 2 { exit }
        ' "$skill_md")
        if [[ "$has_desc" == "yes" ]]; then
            pass "G6" "SKILL.md frontmatter contains description:"
        else
            fail "G6" "SKILL.md frontmatter missing description:"
        fi
    else
        fail "G6" "SKILL.md not found (cannot check frontmatter)"
    fi

    # ---- G7: skill id appears in capabilities.yaml ----
    if [[ -f "$REGISTRY" ]]; then
        if grep -q "$skill_name" "$REGISTRY"; then
            pass "G7" "\"${skill_name}\" found in capabilities.yaml"
        else
            fail "G7" "\"${skill_name}\" not found in capabilities.yaml"
        fi
    else
        fail "G7" "capabilities.yaml not found at $REGISTRY"
    fi

    # ---- G8: SKILL.md contains "完成后下一步" section ----
    if [[ -f "$skill_md" ]]; then
        if grep -q "完成后下一步" "$skill_md"; then
            pass "G8" "SKILL.md contains next-step section"
        else
            fail "G8" "SKILL.md missing \"完成后下一步\" section"
        fi
    else
        fail "G8" "SKILL.md not found (cannot check next-step)"
    fi

    # ---- G9: failure-handling.md exists (WARN level) ----
    if [[ -f "$failure_md" ]]; then
        pass "G9" "references/failure-handling.md exists"
    else
        warn "G9" "references/failure-handling.md not found"
    fi

    # ---- G10: SKILL.md does not contain "在 Claude Code" (WARN level) ----
    if [[ -f "$skill_md" ]]; then
        if grep -q "在 Claude Code" "$skill_md"; then
            warn "G10" "SKILL.md contains banned phrase \"在 Claude Code\""
        else
            pass "G10" "SKILL.md clean of banned phrase"
        fi
    else
        pass "G10" "SKILL.md not found (N/A)"
    fi

    # ---- G11: prompts/ has at least 1 .md file ----
    if [[ -d "$prompts_dir" ]]; then
        local prompt_count
        prompt_count=$(find "$prompts_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$prompt_count" -ge 1 ]]; then
            pass "G11" "prompts/ has ${prompt_count} .md file(s)"
        else
            fail "G11" "prompts/ exists but has no .md files"
        fi
    else
        fail "G11" "prompts/ directory not found"
    fi

    # ---- G12: references/ has at least 2 .md files ----
    if [[ -d "$refs_dir" ]]; then
        local ref_count
        ref_count=$(find "$refs_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$ref_count" -ge 2 ]]; then
            pass "G12" "references/ has ${ref_count} .md files (>= 2)"
        else
            fail "G12" "references/ has only ${ref_count} .md file(s) (need >= 2)"
        fi
    else
        fail "G12" "references/ directory not found"
    fi
}

# ---------- Main ----------
ALL_SKILLS=(
    project-analyzer
    project-architect
    project-documenter
    project-generator
    project-planner
    project-refactorer
    project-releaser
    project-reviewer
    project-tester
)

printf "${BOLD}SUITE_SPEC Compliance Check (G1-G12)${RESET}\n"
printf "${DIM}Suite: %s${RESET}\n" "$SUITE_DIR"

if [[ $# -ge 1 && "$1" != "-h" && "$1" != "--help" ]]; then
    # Check specific skill(s) passed as arguments
    for arg in "$@"; do
        check_skill "$arg"
    done
else
    # Check all skills
    for skill in "${ALL_SKILLS[@]}"; do
        check_skill "$skill"
    done
fi

# ---------- Summary ----------
printf "\n${BOLD}────────────────────────────────────${RESET}\n"
printf "${BOLD}Summary${RESET}\n"
printf "  Total:    %d\n" "$TOTAL"
printf "  ${GREEN}Passed:   %d${RESET}\n" "$PASSED"
printf "  ${RED}Failed:   %d${RESET}\n" "$FAILED"
printf "  ${YELLOW}Warnings: %d${RESET}\n" "$WARNED"
printf "${BOLD}────────────────────────────────────${RESET}\n"

if [[ "$HAS_FAIL" -eq 1 ]]; then
    printf "${RED}${BOLD}RESULT: FAIL${RESET} — fix the above failures before shipping.\n"
    exit 1
else
    printf "${GREEN}${BOLD}RESULT: PASS${RESET} — all quality gates satisfied.\n"
    exit 0
fi
