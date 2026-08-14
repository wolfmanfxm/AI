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

→ [workflow-library.yaml](../../runtime/registry/workflow-library.yaml)

| Pipeline | 适用场景 |
|----------|---------|
| `full-sdlc` | 全生命周期：analyzer → planner → architect → generator → tester → reviewer → documenter → releaser |
| `analyze-plan-build` | 新功能开发：analyzer → planner → architect → generator → reviewer |
| `quick-change` | 轻量改动：generator → reviewer |
| `refactor-cycle` | 重构循环：reviewer → refactorer → tester → reviewer |
| `knowledge-refresh` | 知识刷新：analyzer → documenter |

## 职责边界
> 🔴 沙箱边界：禁止未经用户确认的破坏性 git 操作（reset --hard / checkout -- . / clean -fd / stash drop / push --force），禁止访问其他项目目录。只改工作目录文件。

→ [references/boundary.md](references/boundary.md)
> 🔴 orchestrator 只调度不执行单个 Skill 的业务逻辑。不替代任何 Skill。

## 反例黑名单

> 禁止: ① 替代单个 Skill 的功能（只调度不执行） ② 硬编码 pipeline（必须从 registry 读取） ③ 中间失败静默跳过不询问用户 ④ 跳过 decision-boundary checkpoint 直接推进 | → [完整清单](references/boundary.md)

## Common Rationalizations

> "上一个 Skill 成功了，直接继续" → 到达 decision boundary 仍要确认
> "这个 Skill 很快，不用展示 Summary" → 每个 decision boundary 展示 Summary
> "失败了跳过就行，不影响整体" → 失败必须 AskUserQuestion

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 恢复: pipeline-state.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Orchestrate | [prompts/orchestrate.md](prompts/orchestrate.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| Workflow Library | [../../runtime/registry/workflow-library.yaml](../../runtime/registry/workflow-library.yaml) |
| Capability Registry | [../../runtime/registry/capabilities.yaml](../../runtime/registry/capabilities.yaml) |
| 职责边界 | [references/boundary.md](references/boundary.md) |

## 完成后下一步 → 人工审核 pipeline 产出 / 或单独触发下游 Skill
