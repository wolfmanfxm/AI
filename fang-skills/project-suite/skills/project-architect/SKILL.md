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

## 反例黑名单

→ [references/boundary.md](references/boundary.md)

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
2. 🔴 CHECKPOINT — 展示设计范围 + 约束清单，用户确认后进入现状核实

### 现状核实（Discover 后必做）

→ [references/code-audit.md](references/code-audit.md)

> 标注 `[已实现][部分实现][未实现]`。已实现的不再出设计方案。

### Graph 模块分析

→ [Graph Query Protocol](../../runtime/contracts/graph-query.md)

1. `findDependencies(<目标模块>)` → 了解当前模块耦合度
2. 全图 edges 按 `group` 聚合 → 识别跨层依赖（view→infrastructure 标注异常）
3. `findConsumers(<目标 API>)` → 修改 API 契约时了解影响范围
4. 循环依赖（A→B 且 B→A）→ 标注为架构风险，建议重构

🔴 CHECKPOINT — 展示现状核实 + Graph 分析结果，用户确认范围后进入 Execute。

### Execute

```
"选什么技术" → 1.技术选型 → [prompts/tech-selection.md](prompts/tech-selection.md)
"模块划分"   → 2.模块设计 → [prompts/module-design.md](prompts/module-design.md)
"API设计"    → 3.API契约  → [prompts/api-design.md](prompts/api-design.md)
综合设计     → 1→2→3 顺序，每步 CHECKPOINT
```

🔴 CHECKPOINT — 展示 ARCHITECTURE.md 摘要（决策数+模块图+API契约），用户确认后写入文件。

### Output

`decisions/ARCHITECTURE-<topic>.md`

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| `.project-knowledge/architecture/` 不存在 | 从代码结构推断模块边界 | 标注"⚠️ 未分析现有架构"，通用模式设计 |
| PLAN.md `# Decision` 为空（无待 resolve 决策） | 自行识别架构决策点 | 标注"⚠️ 自行识别决策点" |
| 候选方案无明确最优（对比矩阵分差 < 10%） | 展示对比 + 权衡分析，标注推荐 | AskUserQuestion 让用户选择 |
| 现状核实源码不可读 | 标注"⚠️ 未核实"，按未实现出方案 | 不基于猜测做架构决策 |
| 设计范围完全未指定 | 🔴 BLOCKED — 拒绝执行 | 提示用户先执行 `/project-planner` |

→ 详细: [references/failure-handling.md](references/failure-handling.md)

## 完成后下一步

architect 完成 → /project-generator 或 /project-reviewer

## 输出末尾：Workflow Hint 块

→ [references/workflow-hint.md](references/workflow-hint.md)
