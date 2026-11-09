#!/bin/bash
# Timeline Append v2.0.0 (wrapper)
#
# 向 .project-knowledge/runtime/metrics/timeline.jsonl 追加一条 run 记录。
# 校验与追加逻辑在 timeline-append.mjs；本包装只负责解析参数与给出统一报错。
#
# Usage:
#   bash shared/scripts/timeline-append.sh <project-root> -          # JSON 从 stdin
#   bash shared/scripts/timeline-append.sh <project-root> record.json
#
# Exit: 0 = 已追加；2 = 记录非法（一行都不写）；3 = 用法 / IO 错误
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "usage: bash timeline-append.sh <project-root> [-|record.json]" >&2
  exit 3
fi

exec node "$SCRIPT_DIR/timeline-append.mjs" "$@"
