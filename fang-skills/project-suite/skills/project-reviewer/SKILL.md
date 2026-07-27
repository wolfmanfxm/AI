---
name: project-reviewer
description: >
  对代码变更进行五轴审查：正确性、安全性、可读性、架构、性能。问题分级（BLOCKER/HIGH/MEDIUM/LOW）
  附带精确的 file:line 引用和可操作的修复建议。
  触发词：代码审查、review、检查代码、审查 PR、代码质量、code review、security review、
  audit code、审查、帮我看看这段代码、这个 PR 怎么样。
  产出：REVIEW.md（分级问题列表 + 正向反馈 + 审查结论）。
---

# Reviewer

> 代码变更 → 五轴审查 → 问题分级 → REVIEW.md

## 核心原则

1. **精确引用** — 每个发现标注 `file:line`
2. **可操作** — 每个问题附带具体修复建议
3. **正向反馈** — 做得好的也记录（PRAISE）
4. **分级明确** — BLOCKER 必须有明确阻断理由

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 reviewer 只查不修。发现问题 → 记录 file:line + 建议。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 1 | `.project-knowledge/patterns/` | 标注"⚠️ 缺乏项目规范" |
| 2 | `PLAN.md` | 不阻塞 |
| 3 | `ARCHITECTURE.md` | 不阻塞 |

## 审查轴

| 轴 | 重点 |
|----|------|
| 正确性 | 逻辑错误、边界条件、类型安全、状态一致性、API 契约 |
| 安全性 | 注入、XSS、敏感数据、权限、输入校验 |
| 可读性 | 命名、复杂度、注释、函数长度 |
| 架构 | 模块边界、接口设计、复用、扩展性 |
| 性能 | N+1 查询、渲染、内存、包体积 |

## 问题分级

| 级别 | 判定 |
|------|------|
| 🔴 BLOCKER | 生产事故 → 必须修复 |
| 🟠 HIGH | 大概率引发线上问题 |
| 🟡 MEDIUM | 代码质量可改善 |
| 🟢 LOW | 锦上添花 |
| 🔵 PRAISE | 值得学习 |

## 工作流

1. 确认审查范围 → 读项目规范
2. 🔴 CHECKPOINT → [checkpoint 模式](../../../shared/conventions/checkpoint-pattern.md)
3. 五轴扫描 → 记录问题 → 统一分级
4. 输出 `reports/REVIEW-<topic>.md`

失败处理 → [references/failure-handling.md](references/failure-handling.md)

## 完成后下一步

```
reviewer 完成 → /project-generator(修复) 或 /project-documenter 或 /project-releaser
```
