#!/bin/bash
# Structural Graph Contract Gate v1.0.0
#
# 校验 `.project-knowledge/graph.json` 是否符合 Structural Graph v3.0.0。
# 与 check-e2e-smoke.sh 共用 graph-validate.mjs，避免「两把尺子」。
#
# 旧图兼容：schemaVersion 2.0.0 是 Knowledge Objects 形状（不是结构图）。
#   默认只 warning + exit 0，提示重跑 Analyzer——不硬阻断既有项目。
#   `--strict` 时按非法处理（E2E / CI 新 fixture 用）。
#
# Usage:
#   bash shared/scripts/check-graph-contract.sh <graph.json> [--strict]
#
# Exit:
#   0 = 合法，或 legacy 2.0.0 在非 strict 模式下
#   1 = 结构契约违约
#   2 = 用法 / 文件不存在 / JSON 解析失败

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR="$SCRIPT_DIR/graph-validate.mjs"

GRAPH=""
STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *) GRAPH="$arg" ;;
  esac
done

if [ -z "$GRAPH" ]; then
  echo "usage: bash check-graph-contract.sh <graph.json> [--strict]" >&2
  exit 2
fi
if [ ! -f "$GRAPH" ]; then
  echo "❌ check-graph-contract: 找不到 $GRAPH" >&2
  exit 2
fi

VERSION="$(node -e '
  const fs = require("fs");
  try {
    const g = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    process.stdout.write(String(g.schemaVersion ?? ""));
  } catch (e) {
    process.stderr.write(e.message + "\n");
    process.exit(2);
  }
' "$GRAPH")"
PARSE_RC=$?
if [ "$PARSE_RC" -ne 0 ]; then
  echo "❌ check-graph-contract: 无法解析 $GRAPH" >&2
  exit 2
fi

if [ "$VERSION" != "3.0.0" ]; then
  if [ "$STRICT" -eq 1 ]; then
    node "$VALIDATOR" "$GRAPH" --strict
    exit $?
  fi
  echo "⚠️  check-graph-contract: legacy graph schemaVersion=${VERSION:-<missing>}（不是结构图 v3.0.0）" >&2
  echo "    → 重跑 project-analyzer 全量重建 graph.json；本次不阻断既有项目。" >&2
  exit 0
fi

node "$VALIDATOR" "$GRAPH" --strict
exit $?
