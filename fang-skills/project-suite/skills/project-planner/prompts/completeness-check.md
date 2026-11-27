# Completeness Check — Planner

> 收到任务后第一步：多维度评分 → confidence → 决定 Interview 深度。
> 简单任务不走重流程，复杂任务不遗漏关键信息。

## Decision State：三态替代二元判断

每个关键决策标注状态：

| State | 含义 | 触发 |
|-------|------|------|
| **KNOWN** | 项目知识/Code Audit 已回答 | 自动填充，不询问 |
| **ASSUMED** | 无明确证据但合理推断 | 标注 confidence，Interview 时优先确认 |
| **NEEDS_CLARIFICATION** | 缺失 + 影响 high | Interview 时必问 |

```yaml
decisions:
  - field: form_component
    state: KNOWN
    value: <统一表单封装>
    source: context-package.json#knowledge(pattern.form-wrapper)
  - field: avatar_storage
    state: ASSUMED
    value: existing-upload-service
    confidence: 0.72
  - field: permission_model
    state: NEEDS_CLARIFICATION
    impact: high
```

## 评分矩阵

| 维度 | KNOWN(1.0) | ASSUMED(0.6) | NEEDS_CLARIFICATION(0.2) |
|------|-----------|-------------|-------------------------|
| **goal** | 1.0 | 0.5 | 0.2 |
| **scope** | 1.0 | 0.5 | 0.2 |
| **constraints** | 1.0 | 0.5 | 0.2 |
| **knowledge** | 1.0 | 0.6 | 0.3 |

```
requirement_completeness = Σ(state_score × weight) / Σ(weight)
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

按任务复杂度自动分配预算，用完后**按影响分流**（不是一律写假设）：

| 复杂度 | Budget | 用完行为 |
|--------|--------|---------|
| Simple | 0 | 低/中影响 → 假设 + 标注；高影响 → Pending Decisions |
| Normal | 2 | 同上 |
| Complex | 5 | 同上 |

> **高影响未决项**（`state: NEEDS_CLARIFICATION` + `impact: high`）是拦截条件，不是预算问题：
> 预算用完也必须把选择权交回用户（`## Pending Decisions` + CHECKPOINT），
> 不得静默写成 Assumption——那等于替用户做了产品决策。

## Assumption 格式

预算用完 → 低/中影响写假设（高影响写 `## Pending Decisions`，格式见 [interview.md](interview.md)）：

```markdown
## Assumptions
- Assume 使用现有 <统一表单封装> 模式 (confidence: 0.81)
- Assume 当前权限模型适用 (confidence: 0.75)
- Assume 单用户单记录 (confidence: 0.90)
```

## 联动 Code Audit + Context Resolver

**Code Audit 先执行**（在 Interview 之前）→ 发现 `[已实现]` 的模块/API/组件 → 自动填充 knowledge 维度：

- 发现 `[已实现] BaseTable` → knowledge 维度 +0.2 → 不需要问"用什么表格组件？"
- 发现 `[已实现] Permission` → 不需要问"是否需要权限？"
- 发现 `[未实现] Export` → 标记为 gap → Interview 时可以问

**Context Resolver 已回答的 → 不重复问**：
- "用什么表单组件？" → Resolver: <统一表单封装> → 跳过
- "是否需要审批流？" → Resolver: <审批流实现> 存在 → 问"是否复用？"而非"是否需要？"

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
                 └─ budget 用完
                      ├─ 有高影响未决 → Pending Decisions → CHECKPOINT（用户拍板 / 显式授权按假设执行）
                      └─ 否则 → Assumption → Generate Plan
```
