#!/bin/bash
# Knowledge Query Tool — DEPRECATED · **已归档到 docs/archive/（2026-09-18）**
#
# ⚠️ 已废弃。本工具原设计为查询 `.project-knowledge/knowledge-graph.yaml`，
#    但该文件从未被任何 Producer 产出（真实产物是 graph.json + knowledge-index.json），
#    因此这条查询路径从未闭环。
#
# 替代路径（按用途二选一）：
#   - 结构查询（组件/API/模块存在性、依赖链、影响半径）→ runtime/contracts/graph-query.md
#     （jq 直查 .project-knowledge/graph.json，7 个标准查询）
#   - 知识检索（rules/decisions/patterns/experience/playbooks 的约束与模式）
#     → knowledge-resolver.sh 读 .project-knowledge/knowledge-index.json → context-package.json
#
# 保留本文件仅为兼容旧引用，不再维护。

set -euo pipefail

cat >&2 <<'MSG'
⚠️ knowledge-query.sh 已废弃。

它原本查询 .project-knowledge/knowledge-graph.yaml，但该文件从未被产出（真实产物是
graph.json + knowledge-index.json），所以这条查询路径没有闭环。

请改用：
  - 结构查询（组件/API/模块存在性、依赖链）→ runtime/contracts/graph-query.md
    （jq 直查 .project-knowledge/graph.json，7 个标准查询）
  - 知识检索（rules/decisions/patterns/experience/playbooks）→ knowledge-resolver.sh
    （读 .project-knowledge/knowledge-index.json → context-package.json）
MSG
# 2026-09-18：与 check-decay.sh 同批归档——恒 exit 1 的存根留在 shared/scripts/，
#   会让「跑了全套脚本」的清单永远带红灯，磨掉红灯的信号价值。
exit 1
