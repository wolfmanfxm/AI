# Project Suite

> 软件项目全生命周期 skill 套件 — 9 个 skill，从分析到发布，覆盖完整 SDLC。
> 每个 skill 可独立触发，也可编排为工作流链。每个 skill 只做本阶段的事，不越界。

## 当前版本：0.5.0

本次更新：职责边界硬约束 + AskUserQuestion 全 CHECKPOINT + 现状探查 + 知识库同步策略 + 上下游显式衔接 + 反例黑名单。

## Skill 矩阵

| # | Skill | 职责 | 产出 | 知识库同步 |
|---|-------|------|------|----------|
| 1 | **project-analyzer** | 7 维度代码分析 | `.project-knowledge/` | ✅ 全量 |
| 2 | **project-planner** | 需求 → 任务拆解（现状探查先行） | `proposals/PLAN.md` | ❌ 任务产物 |
| 3 | **project-architect** | 技术选型 + 模块设计（现状核实先行） | `decisions/ARCHITECTURE.md` | ❌ 任务产物 |
| 4 | **project-generator** | 项目知识 → 生产级代码 + 完成报告 | 代码文件 | ❌ 源码 |
| 5 | **project-tester** | 测试生成 + 覆盖率报告 | 测试文件 + 报告 | ❌ 测试产物 |
| 6 | **project-reviewer** | 五轴审查 + BLOCKER→LOW 分级 | `reports/REVIEW.md` | ❌ 任务产物 |
| 7 | **project-refactorer** | 安全重构：9 种手法 + 4 层协议 | 代码文件 | ❌ 源码 |
| 8 | **project-documenter** | 代码 → API/组件/Changelog 文档 | `api/` `components/` `reports/` | ✅ API+组件文档 |
| 9 | **project-releaser** | 版本 bump + Changelog + 发布检查 | `CHANGELOG.md` | ❌ 发布产物 |

## 职责边界（硬性约束）

| 原则 | 说明 |
|------|------|
| **单一职责** | 每个 skill 只做本阶段的活。planner 不做代码，generator 不做设计 |
| **发现问题 → 记录，不修** | planner/architect/reviewer 发现代码问题 → 记录在产出文件中，不直接改代码 |
| **CHECKPOINT → AskUserQuestion** | 所有需要用户确认的步骤，使用 `AskUserQuestion` 给出选项 |
| **上游必读** | generator 启动时检查 PLAN.md/ARCHITECTURE.md 是否存在，存在则必须读取 |
| **现状探查先于产出** | planner（现状探查）和 architect（现状核实）在产出前先确认代码现状 |
| **每个 skill 有反例黑名单** | references/boundary.md 含 ≥3 条「不要做 X」的反例 |

## 知识库同步策略

| 类型 | 同步 Vault？ | 示例 |
|------|------------|------|
| 架构/组件/API/模式文档 | ✅ | `architecture/overview.md` `api/groupCustomer.md` |
| 任务计划 | ❌ | `proposals/PLAN-*.md` |
| 设计决策 | ❌ | `decisions/ARCHITECTURE-*.md` |
| 审查报告 | ❌ | `reports/REVIEW-*.md` |

## 典型工作流

### 全流程
```
analyzer → planner → architect → generator → tester → reviewer → documenter → releaser
  ✅Vault   ❌Vault   ❌Vault     ❌Vault    ❌Vault   ❌Vault    ✅Vault     ❌Vault
```

### 轻量改动: generator → reviewer
### 重构: analyzer → refactorer → tester → reviewer

## 如何使用

每个 skill 用 `/project-<name>` 触发，完成后提示下一步操作。详见 `shared/conventions/checkpoint-pattern.md`。

## 参与

- [docs/architecture.md](docs/architecture.md) — suite 设计决策
- [docs/roadmap.md](docs/roadmap.md) — 版本路线
