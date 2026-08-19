# Execution — Planner

> @template: execution
> Session Snapshot: 每步 Pipeline 后写入 `.project-knowledge/.sessions/project-planner/state.json` → 跨 session resume

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
⚡ 写入 session snapshot: `current_step` + `completed_sections` → 中断后从此步骤 resume

## Decision Record

每个决策输出标准化 Decision Record：

```yaml
decisions:
  - id: D1
    decision: "模块划分: 新建 pricingManage/"
    selected: "pricingManage/"
    ignored:
      - { option: "扩展 approvalManage/", reason: "approvalManage 已有 133 文件(top5), 耦合风险高" }
      - { option: "新建 billingManage/", reason: "太泛, 未来可能包含非价格功能" }
    reason: "价格调整是独立业务域, 与审批管理职责不同"
    evidence: ["approvalManage/ 133 files", "orderManage 60 files (独立模块)"]
    confidence: 0.85
    risk: "审批流集成需确认"
    owner: "architect"
```

## Exit

- 9 个 Section 全部非空（内容 ≥3 行）
- confidence ≥ 40%（否则仅输出 Goal+Scope+Gap List，拒绝产出完整 PLAN）
- Reasoning Report 已生成
- 用户已确认摘要

## Failure

| Condition | Action |
|-----------|--------|
| 需求自相矛盾 | 在 Context 假设表中标注，分别给出两个方案覆盖矛盾分支 |
| 时间不可行（估时远超可用工时） | 给出最小可行版 + 完整版两个方案，AskUserQuestion |
| Confidence < 40% | **拒绝产出完整 PLAN**，只输出 `# Goal` + `# Scope`（含 Gap List）→ [confidence-gate](../../../runtime/mechanisms/confidence-gate.md) |
| 用户中途修改需求范围 | 重新划定 Scope，废弃任务标 `[deprecated]` |
