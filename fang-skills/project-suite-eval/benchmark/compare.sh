#!/bin/bash
# Benchmark Compare v1.0
# 汇总 benchmark 结果，输出 native vs project-suite 对比表。
#
# Usage: bash benchmark/compare.sh [results-dir]
# results-dir: 默认 benchmark/results/（每个任务一个 .yaml 文件）

set -euo pipefail
RESULTS_DIR="${1:-benchmark/results}"

if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls "$RESULTS_DIR"/*.yaml 2>/dev/null)" ]; then
  echo "没有结果文件。先跑 benchmark 任务，把结果写入 $RESULTS_DIR/<task>.yaml"
  echo ""
  echo "每个任务的结果格式见 benchmark/metrics.md"
  echo "跑完一个任务，手动记录结果（或用 agent 跑后汇总）"
  exit 0
fi

echo "═══════════════════════════════════════"
echo " Benchmark 对比报告"
echo "═══════════════════════════════════════"
echo ""

# 指标列表（native vs suite 都有的）
metrics=("requirement_coverage" "context_tokens" "review_defects" "knowledge_reuse" "interview_questions" "human_interventions")

echo "| 指标 | native 平均 | suite 平均 | Δ |"
echo "|------|------------|-----------|-----|"

for metric in "${metrics[@]}"; do
  native_sum=0; native_count=0
  suite_sum=0; suite_count=0

  for f in "$RESULTS_DIR"/*.yaml; do
    n=$(grep -A20 "native:" "$f" | grep "$metric:" | grep -oE '[0-9.]+' | head -1)
    s=$(grep -A20 "project_suite:" "$f" | grep "$metric:" | grep -oE '[0-9.]+' | head -1)
    [ -n "$n" ] && { native_sum=$(echo "$native_sum + $n" | bc); native_count=$((native_count+1)); }
    [ -n "$s" ] && { suite_sum=$(echo "$suite_sum + $s" | bc); suite_count=$((suite_count+1)); }
  done

  if [ "$native_count" -gt 0 ] && [ "$suite_count" -gt 0 ]; then
    native_avg=$(echo "scale=2; $native_sum / $native_count" | bc)
    suite_avg=$(echo "scale=2; $suite_sum / $suite_count" | bc)
    delta=$(echo "scale=2; $suite_avg - $native_avg" | bc)
    echo "| $metric | $native_avg | $suite_avg | $delta |"
  fi
done

echo ""
echo "任务数: $(ls "$RESULTS_DIR"/*.yaml | wc -l | tr -d ' ')"
echo ""
echo "⚠️ 注：这是框架。真实收益数据需要跑完至少 20 个任务才能有意义。"
