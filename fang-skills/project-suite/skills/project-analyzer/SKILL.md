---
name: project-analyzer
metadata: skill.yaml
description: >
  分析软件项目并生成可复用的项目知识库，覆盖架构、组件、API、模式、编码风格等维度。
  触发词：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、刷新项目知识、
  项目规范、编码规范、analyze codebase、scan project、project refresh。
  产出：.project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
---

# Analyzer

> 代码扫描 → 7 维度分析 → 结构化知识库 → Vault 同步
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **仅写知识文件** — 不修改源码
2. **基于证据** — 每个结论源自代码，不编造
3. **全量覆盖** — 7 维度并行分析，无死角
4. **可增量** — 支持增量刷新，仅更新变更维度

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 项目源码 | 🔴 BLOCKED |
| 1 | Knowledge Vault 路径 | 🟡 DEGRADED — 跳过 Vault 同步 |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)

## 反例黑名单

> 禁止: ① 修改源码（只写知识文件） ② 跳过CHECKPOINT确认 ③ agent提前返回不等待全部完成 | → [完整清单](references/boundary.md)

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Templates | [../../workflow-engine/references/stage-templates/](../../workflow-engine/references/stage-templates/) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| 维度 Prompt | [prompts/](prompts/) |
| 职责边界+反例 | [references/boundary.md](references/boundary.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |
| Finish 详细 | [references/finish-workflow.md](references/finish-workflow.md) |

## 完成后下一步 → /project-planner 或 /project-architect
