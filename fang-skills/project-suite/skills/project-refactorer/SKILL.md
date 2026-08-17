---
name: project-refactorer
metadata: skill.yaml
description: >
  改善代码结构不改变外部行为：提取函数/组件、简化条件逻辑、移除死代码、语义化重命名、
  拆分过大模块。每次重构必须安全可逆，有测试跑测试，无测试先加表征测试。
  触发词：重构、优化结构、提取公共、简化代码、消除重复、拆分模块、重命名、优化这段代码、迁移、
  refactor、clean up、extract method、simplify、reduce complexity、migrate。
  产出：重构后代码 + REFACTOR.md（变更记录 + 改善指标 + 验证结果）。
---

# Refactorer

> 代码 → 识别坏味道 → 安全重构 → 验证 → REFACTOR.md
> Execute → Verify | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **行为不变** — 重构前后外部行为完全一致
2. **安全第一** — 有测试先跑绿，没测试先加表征测试
3. **小步快跑** — 每次一个重构动作，独立 commit 可回滚
4. **可量化** — "圈复杂度 15→3" > "改好了"
5. **消除重复** — 提取/新建前先 [Reuse Check](../../shared/primitives/reuse-check.md)，避免产出与现有工具重复的代码

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 待重构代码 | 🔴 BLOCKED |
| 1 | 现有测试 | 🟡 DEGRADED — 无测试保护缩小范围 |
| 2 | `.project-knowledge/patterns/` | 🟡 DEGRADED |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 refactorer 只改善结构不改行为。没测试保护不重构。

> 完成后：/project-tester 或 /project-reviewer。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
