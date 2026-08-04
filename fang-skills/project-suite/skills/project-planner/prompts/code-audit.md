# Code Audit — Planner

> @engine: code-audit

## Actions

对 Scope 内的每个模块/功能标注现状：
- `[新]` — 全新功能，无现有代码
- `[有骨架]` — 有目录/文件占位但功能不完整
- `[基本完成]` — 核心功能已有，需增量修改
- `[已完成]` — 无需改动

修正估时：
- `[新]` 不修正
- `[有骨架]` 估时 -20%
- `[基本完成]` 估时 -50%
- `[已完成]` 从 Scope 移除

→ 详细方法：[references/code-audit.md](../references/code-audit.md)

## Exit

- 每个 Scope 项已标注现状
- 估时已修正
- 用户已确认标注结果

## Failure

| Condition | Action |
|-----------|--------|
| API 文档路径与代码不一致 | 标注为 `⤳ 待确认` 外部依赖 |
| 上游 PLAN.md 存在但代码已大幅变更 | 标注 `⚠️ 上游规划可能过期`，重新 diff 修正 |

## CHECKPOINT

🔴 CHECKPOINT — 展示现状标注结果 + 修正后估时
