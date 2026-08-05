#!/bin/bash
# Knowledge Decay Checker v1.0
# 扫描 knowledge-graph.yaml 中的 decay 字段，输出衰减报告。
# Usage: bash shared/scripts/check-decay.sh [knowledge-graph.yaml]

set -euo pipefail
GRAPH="${1:-.project-knowledge/knowledge-graph.yaml}"
REPORT="${GRAPH%.yaml}-decay-report.md"
TODAY=$(date +%s)

echo "# Knowledge Decay Report" > "$REPORT"
echo "> $(date -u +%Y-%m-%d)" >> "$REPORT"
echo "" >> "$REPORT"

stale=0; decay=0; deprecated=0

if [ -f "$GRAPH" ]; then
  while IFS= read -r line; do
    id=$(echo "$line" | grep -o '"id": "[^"]*"' | sed 's/.*"\(.*\)".*/\1/' || echo "?")
    stability=$(echo "$line" | grep -o '"stability": [0-9.]*' | grep -o '[0-9.]*' || echo "1.0")
    last_verified=$(echo "$line" | grep -o '"last_verified": "[^"]*"' | sed 's/.*"\(.*\)".*/\1/' || echo "")

    if [ -n "$last_verified" ]; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        verified_epoch=$(date -j -f "%Y-%m-%d" "$last_verified" +%s 2>/dev/null || echo 0)
      else
        verified_epoch=$(date -d "$last_verified" +%s 2>/dev/null || echo 0)
      fi
      days=$(( (TODAY - verified_epoch) / 86400 ))

      if [ "$days" -gt 365 ]; then
        echo "- ❌ \`$id\` — 未验证 ${days}天, stability=$stability → DEPRECATED" >> "$REPORT"
        ((deprecated++))
      elif [ "$days" -gt 180 ]; then
        echo "- ⚠️ \`$id\` — 未验证 ${days}天, stability=$stability → STALE" >> "$REPORT"
        ((stale++))
      fi

      # Check stability threshold
      if [ "$(echo "$stability < 0.4" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
        echo "- 🔴 \`$id\` — stability=$stability → DECAYING" >> "$REPORT"
        ((decay++))
      fi
    fi
  done < <(grep -E '"id"|"stability"|"last_verified"' "$GRAPH")
fi

echo "" >> "$REPORT"
echo "| Status | Count |" >> "$REPORT"
echo "|--------|-------|" >> "$REPORT"
echo "| ✅ Stable | — |" >> "$REPORT"
echo "| ⚠️ Stale (>180d) | $stale |" >> "$REPORT"
echo "| 🔴 Decaying (stability<0.4) | $decay |" >> "$REPORT"
echo "| ❌ Deprecated (>365d) | $deprecated |" >> "$REPORT"

echo "Report: $REPORT"
[ "$deprecated" -gt 0 ] && exit 1 || exit 0
