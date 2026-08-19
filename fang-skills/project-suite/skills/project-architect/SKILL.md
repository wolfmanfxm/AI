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
> 遵循 [workflow-protocol](../../workflow-protocol/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **决策可追溯** — 问题 → 候选方案 → 选择 → 理由；严谨度按 [决策成本门](#决策成本门) 定
2. **上下文驱动** — 选型基于项目约束，不追求银弹
3. **现状核实先行** — `[已实现]` 的模块不再出设计方案（先走 [Reuse Check](../../shared/primitives/reuse-check.md)）
4. **够用就好** — 当前需求 + 可预见扩展

## 决策成本门（Decision Cost Gate）

> 不是所有决策都要完整 ADR。严谨度匹配决策成本（可逆性 / 影响面）。

| 决策类型 | 判据 | 严谨度 |
|---------|------|--------|
| **low-impact** | 可逆、局部、单模块内 | 直接选 + reason（1 个方案即可，不强制对比矩阵） |
| **high-impact** | 不可逆 / 跨模块 / 影响下游 | ≥2 方案 + ≥3 维度对比矩阵（完整 ADR） |

判据优先级：**可逆性 > 影响面**（改个常量可逆 → low；改数据库 schema / 换技术栈 → high）。

> ⚠️ **Decision Impact ≠ Task Complexity**：决策成本门看的是「这个决策的影响」（可逆性/影响面），不是「任务的复杂度」。一个 complex 任务里可能有多个 low-impact 决策，一个 simple 任务里也可能有 irreversible 决策——两者独立判断。

## 决策风险分级（Grill / Challenge 条件机制）

> 借鉴 Matt Pocock grill-me，与 planner 的 Adaptive Interview 对称。不是每次决策都追问——只在「高风险 / 低 confidence / 多方案分歧」时才 Challenge。

| 决策风险 | 触发条件 | 动作 |
|---------|---------|------|
| **Low** | 只有一个合理方案，或可逆且影响小 | 直接执行，不追问 |
| **Medium** | 有 2 个方案但有一个明显更优，或 confidence 70-89 | 1~3 个 Challenge 问题（质疑选型的理由），答完即执行 |
| **High** | 多个方案分歧大 / confidence < 70 / 不可逆决策 | Grill-Me：逐条质疑假设，等价于 Decision Review |

**规则**：
- 决策风险与决策成本门**正交**——low-impact 决策也可能高风险（如「虽然可逆但方案分歧大」），high-impact 决策也可能低风险（如「虽然不可逆但只有一个合理方案」）。
- 简单任务不该被问太多问题：只有 High 风险才 Grill，Medium 只做轻量 Challenge，Low 直接过。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | `context.json` | 从 architecture 知识（Context Resolver 注入） 提取 |
| 1 | architecture 知识（Context Resolver 注入） | 标注"未分析" |
| 2 | `PLAN.md`，若存在必读 | 标注"⚠️ 无规划" |
| 3 | 上游源码 | 标注"⚠️ 未核实" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @template: discovery |
| Code Audit | [prompts/code-audit.md](prompts/code-audit.md) | @template: code-audit |
| Graph Analysis | [prompts/graph-analysis.md](prompts/graph-analysis.md) | @template: graph-analysis |
| Execution | [prompts/execution.md](prompts/execution.md) | @template: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @template: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @template: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @template: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）
> 🔴 architect 只做设计不写代码。

> 完成后：/project-generator 或 /project-reviewer。通用约束 → [workflow-protocol](../../workflow-protocol/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/mechanisms/command-guard.md)。
