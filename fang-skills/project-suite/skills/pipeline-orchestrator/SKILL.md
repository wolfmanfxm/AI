---
name: pipeline-orchestrator
metadata: skill.yaml
description: >
  跨 Skill Pipeline 编排引擎。读取 registry 自动发现依赖，按 DAG 顺序调度执行，
  传递上下文，处理失败。从 9 个独立 Skill 变成 1 个协调执行的 Pipeline Framework。
  触发词：全流程、一键执行、自动编排、pipeline、完整链路、端到端、从分析到发布、自动化开发、full pipeline、orchestrate、end-to-end、auto sdlc、run all、complete workflow。
  产出：pipeline-state.json + pipeline-report.md。
---

# Pipeline Orchestrator

> 读取 registry → 呈现 pipeline → auto-advance + Decision-Boundary Checkpoint → 传递上下文 → 报告 → 触发 Background Pipeline
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — Execution Driver + Registry-Driven + Stage Template Injection

## 核心原则

1. **不替代单个 Skill** — 只做编排，每个 Skill 独立执行自己的业务逻辑
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
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Orchestrate | [prompts/orchestrate.md](prompts/orchestrate.md) | @engine: execution |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 可用 Pipeline

> Pipeline 路由由 [Complexity Gate](../../shared/prompts/complexity-gate.md) 决定（Reuse Fast Path / Quick / Standard / Full），具体 pipeline 定义见 [workflow-library.yaml](../../runtime/registry/workflow-library.yaml)。

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 orchestrator 只调度不执行单个 Skill 的业务逻辑。不替代任何 Skill。

> 完成后：人工审核 pipeline 产出。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
