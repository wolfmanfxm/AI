#!/bin/bash
# Claude Code PreToolUse Hook — Command Guard 接线（环境 adapter，非 project-suite 本体）
#
# 作用：把 project-suite 可移植的 command-guard.sh 接进 Claude Code 的 Bash dispatch。
#   可移植的规范/脚本在 project-suite/ 里；本 hook 是它在 Claude Code 上的「接线」。
#   换到别的 harness，写另一个 adapter，复用同一个 command-guard.sh。
#
# 输入（stdin）：Claude Code PreToolUse 事件 JSON
#   { "tool_name":"Bash", "tool_input":{ "command":"git checkout -- ." }, ... }
# 输出（stdout）：
#   {"decision":"block","reason":"..."}   ← 改写工作树/历史 → 阻止
#   {"decision":"allow"}                  ← 放行
#
# 依赖：python3（JSON 解析，干净）；无 python3 时降级 grep。
# 挂载：见 settings.example.json（不全局挂载，只在 benchmark 上下文启用）。

set -uo pipefail

# command-guard.sh 路径（可用环境变量覆盖）
GUARD="${COMMAND_GUARD_SCRIPT:-/Users/fangxiangming/Work/AI/fang-skills/project-suite/shared/scripts/command-guard.sh}"
# guard-events.json 落盘位置（默认 benchmark hooks 目录下）
GUARD_EVENTS="${GUARD_EVENTS:-/Users/fangxiangming/Work/AI/fang-skills/project-suite-eval/hooks/guard-events.json}"

INPUT=$(cat)

extract_json() {
  # $1 = 顶层字段, $2 = 二级字段（可空）
  if command -v python3 >/dev/null 2>&1; then
    if [ -z "${2:-}" ]; then
      printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
  print(json.load(sys.stdin).get(sys.argv[1],""))
except Exception:
  print("")' "$1" 2>/dev/null
    else
      printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
  print(json.load(sys.stdin).get(sys.argv[1],{}).get(sys.argv[2],""))
except Exception:
  print("")' "$1" "$2" 2>/dev/null
    fi
  else
    # 降级：grep 近似提取
    printf '%s' "$INPUT" | grep -o "\"$1\"[^,]*" | head -1 | sed 's/.*:\s*"\([^"]*\)".*/\1/'
  fi
}

TOOL_NAME=$(extract_json "tool_name")
CMD=$(extract_json "tool_input" "command")

# 只拦 Bash 命令；其它工具（Read/Write/Edit/MCP）放行
if [ "$TOOL_NAME" != "Bash" ] || [ -z "$CMD" ]; then
  printf '{"decision":"allow"}\n'
  exit 0
fi

# 跑 guard 一次（--exit：BLOCK 时 exit 1），同时拿输出和退出码
guard_output=$(GUARD_EVENTS="$GUARD_EVENTS" bash "$GUARD" "$CMD" --exit 2>&1)
guard_rc=$?

if [ "$guard_rc" -ne 0 ]; then
  reason=$(printf '%s' "$guard_output" | head -1)
  printf '{"decision":"block","reason":"%s"}\n' "$reason"
  exit 0
fi

printf '{"decision":"allow"}\n'
exit 0
