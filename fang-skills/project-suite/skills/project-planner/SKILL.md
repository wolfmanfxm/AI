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

**定位：** 不是 Task Planner。是 Project Planning Engine。职责不是"拆任务"，而是把模糊需求逐步收敛成 Architect、Generator、Reviewer、Tester 都能各自消费的契约。

## 核心原则

1. **Contract over Todo** — 产出 9 模块契约，每个模块标注下游消费者
2. **Knowledge First** — 先扫描 `.project-knowledge/` 可复用资产，再设计
3. **Decision ↔ Task 绑定** — 识别决策点，标注影响哪些 Task，Architect 先 resolve
4. **Confidence 透明** — < 40% 拒绝产出，暴露 Gaps 不强规划

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 Planning Engine 只产出执行契约。识别决策点但不做架构设计（Architect），拆任务但不写代码（Generator）。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **`context.json`** | 从 `.project-knowledge/` 提取 |
| 1 | `.project-knowledge/` | 跳过 Reuse Analysis，标注"⚠️ 缺少知识库" |
| 2 | 上游 `PLAN.md` / `ARCHITECTURE.md`（若存在） | 标注"⚠️ 无上游规划" |

## 工作流

### Discover

1. 加载 `context.json` → 模块/组件/API 清单
2. 读用户输入 + 上游 PLAN.md/ARCHITECTURE.md
3. 一句话总结 Goal + 划定 Scope
4. 🔴 CHECKPOINT — 展示 Goal + Scope，用户确认后进入现状探查

### 现状探查（Discover 后必做）

→ [references/code-audit.md](references/code-audit.md)

> 标注 `[新][有骨架][基本完成][已完成]`，修正估时。
>
> 🔴 CHECKPOINT — 展示现状标注结果 + 修正后估时，用户确认后进入 Execute。

### Execute — 9 步 Pipeline

| # | 步骤 | 产出 Section | 下游消费者 |
|---|------|-------------|-----------|
| 1 | Goal 定义 | `# Goal` | 全部 Skill |
| 2 | Scope 边界 | `# Scope` | Generator、Reviewer |
| 3 | Context 引用 | `# Context` | Architect、Generator |
| 4 | Reuse Analysis | `# Reuse Analysis` | Generator |
| 5 | Decision 识别 | `# Decision` | Architect |
| 6 | Task Breakdown | `# Task Breakdown` | Generator |
| 7 | Dependency Graph | `# Dependency Graph` | Generator、Runtime |
| 8 | Risk Assessment | `# Risk Assessment` | Reviewer、Tester |
| 9 | Acceptance Criteria | `# Acceptance Criteria` | Tester、Reviewer |

→ 详细 Prompt：[prompts/task-breakdown.md](prompts/task-breakdown.md)
→ 工作量评估：[prompts/estimation.md](prompts/estimation.md)

🔴 CHECKPOINT — 9 步 Pipeline 完成后，展示 PLAN.md 摘要（任务数+估时+风险TOP3），用户确认后写入文件。

### Output

- `.project-knowledge/proposals/PLAN-<feature>.md`（9 模块 Contract）
- **`context-package.json`**（预消化知识包，Generator 直接消费，无需读文件）→ [Context Package](../../runtime/contracts/context-package.schema.json)

**context-package.json（v2.0，替代 knowledge-list.json）：**
```json
{
  "capabilities": ["VueConvention", "TablePattern", "FormPattern", "ApiPattern"],
  "plan": "PLAN-<feature>.md"
}
```
使用 capability 标签而非文件路径 → 目录变更不影响 Planner 和 Generator。

## 失败处理

| 触发 | 行为 |
|------|------|
| `.project-knowledge/` 不存在 | 跳过 Reuse Analysis，标注"⚠️ 缺少知识库" |
| 需求自相矛盾 | 标注于 Context 假设表，给出两个方案分别覆盖矛盾分支 |
| 时间不可行 | 给最小可行 + 完整两版，AskUserQuestion |
| Confidence < 40% | **拒绝产出**，只输出 `# Goal` + `# Scope`（含 Gap List） | → [../../runtime/engine/confidence-gate.md](../../runtime/engine/confidence-gate.md) |
| 无任何需求输入 | BLOCKED — 拒绝执行 |
| 上游 PLAN.md 存在但代码已大幅变更 | 标注"⚠️ 上游规划可能过期"，重新执行现状探查，diff 后修正 |
| API 文档路径与代码不一致 | 标注为 `⤳ 待确认` 外部依赖，记录在 Dependency Graph |
| 用户中途修改需求范围 | 重新划定 Scope，标记已废弃任务为 `[deprecated]`，AskUserQuestion 确认新范围 |

## 引用索引

| 资源 | 路径 |
|------|------|
| 入口 Prompt | [prompts/main.md](prompts/main.md) |
| 任务拆解 | [prompts/task-breakdown.md](prompts/task-breakdown.md) |
| 工作量估算 | [prompts/estimation.md](prompts/estimation.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
| 现状探查 | [references/code-audit.md](references/code-audit.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |

## 完成后下一步

```
planner 完成 → /project-architect（resolve Decisions）| /project-generator（已全 resolved）
```

## 输出末尾：Workflow Hint 块

→ [references/workflow-hint.md](references/workflow-hint.md)
