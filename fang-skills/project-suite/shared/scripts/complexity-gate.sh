#!/bin/bash
# Complexity Gate v1.0
# 任务复杂度分类器（确定性启发式，等价于几百 token 的 LLM 分类，但零 token 成本）。
# 把需求文本分类为 simple/medium/complex → 路由到 Quick/Standard/Full path。
# 默认规则：不确定 → medium（宁可不省，也不误路由到过轻的路径）。
#
# Usage:
#   bash complexity-gate.sh "把按钮颜色改成蓝色"
#   bash complexity-gate.sh "给订单列表加状态筛选"
#   bash complexity-gate.sh "从零搭建报表模块"

set -uo pipefail

REQ="${1:-}"
if [ -z "$REQ" ]; then
  echo "Usage: bash complexity-gate.sh '<需求描述>'"
  exit 1
fi

# 信号关键词（按优先级：complex > trivial > medium > simple）
complex_patterns=("重构" "从零" "搭建" "迁移" "架构" "权限" "新模块" "全链路" "大屏" "国际化" "多级审批")
trivial_patterns=("加一个" "加一项" "补.*total" "改.*label" "改.*文案")   # 显式 trivial 强信号，压过 medium 的「搜索/筛选」
medium_patterns=("新增" "实现" "导出" "筛选" "搜索" "分页" "新建" "页面" "组件" "功能")
simple_patterns=("修复" "改成蓝色" "改颜色" "样式" "删除.*import" "删.*import" "文案")

LEVEL="medium"  # 默认

is_complex=0
for p in "${complex_patterns[@]}"; do
  if printf '%s' "$REQ" | grep -q "$p"; then is_complex=1; break; fi
done

is_trivial=0
for p in "${trivial_patterns[@]}"; do
  if printf '%s' "$REQ" | grep -q "$p"; then is_trivial=1; break; fi
done

is_medium=0
for p in "${medium_patterns[@]}"; do
  if printf '%s' "$REQ" | grep -q "$p"; then is_medium=1; break; fi
done

is_simple=0
for p in "${simple_patterns[@]}"; do
  if printf '%s' "$REQ" | grep -q "$p"; then is_simple=1; break; fi
done

# 优先级：complex > trivial（加一个/补/改label 强 trivial）> medium > simple
if [ "$is_complex" = "1" ]; then
  LEVEL=complex
elif [ "$is_trivial" = "1" ]; then
  LEVEL=simple
elif [ "$is_medium" = "1" ]; then
  LEVEL=medium
elif [ "$is_simple" = "1" ]; then
  LEVEL=simple
fi

case "$LEVEL" in
  simple)  ROUTE="Quick Path (generator → verify)"; DEPTH="minimal" ;;
  medium)  ROUTE="Standard Path (planner → generator → reviewer)"; DEPTH="standard" ;;
  complex) ROUTE="Full Path (analyzer → planner → architect → generator → tester → reviewer)"; DEPTH="full" ;;
esac

cat <<EOF
Complexity Gate 判定:
  复用判定: 未覆盖（Reuse Fast Path 需先查 catalog.md/graph.json，见 shared/primitives/reuse-check.md）
  复杂度: $LEVEL
  路由: $ROUTE
  深度: $DEPTH
  理由: 关键词启发式（complex=$is_complex trivial=$is_trivial medium=$is_medium simple=$is_simple，默认 medium）
EOF
