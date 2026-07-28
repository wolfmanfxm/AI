# Interface: project-architect

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Architecture** — `decisions/ARCHITECTURE-<topic>.md`（ADR 格式）

## Consumes
- 🔴 **Context**（`context.json`，缺失则 DEGRADED）
- 🔴 **Plan Decision** — `PLAN.md > # Decision`（Planning Engine 识别的决策点，缺失则自行识别）
- 🔴 **Plan Context** — `PLAN.md > # Context`（项目现状 + 约束 + 假设）
- 🟡 **KnowledgeBase**（`.project-knowledge/architecture/`，缺失则 DEGRADED）
- 🟡 **Plan Reuse Analysis** — `PLAN.md > # Reuse Analysis`（技术选型优先考虑已有资产）

## Guarantees
- 每个决策含：Context → Options（≥2）→ Decision → Rationale → Affected Tasks
- 决策可追溯到 PLAN.md 的 Decision ID（D-01 → ARCHITECTURE.md D-01）
- 选型基于对比矩阵（候选方案 × 评估维度），不凭记忆
- 现状核实：`[已实现][部分实现][未实现]`
- API 契约含：方法+路径+参数+响应+鉴权+幂等
- 已 resolve 的决策标注 `[RESOLVED]`

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| KnowledgeBase 不存在 | DEGRADED | 通用模式设计，标注"⚠️ 未分析现有架构" |
| PLAN.md 存在但无 `# Decision` | DEGRADED | 标注"无待 resolve 决策"，自行识别 |
| 现状核实源码不可读 | DEGRADED | 标注"⚠️ 未核实"，按未实现处理 |
| 候选方案无明确最优 | DEGRADED | 展示对比+权衡，标记待用户选择 |
| 设计范围完全未指定 | BLOCKED | 拒绝执行 |
