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
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

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

> 9-Step Pipeline（Goal→Scope→Context→Reuse→Decision→Tasks→Deps→Risk→AC）与深度（standard=Goal/Scope/Reuse/Tasks/AC，full=9 模块+Interview+Verify）详见 [task-breakdown.md](prompts/task-breakdown.md)。

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）
> 🔴 Planning Engine 只产出执行契约。不架构设计、不写代码。

> 完成后：/project-architect 或 /project-generator。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
