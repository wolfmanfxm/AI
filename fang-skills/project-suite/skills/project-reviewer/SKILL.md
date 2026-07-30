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

> 代码变更 + Acceptance Criteria + Risk Assessment → 五轴审查 → 问题分级 → REVIEW.md

## 核心原则

1. **精确引用** — 每个发现标注 `file:line`
2. **AC 对照** — 逐条验证 `PLAN.md > # Acceptance Criteria`
3. **可操作** — 每个问题附带具体修复建议
4. **分级明确** — BLOCKER 必须有明确阻断理由

## 职责边界

→ [references/boundary.md](references/boundary.md)

> 🔴 reviewer 只查不修。发现问题 → 记录 file:line + 修复方案。对照 Scope 检查范围蔓延。

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **发现问题后动手修改代码** | reviewer 的 diff 与 generator 的修复混在一起，无法追溯 | 只记录 file:line + 修复方案，修复由 generator 或人工执行 |
| 2 | **没有 file:line 就报告问题** | 开发者找不到问题位置，审查结论无法验证 | 每个发现必须标注精确的 `file:line` 引用 |
| 3 | **跳过 AC 对照直接审查** | 不知道需求是什么，审查变成主观代码风格评判 | 先读 PLAN.md `# Acceptance Criteria`，逐条验证 |
| 4 | **BLOCKER 无明确阻断理由** | 滥用最高级别导致审查失信（"狼来了"效应） | 每个 🔴 BLOCKER 必须附：触发条件 + 生产影响 + 必须在合并前修复的理由 |
| 5 | **仅给负面评价无 PRAISE** | 审查变成挑刺，团队抵触情绪积累 | 值得学习的代码用 🔵 PRAISE 标注，说明好在哪里 |

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **变更 Code**（diff / 文件列表）| 🔴 BLOCKED — 拒绝执行 |
| 1 | **`PLAN.md > # Acceptance Criteria`** | DEGRADED — 标注"⚠️ 无验收标准" |
| 2 | **`PLAN.md > # Risk Assessment`** | DEGRADED — 标准审查强度 |
| 3 | **`PLAN.md > # Scope`** | DEGRADED — 无法检查范围蔓延 |
| 4 | `.project-knowledge/patterns/` | 标注"⚠️ 缺乏项目规范" |
| 5 | `PLAN.md > # Task Breakdown` | 不阻塞 — 判断是否超出规划范围 |
| 6 | `ARCHITECTURE.md` | 不阻塞 — 对照决策检查一致性 |

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

### Discover

1. 加载 `PLAN.md > # Acceptance Criteria` + `# Risk Assessment` + `# Scope`
2. **Graph 影响分析** → [Graph Query Protocol](../../runtime/contracts/graph-query.md)：
   - `findImpacted([变更文件列表])` → 本次修改影响哪些节点
   - `findConsumers(<受影响 API>)` → 修改 API 时了解下游影响
   - 影响节点 > 5 → 审查强度自动升级为 HIGH
3. 按 Risk Assessment 确定审查强度：HIGH → Full audit / MEDIUM → Spot check / LOW → Standard
4. 🔴 CHECKPOINT — 展示审查范围+影响节点+审查强度，用户确认后进入 Execute

### Execute

5. **五轴扫描** → 每轴逐文件检查，每个发现标注 `file:line` + 修复方案
6. **AC 逐条验证** → 对照 `# Acceptance Criteria`，标注 ✅/❌/⚠️
7. **Scope 边界检查** → 变更是否超出 PLAN.md `# Scope`，超出标注 `[SCOPE CREEP]`
8. **Candidate 验证**（若 Generator 产出了 Candidate 知识）→ 验证准确性 → 标注 confidence → 满足 R3（> 85）→ 更新 knowledge.json

### Output

`reports/REVIEW-<topic>.md`：问题列表（按 BLOCKER→HIGH→MEDIUM→LOW 排序）+ PRAISE + AC 对照表 + 审查结论

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 变更文件 > 20 | 只审查核心文件（按变更量+风险排序），其余标注 `⚠️ 未审查` | AskUserQuestion：全审 / 核心 / 指定文件 |
| 文件过大无法完整读取 | 分段读关键区域（函数签名+分支+异常处理），标注 `⚠️ 未完整审查` | 限审查深度，优先发现 BLOCKER |
| `.project-knowledge/` 不存在 | 使用通用代码质量标准审查，标注 `⚠️ 缺乏项目规范` | 不阻塞 — 通用标准仍有效 |
| 不熟悉的语言/框架 | 仅做通用检查（命名/结构/注释），标注 `[超出审查范围]` | 跳过语言特有检查，不强制推断 |
| PLAN.md 缺失无法对照 AC | 从代码推断功能意图，标注 `⚠️ 无验收标准` | 不阻塞 — 降级为纯代码审查 |
| Graph 不可用（graph.json 缺失） | 手动分析 import 依赖链（grep import），标注 `⚠️ 无 Graph` | 影响范围分析降级为静态 import 扫描 |

## 完成后下一步

```
reviewer 完成 → /project-generator(修复) 或 /project-documenter 或 /project-releaser
```
