# Interface: project-architect

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Architecture** — `decisions/ARCHITECTURE-<topic>.md`（ADR 格式）

## Consumes
- 🔴 **KnowledgeBase**（`.project-knowledge/architecture/`，缺失则 DEGRADED）
- 🟡 **Plan**（`PLAN.md`，若存在则必须读入）
- 🟡 **Context**（`context.json`，缺失则从 KnowledgeBase 提取）

## Guarantees
- 每个决策含：问题 → 候选方案对比 → 选择 → 理由
- 现状核实标记：`[已实现][部分实现][未实现]`
- 技术选型含对比矩阵（候选方案 × 评估维度）
- API 契约含：方法+路径+参数+响应+鉴权+幂等

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| KnowledgeBase 不存在 | DEGRADED | 通用模式设计，标注"⚠️ 未分析现有架构" |
| 现状核实源码不可读 | DEGRADED | 标注"⚠️ 未核实"，按未实现处理 |
| 候选方案无明确最优 | DEGRADED | 展示对比+权衡，标记待用户选择 |
| 设计范围完全未指定 | BLOCKED | 拒绝执行 |
