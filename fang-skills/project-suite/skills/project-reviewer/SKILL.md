---
name: project-reviewer
metadata: skill.yaml
description: >
  对代码变更进行五轴审查：正确性、安全性、可读性、架构、性能。问题分级（BLOCKER/HIGH/MEDIUM/LOW）
  附带精确的 file:line 引用和可操作的修复建议。
  触发词：代码审查、review、检查代码、审查 PR、代码质量、code review、security review、
  audit code、审查、帮我看看这段代码、这个 PR 怎么样。
  产出：REVIEW.md（分级问题列表 + 正向反馈 + 审查结论）。
---

# Reviewer

> 代码变更 + AC + Risk → 五轴审查 → 问题分级 → REVIEW.md
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **精确引用** — 每个发现标注 `file:line`
2. **AC 对照** — 逐条验证 `PLAN.md > # Acceptance Criteria`
3. **可操作** — 每个问题附带具体修复建议
4. **分级明确** — 🔴BLOCKER → 🟠HIGH → 🟡MEDIUM → 🟢LOW → 🔵PRAISE

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 变更 Code（diff / 文件列表） | 🔴 BLOCKED |
| 1 | `PLAN.md > # Acceptance Criteria` | DEGRADED — 标注"⚠️ 无验收标准" |
| 2 | `PLAN.md > # Risk Assessment` | DEGRADED — 标准审查强度 |
| 3 | `.project-knowledge/patterns/` | 标注"⚠️ 缺乏项目规范" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

> 深度（`depth_profiles`，见 skill.yaml）：**minimal**=只审正确性+安全（小 diff）；**standard/full**=五轴全审。小改动不必跑架构/性能轴。

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 reviewer 只查不修。发现问题 → 记录 file:line + 修复方案。

> 完成后：/project-generator（修复） 或 /project-documenter 或 /project-releaser。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
