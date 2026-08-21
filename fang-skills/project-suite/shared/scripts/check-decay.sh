#!/bin/bash
# Knowledge Decay Checker — DEPRECATED
#
# ⚠️ 已废弃。本工具原设计为扫描 `.project-knowledge/knowledge-graph.yaml` 中的
#    decay 字段（stability/last_verified），但该文件从未被产出，因此从未闭环。
#
# 两个概念要分清（不要混淆）：
#   - knowledge-health.json（analyzer 产出）= 质量健康（broken_link/duplicate/evidence）
#   - knowledge-decay（future，见 runtime/knowledge/knowledge-decay.md）= 可信度衰减（last_verified/stability）
#
# 保留本文件仅为兼容旧引用，不再维护。

set -euo pipefail

cat >&2 <<'MSG'
⚠️ check-decay.sh 已废弃。

它原本扫描 .project-knowledge/knowledge-graph.yaml 的 decay 字段（stability/last_verified），
但该文件从未被产出——decay 目前没有可靠的 Producer 输入。

注意区分两个概念：
  - knowledge-health.json（analyzer 产出）= 质量健康（broken_link/duplicate/evidence）
  - knowledge-decay（未来）= 可信度衰减（last_verified/stability），见 runtime/knowledge/knowledge-decay.md（planned）
MSG
exit 1
