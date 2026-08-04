---
name: project-architect
metadata: skill.yaml
description: >
  架构决策、技术选型、模块设计、API 契约设计。使用对比矩阵做技术选型，输出 ADR 格式的架构决策记录。
  触发词：架构设计、技术选型、模块设计、系统设计、数据库设计、API 设计、架构评审、
  怎么设计、选什么技术、模块怎么划分、接口怎么定义、design architecture、tech stack、
  system design、API design。
  产出：ARCHITECTURE.md（ADR 决策记录 + 模块图 + 选型理由 + API 契约）。
---

# Architect

> 需求 → 技术选型 → 模块设计 → API 契约 → ARCHITECTURE.md
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **决策可追溯** — 问题 → 候选方案 → 选择 → 理由（ADR 格式）
2. **上下文驱动** — 选型基于项目约束，不追求银弹
3. **现状核实先行** — `[已实现]` 的模块不再出设计方案
4. **够用就好** — 当前需求 + 可预见扩展

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | `context.json` | 从 `.project-knowledge/architecture/` 提取 |
| 1 | `.project-knowledge/architecture/` | 标注"未分析" |
| 2 | `PLAN.md`，若存在必读 | 标注"⚠️ 无规划" |
| 3 | 上游源码 | 标注"⚠️ 未核实" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Code Audit | [prompts/code-audit.md](prompts/code-audit.md) | @engine: code-audit |
| Graph Analysis | [prompts/graph-analysis.md](prompts/graph-analysis.md) | @engine: graph-analysis |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 architect 只做设计不写代码。

## 反例黑名单

> 禁止: ① 写代码（只做设计） ② 跳过现状核实 ③ 基于猜测做架构决策 | → [完整清单](references/boundary.md)

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Code Audit | [prompts/code-audit.md](prompts/code-audit.md) |
| Stage Graph Analysis | [prompts/graph-analysis.md](prompts/graph-analysis.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| 技术选型 Prompt | [prompts/tech-selection.md](prompts/tech-selection.md) |
| 模块设计 Prompt | [prompts/module-design.md](prompts/module-design.md) |
| API 契约 Prompt | [prompts/api-design.md](prompts/api-design.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
| 决策框架 | [references/decision-framework.md](references/decision-framework.md) |

## 完成后下一步 → /project-generator 或 /project-reviewer
