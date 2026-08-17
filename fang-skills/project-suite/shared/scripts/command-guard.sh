#!/bin/bash
# Command Guard v1.1
# Runtime 级命令护栏执行器。拦截改写工作树/历史的 git 命令，并记录 guard-events.json 审计。
# 把「禁 git」从 LLM prompt 约束升级为确定性边界（prompt 约束不可靠，需要 Runtime 级硬护栏）。
# 零依赖：纯 bash。黑名单与 runtime/tool-adapters/adapter-registry.yaml 的 git.guard 保持一致。
#
# Usage:
#   bash command-guard.sh "git checkout -- ."     → BLOCK + 记录 guard-events.json
#   bash command-guard.sh "git status"            → ALLOW（只读）
#   bash command-guard.sh "npm test"              → ALLOW（非 git）
#   bash command-guard.sh "git checkout -- ." --exit   → BLOCK 且 exit 1（供 pipeline 直接拦）
#
# 环境变量:
#   GUARD_EVENTS  事件文件路径（默认 ./guard-events.json）

set -uo pipefail

CMD="${1:-}"
EXIT_ON_BLOCK=0
[ "${2:-}" = "--exit" ] && EXIT_ON_BLOCK=1
GUARD_EVENTS="${GUARD_EVENTS:-guard-events.json}"

if [ -z "$CMD" ]; then
  echo "Usage: bash command-guard.sh '<command>' [--exit]"
  exit 1
fi

# 权威黑名单（改写工作树/历史/推送）。与 adapter-registry.yaml git.guard.blocklist 同步。
BLOCKLIST=(
  "git checkout"
  "git reset"
  "git clean"
  "git restore"
  "git rm"
  "git stash"
  "git revert"
  "git commit"
  "git add"
  "git push"
  "git merge"
  "git rebase"
  "git cherry-pick"
)
# 只读命令（明确放行）
ALLOWLIST=(
  "git status"
  "git diff"
  "git log"
  "git branch"
  "git rev-parse"
  "git show"
  "git blame"
)

# 追加一条审计事件（JSONL）
record_event() {
  local verdict="$1" reason="$2"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "?")
  # 命令里的双引号/反斜杠转义，避免破坏 JSON
  local esc_cmd
  esc_cmd=$(printf '%s' "$CMD" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"ts":"%s","cmd":"%s","verdict":"%s","reason":"%s"}\n' "$ts" "$esc_cmd" "$verdict" "$reason" >> "$GUARD_EVENTS"
}

# 非 git 命令 → 直接放行
if ! printf '%s' "$CMD" | grep -qE '^(git |/usr/bin/git |git$|git\b)'; then
  echo "ALLOW  (非 git 命令): $CMD"
  exit 0
fi

# 只读 git → 放行
for a in "${ALLOWLIST[@]}"; do
  if [[ "$CMD" == "$a"* ]]; then
    echo "ALLOW  (只读 git): $CMD"
    exit 0
  fi
done

# 黑名单 → BLOCK + 记录
for b in "${BLOCKLIST[@]}"; do
  if [[ "$CMD" == "$b"* ]]; then
    echo "BLOCK  (改写工作树/历史): $CMD → 用 Edit/Write 代替，或交给用户"
    record_event "BLOCK" "blocklist:$b"
    [ "$EXIT_ON_BLOCK" = "1" ] && exit 1
    exit 0
  fi
done

# 未列明的 git 命令 → 保守拦截（default-deny 于风险域）
echo "BLOCK  (未列明的 git 命令，保守拦截): $CMD"
record_event "BLOCK" "default-deny-unlisted-git"
[ "$EXIT_ON_BLOCK" = "1" ] && exit 1
exit 0
