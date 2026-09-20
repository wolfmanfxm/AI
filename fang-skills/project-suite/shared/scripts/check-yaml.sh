#!/bin/bash
# YAML Parse Gate v1.0
#
# 校验 Suite 内所有 .yaml 能被**标准 YAML parser** 解析。
#
# 为什么需要（2026-09-17 补）：既有 checker 全是文本/regex 校验，全绿也不代表 YAML 真能被解析。
# 实测当时有 3 个文件不可解析（project-documenter/skill.yaml 的 `recovery: 标记[CONFLICT]`、
# 一份已删除的 Context Engine 规格里的箭头 DSL，以及前者向 skills.generated.yaml 的传播）——门禁全绿却全是坏的。
# （2026-09-20 注：那份箭头 DSL 规格的可执行版本已随清场删除，.md 仅作设计史归档在 docs/archive/，
#   见 docs/roadmap.md G1.1(c)——但**本门禁仍覆盖 docs/archive/ 的 .yaml**，故该注记保留其历史价值。）
#
# 解析器优先级（保持零 Node 依赖）：
#   1. ruby -ryaml      macOS 自带
#   2. python3 + PyYAML
#   两者都没有 → **跳过并显式告警**（不静默通过，也不误判为失败）
#
# Usage: bash shared/scripts/check-yaml.sh
# Exit:  0 = 全部可解析（或宿主无解析器而跳过）；1 = 有文件不可解析

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUITE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

red()    { echo -e "\033[31m$1\033[0m"; }
green()  { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 用 parse_file 而非 load_file：只做语法判定，不实例化对象，也不受 safe_load/alias 限制影响
if command -v ruby >/dev/null 2>&1 && ruby -ryaml -e 'require "psych"' >/dev/null 2>&1; then
  PARSER=ruby
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
  PARSER=python3
else
  PARSER=none
fi

echo "========================================"
echo " YAML Parse Check（标准 parser 可解析）"
echo "========================================"
echo ""

if [ "$PARSER" = "none" ]; then
  yellow "⚠️ 宿主无 YAML 解析器（ruby -ryaml 或 python3+PyYAML），本层跳过。"
  yellow "   注意：这是**跳过**，不是通过——门禁未生效。"
  exit 0
fi

echo "解析器: $PARSER"
echo ""

parse_one() {
  case "$PARSER" in
    ruby)    ruby -E UTF-8 -ryaml -e 'Psych.parse_file(ARGV[0])' "$1" 2>&1 ;;
    python3) python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1],encoding="utf-8"))' "$1" 2>&1 ;;
  esac
}

PASS=0
FAIL=0

while IFS= read -r f; do
  rel="${f#"$SUITE_ROOT"/}"
  if err="$(parse_one "$f")"; then
    PASS=$((PASS + 1))
  else
    red "  ❌ $rel"
    printf '%s\n' "$err" | grep -v '^\s*from ' | head -2 | sed 's/^/        /'
    FAIL=$((FAIL + 1))
  fi
done < <(find "$SUITE_ROOT" -name '*.yaml' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)

echo ""
echo "========================================"
echo " Summary: Pass=$PASS  Fail=$FAIL"
echo "========================================"
if [ "$FAIL" -gt 0 ]; then
  red "❌ YAML PARSE CHECK FAILED — $FAIL 个文件无法被标准 parser 解析"
  exit 1
fi
green "✅ YAML PARSE CHECK PASSED — $PASS 个 .yaml 全部可解析"
exit 0
