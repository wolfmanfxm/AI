---
name: project-planner
metadata: skill.yaml
description: >
  将需求拆解为可执行的任务列表，分析依赖关系，评估工作量，识别风险，排序优先级。
  触发词：任务拆解、开发计划、需求分析、排期、估算工作量、分解任务、sprint 规划、
  break down tasks、plan sprint、estimate effort、create dev plan、任务规划。
  产出：PLAN.md（任务列表 + 依赖图 + 预估工时 + 风险矩阵）。
---

# Planner

> 需求 → 任务拆解 → 依赖分析 → 工作量评估 → 风险识别 → PLAN.md

## 核心原则

1. **任务粒度适中** — 每个任务 0.5-2 人天
2. **依赖显式化** — 硬依赖(→)、软依赖(⇢)、外部依赖(⤳)
3. **风险透明** — 标注可能性、影响、缓解措施
4. **可验证** — 每个任务有 Definition of Done

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 planner 只做计划不写代码。发现问题记录在风险矩阵，不直接修改。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`** | 从 `.project-knowledge/` 提取模块/组件信息 |
| 1 | `.project-knowledge/` | 标注"⚠️ 缺少项目知识库" |

## 工作流

### Discover

1. 加载 `context.json` → 了解模块/组件/API 清单 + 读用户输入 + 上游 PLAN.md
2. 一句话总结目标 + 列出关键约束
3. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### 现状探查（Discover 后必做）

→ [references/code-audit.md](references/code-audit.md)

> 标注 `[新][有骨架][基本完成][已完成]`，修正估时。

### Execute

| 步骤 | 产出 |
|------|------|
| 需求映射 | 任务树 |
| 依赖分析 → [prompts/task-breakdown.md](prompts/task-breakdown.md) | 依赖图 |
| 工作量评估 → [prompts/estimation.md](prompts/estimation.md) | S/M/L/XL + 人天 |
| 优先级排序 | P0/P1/P2/P3 |
| 风险识别（技术/依赖/知识/范围/时间） | 风险矩阵 |

### Output

`proposals/PLAN-<feature>.md`

## 失败处理

| 触发 | 修复 | 兜底 |
|------|------|------|
| `.project-knowledge/` 不存在 | 跳过已有能力分析 | 通用模式拆解 |
| 需求自相矛盾 | 标注矛盾，AskUserQuestion | 保留矛盾给两个方案 |
| 时间不可行 | 给最小可行+完整两版 | AskUserQuestion |

## 完成后下一步

```
planner 完成 → /project-architect 或 /project-generator
```
