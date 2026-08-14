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
> Candidate → Verify → Accept | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **行为不变** — 重构前后外部行为完全一致
2. **安全第一** — 有测试先跑绿，没测试先加表征测试
3. **小步快跑** — 每次一个重构动作，独立 commit 可回滚
4. **可量化** — "圈复杂度 15→3" > "改好了"

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
> 🔴 沙箱边界：禁止未经用户确认的破坏性 git 操作（reset --hard / checkout -- . / clean -fd / stash drop / push --force），禁止访问其他项目目录。只改工作目录文件。

→ [references/boundary.md](references/boundary.md)
> 🔴 refactorer 只改善结构不改行为。没测试保护不重构。

## 反例黑名单

> 禁止: ① 无测试保护直接重构 ② 重构同时改功能 ③ 一次性重构>5个文件 | → [完整清单](references/boundary.md)

## Common Rationalizations

> "这个重构很安全，不用跑测试" → 必须先跑绿
> "指标改善不明显，但代码确实更好了" → 改善 <10% 必须标注"⚠️ 边际改善"
> "一起改了吧，都是相关的小改动" → 每个重构动作独立 commit

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: git revert → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| 提取方法 Prompt | [prompts/extract-method.md](prompts/extract-method.md) |
| 简化逻辑 Prompt | [prompts/simplify-logic.md](prompts/simplify-logic.md) |
| 安全协议 | [references/safety-protocol.md](references/safety-protocol.md) |

## 完成后下一步 → /project-tester 或 /project-reviewer
