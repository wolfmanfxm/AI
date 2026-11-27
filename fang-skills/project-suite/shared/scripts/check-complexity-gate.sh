#!/bin/bash
# Complexity Gate 冒烟（macOS bash 3.2 / set -u / 不同 locale）
# 背景：macOS bash 3.2 + set -u 下实测 `is_simple�: unbound variable`——变量后紧跟全角标点在部分
# bash 构建/ locale 下会被并入变量名。此冒烟固定覆盖该形态。
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATE="$SCRIPT_DIR/complexity-gate.sh"
FAIL=0
inputs=("把按钮颜色改成蓝色" "修复权限校验绕过，只涉及 2 个文件" "从零搭建报表模块")
locales=("C" "en_US.UTF-8" "zh_CN.UTF-8")
for loc in "${locales[@]}"; do
  for req in "${inputs[@]}"; do
    out=$(LC_ALL="$loc" /bin/bash "$GATE" "$req" 2>&1) || { echo "❌ $loc / $req: exit != 0"; echo "$out" | tail -3; FAIL=1; continue; }
    echo "$out" | grep -q "复杂度:" || { echo "❌ $loc / $req: 缺复杂度"; FAIL=1; }
    echo "$out" | grep -q "风险:"   || { echo "❌ $loc / $req: 缺风险"; FAIL=1; }
  done
done
[ "$FAIL" -eq 0 ] && echo "✅ complexity-gate smoke passed" || echo "❌ complexity-gate smoke failed"
exit "$FAIL"
