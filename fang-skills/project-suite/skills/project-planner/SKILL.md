---
name: project-planner
metadata: skill.yaml
description: >
  Project Planning Engine — 把模糊需求收敛成整个 Suite 都能消费的执行契约（不是 Task Planner）。
  触发词：任务拆解、开发计划、需求分析、排期、估算工作量、分解任务、sprint 规划、
  break down tasks、plan sprint、estimate effort、create dev plan、任务规划。
  产出：PLAN.md — 9 模块 Contract（Goal → Scope → Context → Reuse → Decision → Tasks → Deps → Risk → Acceptance）。
---

# Project Planning Engine

> 模糊需求 → Pipeline 收敛 → 9 模块执行契约 → 全 Suite 可消费
> Candidate → Verify → Accept | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **Contract over Todo** — 产出 9 模块契约，每模块标注下游消费者
2. **Knowledge First** — 先扫描 `.project-knowledge/` 可复用资产
3. **Decision ↔ Task 绑定** — 识别决策点，Architect 先 resolve
4. **Confidence 透明** — < 40% 拒绝产出，暴露 Gaps

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | `context.json` | 从 `.project-knowledge/` 提取 |
| 1 | `.project-knowledge/` | 跳过 Reuse Analysis |
| 2 | 上游 PLAN.md/ARCHITECTURE.md（若存在） | 标注"⚠️ 无上游" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Interview | [prompts/interview.md](prompts/interview.md) | 需求模糊时启用 |
| Code Audit | [prompts/code-audit.md](prompts/code-audit.md) | @engine: code-audit |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 执行链

```
User 需求
  ↓
Code Audit（现状探查 → 发现已有 BaseTable/Permission/API → 减少无效问题）
  ↓
Knowledge Resolver（查询 graph.json → 注入已有 knowledge）
  ↓
Completeness Check（goal/scope/constraints/knowledge → planning_confidence）
  ↓
Adaptive Interview（confidence<0.9 → ≤5 questions, budget 用完 → Assumption）
  ↓
9-Step Pipeline（Goal→Scope→Context→Reuse→Decision→Tasks→Deps→Risk→AC）
  ↓
Decision Record（每个决策: selected + ignored + reason + confidence）
  ↓
Verify（5-Verify → Accepted/Adjusted/Rejected）
  ↓
Delivery（PLAN.md + context-package.json）
```

下游衔接: Architect 读 PLAN.md `# Decision` → Generator 读 `# Task Breakdown` + `# Reuse Analysis` → Reviewer 读 `# Acceptance Criteria`。

## 职责边界
> 🔴 沙箱边界：禁止未经用户确认的破坏性 git 操作（reset --hard / checkout -- . / clean -fd / stash drop / push --force），禁止访问其他项目目录。只改工作目录文件。

→ [references/boundary.md](references/boundary.md)
> 🔴 Planning Engine 只产出执行契约。不架构设计、不写代码。

## 反例黑名单

> 禁止: ① 做架构设计（只识别决策点） ② 写代码（只拆任务） ③ confidence<40仍产出完整PLAN | → [完整清单](references/boundary.md)

## Common Rationalizations

> "需求很明确，不需要现状探查" → 仍然 Code Audit
> "估时差不多就行，不用精确" → 每个 Task 必须有 S/M/L + 天数
> "依赖关系很明显，不用画 DAG" → 必须画，必须检查循环

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Code Audit | [prompts/code-audit.md](prompts/code-audit.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| 任务拆解 Prompt | [prompts/task-breakdown.md](prompts/task-breakdown.md) |
| 工作量估算 | [prompts/estimation.md](prompts/estimation.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |

## 完成后下一步 → /project-architect 或 /project-generator
