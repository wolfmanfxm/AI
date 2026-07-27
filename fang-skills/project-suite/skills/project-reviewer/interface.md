# Interface: project-reviewer

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Review** — `reports/REVIEW-<topic>.md`

## Consumes
- 🔴 **Code**（变更 diff / 文件列表，缺失则 BLOCKED）
- 🟡 **KnowledgeBase**（`.project-knowledge/patterns/`，缺失则 DEGRADED）
- 🟢 **Plan**（`PLAN.md`，用于判断是否超出规划范围）

## Guarantees
- 五轴审查：正确性 / 安全性 / 可读性 / 架构 / 性能
- 每个发现含 `file:line` + 修复建议
- 分级：🔴BLOCKER / 🟠HIGH / 🟡MEDIUM / 🟢LOW / 🔵PRAISE
- 至少 1 个 PRAISE

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 变更文件不可读 | BLOCKED | 拒绝执行 |
| 变更文件 > 20 | DEGRADED | 只审查核心文件，列出跳过的 |
| 不熟悉的语言/框架 | DEGRADED | 标注 `[超出审查范围]`，仅通用检查 |
| 上下文不足以判断意图 | DEGRADED | 标注 `[需确认]`，不强制推断 |
