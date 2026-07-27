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

## 核心原则

1. **决策可追溯** — 问题 → 候选方案 → 选择 → 理由
2. **上下文驱动** — 选型基于项目约束，不追求银弹
3. **够用就好** — 当前需求 + 可预见扩展
4. **基于事实** — 有 `.project-knowledge/` 时基于现有架构

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 architect 只做设计不写代码。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`** | 从 `.project-knowledge/architecture/` 提取 |
| 1 | `.project-knowledge/architecture/` | 标注"未分析" |
| 2 | `PLAN.md`，**若存在必读** | 标注"⚠️ 无规划" |
| 3 | 上游源码，**现状核实必读** | 标注"⚠️ 未核实" |

## 工作流

### Discover

1. 确认设计范围 + 收集约束
2. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### 现状核实（Discover 后必做）

→ [references/code-audit.md](references/code-audit.md)

> 标注 `[已实现][部分实现][未实现]`。已实现的不再出设计方案。

### Execute

```
"选什么技术" → 1.技术选型 → [prompts/tech-selection.md](prompts/tech-selection.md)
"模块划分"   → 2.模块设计 → [prompts/module-design.md](prompts/module-design.md)
"API设计"    → 3.API契约  → [prompts/api-design.md](prompts/api-design.md)
综合设计     → 1→2→3 顺序，每步 CHECKPOINT
```

### Output

`decisions/ARCHITECTURE-<topic>.md`

## 失败处理

→ [references/failure-handling.md](references/failure-handling.md)

## 完成后下一步

```
architect 完成 → /project-generator 或 /project-reviewer
```
