#!/bin/bash
# Round19 suite arm runner: fresh headless Claude Code session with project-* skills
# (launched from the workspace that has .claude/skills/project-* symlinked).
# Usage: run-one.sh <arm> <rep>
# Permissions: explicit allowlist only (no blanket bypass).
set -u
ARM="$1"; REP="$2"
BASE=/Users/fangxiangming/.cache/ps-eval/round19/results
PROMPT_FILE="$BASE/prompts/$ARM.txt"
[ -f "$PROMPT_FILE" ] || { echo "no prompt: $PROMPT_FILE" >&2; exit 2; }
cd /tmp/ps-eval-suite-cwd || exit 1
claude -p "$(cat "$PROMPT_FILE")" \
  --output-format json \
  --allowedTools Skill Read Grep Glob Bash Write Edit MultiEdit TodoWrite Agent Task \
  --add-dir /Users/fangxiangming/.cache/ps-eval/round19 \
  --add-dir /tmp/ps-eval-run19-tester \
  > "$BASE/out/$ARM-r$REP.json" 2> "$BASE/logs/$ARM-r$REP.err"
rc=$?
echo "exit=$rc arm=$ARM rep=$REP"
