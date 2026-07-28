# Interface: project-reviewer

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Review** — `reports/REVIEW-<topic>.md`

## Consumes
- 🔴 **Code**（变更 diff / 文件列表，缺失则 BLOCKED）
- 🔴 **Plan Acceptance Criteria** — `PLAN.md > # Acceptance Criteria`（**必读**：逐条对照验收标准审查）
- 🔴 **Plan Risk Assessment** — `PLAN.md > # Risk Assessment`（**必读**：按风险级别调整审查强度）
- 🔴 **Plan Scope** — `PLAN.md > # Scope`（**必读**：检查是否超出边界/范围蔓延）
- 🟡 **KnowledgeBase**（`.project-knowledge/patterns/`，缺失则 DEGRADED）
- 🟡 **Plan Task Breakdown** — `PLAN.md > # Task Breakdown`（判断是否超出规划范围）
- 🟡 **Architecture**（`ARCHITECTURE.md`，对照决策检查实现一致性）

## Guarantees
- 五轴审查：正确性 / 安全性 / 可读性 / 架构 / 性能
- 每个发现含 `file:line` + 修复建议
- 分级：🔴BLOCKER / 🟠HIGH / 🟡MEDIUM / 🟢LOW / 🔵PRAISE
- 至少 1 个 PRAISE
- **对照 Acceptance Criteria 逐条验证** — 标注每条通过/失败
- **对照 Scope 检查范围蔓延** — 发现超出 `Out` 边界的内容标注 BLOCKER
- **Risk-Driven 审查强度**：HIGH 风险任务 → Full audit / MEDIUM → Spot check / LOW → Standard

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 变更文件不可读 | BLOCKED | 拒绝执行 |
| 变更文件 > 20 | DEGRADED | 只审查核心文件，列出跳过的 |
| Acceptance Criteria 不可验证 | DEGRADED | 标注 `[需确认]`，不强制推断 |
| 不熟悉的语言/框架 | DEGRADED | 标注 `[超出审查范围]`，仅通用检查 |
| 上下文不足以判断意图 | DEGRADED | 标注 `[需确认]`，不强制推断 |
