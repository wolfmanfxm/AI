# Completeness Check — Planner

> 收到任务后第一步：多维度评分 → confidence → 决定 Interview 深度。
> 简单任务不走重流程，复杂任务不遗漏关键信息。

## 评分矩阵

| 维度 | 已知 | 部分已知 | 未知 |
|------|------|---------|------|
| **goal** (目标明确?) | 1.0 | 0.5 | 0.2 |
| **scope** (范围清晰?) | 1.0 | 0.5 | 0.2 |
| **constraints** (约束已知?) | 1.0 | 0.5 | 0.2 |
| **knowledge** (项目知识覆盖?) | 1.0 | 0.6 | 0.3 |

```
requirement_completeness = avg(goal, scope, constraints)
knowledge_coverage = Context Resolver 返回的 knowledge 数量 / 预期数量
planning_confidence = (requirement_completeness × 0.6) + (knowledge_coverage × 0.4)
```

## Interview 深度

| confidence | 深度 | Questions | 模式 |
|-----------|------|-----------|------|
| ≥ 0.9 | None | 0 | 直接 Generate Plan |
| 0.7-0.89 | Light | ≤2 | 只问关键缺口 |
| 0.5-0.69 | Standard | ≤3 | 逐轮追问 |
| < 0.5 | Deep | ≤5 | Planning Loop |

## Interview Budget

按任务复杂度自动分配预算，用完后做 Assumption：

| 复杂度 | Budget | 用完行为 |
|--------|--------|---------|
| Simple | 0 | 假设 + 标注 |
| Normal | 2 | 假设 + 标注 |
| Complex | 5 | 标注 `⚠️ Assumption: ...` |

## Assumption 格式

预算用完 → 不做新的 Interview → 写假设：

```markdown
## Assumptions
- Assume 使用现有 BaseForm 模式 (confidence: 0.81)
- Assume 当前权限模型适用 (confidence: 0.75)
- Assume 单用户单记录 (confidence: 0.90)
```

## 联动 Code Audit + Context Resolver

**Code Audit 先执行**（在 Interview 之前）→ 发现 `[已实现]` 的模块/API/组件 → 自动填充 knowledge 维度：

- 发现 `[已实现] BaseTable` → knowledge 维度 +0.2 → 不需要问"用什么表格组件？"
- 发现 `[已实现] Permission` → 不需要问"是否需要权限？"
- 发现 `[未实现] Export` → 标记为 gap → Interview 时可以问

**Context Resolver 已回答的 → 不重复问**：
- "用什么表单组件？" → Resolver: BaseForm → 跳过
- "是否需要审批流？" → Resolver: creditWorkflow 存在 → 问"是否复用？"而非"是否需要？"

## Planning Loop

```
Receive Task
  → Knowledge Resolver
    → Completeness Check
      ├─ confidence ≥ 0.9 → Generate Plan
      └─ confidence < 0.9
           → Interview (budget 内)
             → Update Context
               → Completeness Check（重新评分）
                 ├─ confidence ≥ 0.9 → Generate Plan
                 └─ budget 用完 → Assumption → Generate Plan
```
