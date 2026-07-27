---
name: project-planner
description: >
  将需求拆解为可执行的任务列表，分析依赖关系，评估工作量，识别风险，排序优先级。
  触发词：任务拆解、开发计划、需求分析、排期、估算工作量、分解任务、sprint 规划、
  break down tasks、plan sprint、estimate effort、create dev plan、任务规划。
  产出：PLAN.md（任务列表 + 依赖图 + 预估工时 + 风险矩阵）。
---

# Planner

> 需求 → 任务拆解 → 依赖分析 → 工作量评估 → 风险识别 → PLAN.md

## 核心原则

1. **任务粒度适中** — 每个任务 0.5-2 人天，超过 2 天的必须拆分
2. **依赖显式化** — 硬依赖（阻塞）、软依赖（影响但不阻塞）、外部依赖（非本团队可控）
3. **风险透明** — 每个风险标注：可能性、影响、缓解措施
4. **可验证** — 每个任务有明确的完成标准（Definition of Done）

## 路由规则

触发匹配见 [../../runtime/protocols/routing.md](../../runtime/protocols/routing.md#planner)。

## 输入类型与策略

| 输入类型 | 示例 | 策略 |
|---------|------|------|
| 模糊想法 | "我想做一个用户权限系统" | 先澄清需求 → 再拆解 |
| PRD/需求文档 | 完整的功能描述 | 直接拆解，标记模糊点 |
| Issue/Bug | "搜索结果为空时不显示提示" | 单任务拆解，分析影响范围 |
| 多模块需求 | "重构支付+订单模块" | 按模块分组 → 各组独立拆解 |

## 工作流

### Discover（需求理解）

1. 阅读用户输入 + 关联上下文（PLAN.md 上游、ARCHITECTURE.md、`.project-knowledge/`）
2. 一句话总结目标，列出关键约束（时间、技术栈、团队规模、外部依赖）
3. 🔴 **CHECKPOINT** — 确认理解后进入拆解

**失败处理**（Execute 阶段内联）：

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| `.project-knowledge/` 不存在 | 跳过项目已有能力分析，标注 `⚠️ 缺少项目知识库` | 基于通用模式拆解 |
| 需求存在自相矛盾 | 标注矛盾点，AskUserQuestion 澄清 | 保留矛盾标注，给出两个方案 |
| 时间约束不可行 | 标注冲突，给出"最小可行范围"和"完整范围"两个版本 | AskUserQuestion：接受最小范围 / 调整时间 / 取消 |

**模糊需求处理**：若需求有歧义，用以下框架澄清：

| 维度 | 澄清问题 |
|------|---------|
| 范围 | 这个功能包含哪些场景？不包含哪些？ |
| 用户 | 谁会使用？使用频率？ |
| 约束 | 有技术栈限制吗？有性能要求吗？ |
| 优先级 | 什么是最小可用版本（MVP）？ |
| 风险 | 哪部分你最不确定？ |

### Execute（任务拆解）

#### 第一步：需求映射

将需求分解为功能点，粒度控制在"一个开发者可以独立完成"：

```
用户权限系统
  ├── 角色管理 CRUD              → T1
  ├── 权限点管理（树形结构）       → T2
  ├── 用户-角色关联              → T3
  ├── 权限校验中间件              → T4
  ├── 前端权限指令/组件           → T5
  └── 权限变更审计日志            → T6
```

#### 第二步：依赖分析

标注三种依赖：

| 类型 | 标识 | 含义 | 示例 |
|------|------|------|------|
| 硬依赖 | → | 前置任务未完成则无法开始 | T4 需要 T1+T2 完成 |
| 软依赖 | ⇢ | 可以先做但会返工 | T5 先做 UI 再用 mock 数据 |
| 外部依赖 | ⤳ | 非本团队可控 | ⤳ 运维提供部署环境 |

#### 第三步：工作量评估

使用 t-shirt size + 人天双重估算：

| Size | 人天 | 判断标准 |
|------|------|---------|
| S | 0.5-1 | 单文件改动，逻辑简单 |
| M | 1-2 | 多文件，有中等复杂度 |
| L | 2-4 | 跨模块，需要设计 |
| XL | 4+ | 必须拆分 |

**校准**：评估后加 20-30% buffer（沟通、CR、修 bug、未知）。

#### 第四步：优先级排序

| 优先级 | 标准 | 示例 |
|--------|------|------|
| P0 | 阻塞下游任务 / MVP 必须 | 数据库 schema 设计 |
| P1 | 核心功能路径 | 用户登录、主业务流程 |
| P2 | 增强功能 | 高级搜索、导出 |
| P3 | 锦上添花 | 动画优化、深色模式 |

#### 第五步：风险识别

按以下维度扫描风险：

| 维度 | 检查项 |
|------|--------|
| 技术 | 新技术栈？性能瓶颈？兼容性？ |
| 依赖 | 依赖其他团队？第三方 API 不稳定？ |
| 知识 | 团队不熟悉的领域？文档缺失？ |
| 范围 | 需求可能膨胀？边界不清？ |
| 时间 | 外部 deadline 不合理？并行任务过多？ |

### Output

生成 `PLAN.md`，结构如下：

```markdown
---
id: plan-<feature-slug>
generatedBy: planner
generatedAt: <ISO-8601>
confidence: <0-100>
sources:
  - <需求来源>
---

# [需求名称] — 开发计划

## 概述
- **目标**：一句话描述
- **预估总工时**：X 人天（含 Y% buffer）
- **建议里程碑**：M1(D+3) / M2(D+7) / M3(D+12)

## 任务列表

| ID | 任务 | 模块 | 依赖 | 估时 | 人天 | 优先级 | 风险 |
|----|------|------|------|------|------|--------|------|
| T1 | 角色管理 CRUD | auth | - | M | 1.5 | P0 | - |
| T2 | 权限点树形管理 | auth | T1⇢ | L | 2.5 | P0 | 树形组件复杂度 |

## 依赖图

```
T1(角色CRUD) ──→ T3(用户-角色关联) ──→ T4(权限校验)
T2(权限点管理) ──↗                        ↘ T5(前端指令)
                                             ↗
```

## 风险矩阵

| 风险 | 可能性 | 影响 | 缓解措施 | 负责人/团队 |
|------|--------|------|---------|-----------|
| 权限模型复杂度超预期 | 中 | 高 | D+2 前完成 RBAC vs ABAC 技术验证 | - |

## 里程碑

| 里程碑 | D+N | 包含任务 | 验收标准 |
|--------|-----|---------|---------|
| M1 权限数据层 | D+3 | T1, T2 | 角色和权限点 API 可用 |
| M2 权限逻辑层 | D+7 | T3, T4 | 权限校验在关键接口生效 |
| M3 前端 + 审计 | D+12 | T5, T6 | 前端权限控制 + 审计日志可查询 |
```

## 与下游 skill 集成

| 下游 | 传递内容 |
|------|---------|
| architect | 任务列表 + 技术风险（需要架构决策的任务） |
| generator | 按任务顺序逐个实现，generator 按 T1→T2→... 顺序执行 |

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 断点续传 | [../../runtime/engine/checkpoint.md](../../runtime/engine/checkpoint.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |
| 编排 | [../../runtime/protocols/orchestration.md](../../runtime/protocols/orchestration.md) |

## Shared 资源

| 资源 | 路径 | 用途 |
|------|------|------|
| Evidence Header | [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md) | PLAN.md 产出模板 |
| Conventions | [../../shared/conventions/README.md](../../shared/conventions/README.md) | 命名与格式约定 |

## References

| 资源 | 路径 |
|------|------|
| 任务拆解 Prompt | [prompts/task-breakdown.md](prompts/task-breakdown.md) |
| 工作量估算 Prompt | [prompts/estimation.md](prompts/estimation.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 输入输出示例 | [references/examples.md](references/examples.md) |
