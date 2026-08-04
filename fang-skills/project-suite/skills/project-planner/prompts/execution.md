# Execution — Planner

> @engine: execution

## Actions

9 步 Pipeline，每步产出对应 PLAN.md 的一个 Section：

| # | 步骤 | 产出 Section | 核心动作 |
|---|------|-------------|---------|
| 1 | Goal 定义 | `# Goal` | 一句话 Goal + 成功标准 |
| 2 | Scope 边界 | `# Scope` | IN/OUT 清单 + 边界说明 |
| 3 | Context 引用 | `# Context` | context.json 关键信息摘要 + 假设表 |
| 4 | Reuse Analysis | `# Reuse Analysis` | 可复用组件/API/模式清单 + 复用方式 |
| 5 | Decision 识别 | `# Decision` | 待决策点列表 + 每个决策影响哪些 Task |
| 6 | Task Breakdown | `# Task Breakdown` | 任务列表（每任务含：名称/估时/依赖/AC/风险） |
| 7 | Dependency Graph | `# Dependency Graph` | 任务依赖图（拓扑序，标注并行机会） |
| 8 | Risk Assessment | `# Risk Assessment` | Top-3 风险 + 缓解措施 + 置信度 |
| 9 | Acceptance Criteria | `# Acceptance Criteria` | 可验证的 AC 列表（每条有 pass/fail 条件） |

→ 详细 Prompt：[prompts/task-breakdown.md](task-breakdown.md)
→ 工作量评估：[prompts/estimation.md](estimation.md)

🔴 CHECKPOINT — 展示 PLAN.md 摘要（任务数+估时+风险TOP3）

## Exit

- 9 个 Section 全部非空（内容 ≥3 行）
- confidence ≥ 40%（否则仅输出 Goal+Scope+Gap List，拒绝产出完整 PLAN）
- 用户已确认摘要

## Failure

| Condition | Action |
|-----------|--------|
| 需求自相矛盾 | 在 Context 假设表中标注，分别给出两个方案覆盖矛盾分支 |
| 时间不可行（估时远超可用工时） | 给出最小可行版 + 完整版两个方案，AskUserQuestion |
| Confidence < 40% | **拒绝产出完整 PLAN**，只输出 `# Goal` + `# Scope`（含 Gap List）→ [confidence-gate](../../../runtime/engine/confidence-gate.md) |
| 用户中途修改需求范围 | 重新划定 Scope，废弃任务标 `[deprecated]` |
