#!/bin/bash
# Knowledge Query Tool v1.0
# 从 knowledge-graph.yaml 中结构化查询 Knowledge Object。
# 零依赖：纯 bash + grep，无需 jq/yq。
#
# Usage:
#   bash knowledge-query.sh --type pattern --tags form
#   bash knowledge-query.sh --type convention --confidence 0.8
#   bash knowledge-query.sh --related-to pattern.repository
#   bash knowledge-query.sh --scope project --limit 10

set -euo pipefail
GRAPH="${KNOWLEDGE_GRAPH:-.project-knowledge/knowledge-graph.yaml}"
TYPE=""; SCOPE=""; TAGS=""; MIN_CONF=""; RELATED=""; LIMIT="20"

while [ $# -gt 0 ]; do
  case "$1" in
    --type)       TYPE="$2"; shift 2 ;;
    --scope)      SCOPE="$2"; shift 2 ;;
    --tags)       TAGS="$2"; shift 2 ;;
    --confidence) MIN_CONF="$2"; shift 2 ;;
    --related-to) RELATED="$2"; shift 2 ;;
    --limit)      LIMIT="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if [ ! -f "$GRAPH" ]; then
  echo "No knowledge-graph.yaml found. Run project-analyzer first."
  exit 1
fi

echo "---"
echo "query:"
[ -n "$TYPE" ]     && echo "  type: $TYPE"
[ -n "$SCOPE" ]    && echo "  scope: $SCOPE"
[ -n "$TAGS" ]     && echo "  tags: [$TAGS]"
[ -n "$MIN_CONF" ] && echo "  confidence>=: $MIN_CONF"
[ -n "$RELATED" ]  && echo "  related_to: $RELATED"
echo "  limit: $LIMIT"
echo "results:"

count=0
in_node=0; node=""
while IFS= read -r line; do
  # Start of a node
  if echo "$line" | grep -q "^\s*- id:"; then
    [ -n "$node" ] && { echo "$node"; ((count++)); }
    node="$line"; in_node=1
    [ "$count" -ge "$LIMIT" ] && break
    continue
  fi
  [ "$in_node" -eq 0 ] && continue

  # Accumulate node lines
  node="$node"$'\n'"$line"

  # Filter: type
  if [ -n "$TYPE" ] && [ "$TYPE" != "all" ]; then
    if echo "$node" | grep -q "type: $TYPE"; then :; else node=""; in_node=0; continue; fi
  fi
  # Filter: scope
  if [ -n "$SCOPE" ]; then
    if echo "$node" | grep -q "scope: $SCOPE"; then :; else node=""; in_node=0; continue; fi
  fi
  # Filter: tags (AND — must contain all)
  if [ -n "$TAGS" ]; then
    all_match=true
    for tag in $(echo "$TAGS" | tr ',' ' '); do
      if ! echo "$node" | grep -q "$tag"; then all_match=false; break; fi
    done
    [ "$all_match" = false ] && { node=""; in_node=0; continue; }
  fi
  # Filter: confidence
  if [ -n "$MIN_CONF" ]; then
    conf=$(echo "$node" | grep "confidence:" | grep -o '[0-9.]*' | head -1 || echo "0")
    if [ "$(echo "$conf < $MIN_CONF" | bc -l 2>/dev/null || echo 1)" = "1" ]; then
      node=""; in_node=0; continue
    fi
  fi
  # Filter: related_to
  if [ -n "$RELATED" ]; then
    if ! echo "$node" | grep -q "$RELATED"; then node=""; in_node=0; continue; fi
  fi
done < "$GRAPH"
[ -n "$node" ] && { echo "$node"; ((count++)); }

echo ""
echo "  count: $count"
