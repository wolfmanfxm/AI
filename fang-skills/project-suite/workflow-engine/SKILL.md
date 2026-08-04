---
name: workflow-engine
description: >
  project-suite 统一流程引擎。Skill 只声明 stages: [...]，Engine 注入 Stage Contract 模板。
  不重复 runtime/engine/ 已有的 state machine / checkpoint / error recovery / confidence gate。
---

# Workflow Engine

> Skill 声明 stages，Engine 注入模板 — Skill 只写 Actions/Exit/Failure，Entry/Input/Output/Recovery 由模板提供

## 核心机制：Stage Template Injection

1. 在 `skill.yaml` 的 `interface.stages` 中声明阶段列表
2. SKILL.md 工作流表格引用 `prompts/<stage>.md`（业务逻辑）+ `@engine:` 声明（模板）
3. Engine 加载 `stage-templates/<name>.md`，自动注入 Entry/Input/Output/Recovery
4. Skill 只写 **Actions / Exit / Failure** 三个自定义字段

加载优先级：`@engine:` 块 > 模板默认值 > skill.yaml interface。Skill 可覆盖模板任意字段。

### 模板目录

| 模板 | 适用 Skill |
|------|-----------|
| [discovery](references/stage-templates/discovery.md) | 全部 |
| [execution](references/stage-templates/execution.md) | 全部 |
| [validation](references/stage-templates/validation.md) | 全部 |
| [delivery](references/stage-templates/delivery.md) | analyzer, planner, architect, reviewer, refactorer, documenter, releaser |
| [code-audit](references/stage-templates/code-audit.md) | planner, architect |
| [graph-analysis](references/stage-templates/graph-analysis.md) | architect |

## 三大能力

| 能力 | 路径 |
|------|------|
| Stage Template Injection | 本文件 — Skill 声明 stages，Engine 注入模板 |
| Validation | [references/validation.md](references/validation.md) — 5类检查 + validation-report |
| QA Sub-Agent | [references/qa-pattern.md](references/qa-pattern.md) — Main→QA→Reviewer 三明治 |

## 反例黑名单

> 禁止: ① 重复runtime/engine已有能力 ② 替代SUITE_SPEC作为唯一权威 ③ 模板覆盖Skill全部字段 → [stage-contract.md](references/stage-contract.md)

## 与 runtime/engine/ 的关系

workflow-engine **不重复** runtime/engine/ 已有能力：

| 能力 | 路径 |
|------|------|
| 状态机 / 断点续传 / 异常恢复 / 置信度门禁 | [runtime/engine/](../runtime/engine/) |

## 降级策略

模板文件不存在或无法加载 → Skill 自带完整 Contract 表格作为 Backward Compatibility。

## 引用索引

| 资源 | 路径 |
|------|------|
| Stage Contract 规范 | [references/stage-contract.md](references/stage-contract.md) |
| Stage Templates | [references/stage-templates/](references/stage-templates/) |
| Validation 框架 | [references/validation.md](references/validation.md) |
| QA Sub-Agent 模式 | [references/qa-pattern.md](references/qa-pattern.md) |
| State Machine / Checkpoint / Error Recovery / Confidence Gate | [../runtime/engine/](../runtime/engine/) |
