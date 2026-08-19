---
name: pipeline-orchestrator
metadata: skill.yaml
description: >
  跨 Skill Pipeline 编排协议（Pipeline Protocol + Decision Boundary，非执行引擎）。
  读取 registry 建议 pipeline 路径，在决策边界处交给用户确认，传递上下文，处理失败。
  触发词：全流程、一键执行、自动编排、pipeline、完整链路、端到端、从分析到发布、自动化开发、full pipeline、orchestrate、end-to-end、auto sdlc、run all、complete workflow。
  产出：pipeline-state.json + pipeline-report.md。
---

# Pipeline Orchestrator

> 读取 registry → 建议 pipeline 路径 → Decision-Boundary Checkpoint（用户决定）→ 传递上下文 → 报告 → 触发 Background Pipeline
> Suite 提供 Pipeline Protocol（建议执行路径），Host/用户决定实际执行（见 [host-capability.md](../../runtime/contracts/host-capability.md)）

## 核心原则

1. **不替代单个 Skill** — 只做编排建议，每个 Skill 独立执行自己的业务逻辑
2. **基于 Registry** — 从 runtime/registry/ 读取 pipeline 定义，不硬编码
3. **上下文传递** — analyzer 产出 → planner 消费 → architect 消费 → ...
4. **失败不阻断全链路** — 中间 Skill 失败时记录、询问、继续或终止

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | `runtime/registry/capabilities.yaml` | 🔴 BLOCKED |
| 1 | `runtime/registry/workflow-library.yaml` | 🔴 BLOCKED |
| 2 | `.project-runtime/state.json` | 🟡 DEGRADED — 无历史状态 |
| 3 | 被编排的 Skill 均可用 | 🟡 DEGRADED — 跳过缺失 Skill |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @template: discovery |
| Orchestrate | [prompts/orchestrate.md](prompts/orchestrate.md) | @template: execution |
| Validation | [prompts/validation.md](prompts/validation.md) | @template: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @template: delivery |

## 可用 Pipeline

> Pipeline 路由由 [Complexity Gate](../../shared/prompts/complexity-gate.md) 决定（Reuse Fast Path / Quick / Standard / Full），具体 pipeline 定义见 [workflow-library.yaml](../../runtime/registry/workflow-library.yaml)。

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）
> 🔴 orchestrator 只调度不执行单个 Skill 的业务逻辑。不替代任何 Skill。

> 完成后：人工审核 pipeline 产出。通用约束 → [workflow-protocol](../../workflow-protocol/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/mechanisms/command-guard.md)。
