---
name: project-generator
metadata: skill.yaml
description: >
  根据需求和项目规范生成生产级代码：组件、页面、API 模块、工具函数、类型定义。
  技术栈由 context + project-knowledge 决定，不预设框架。
  必须遵循项目现有模式，从 .project-knowledge/ 提取规范而非凭记忆。
  触发词：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写、修改、调整、修复、
  删除、改、搭建、implement、create component、build feature、generate code、write a、modify、
  fix、delete、change、update、build、开发、编写、添加。
  产出：代码文件（按项目技术栈）+ completion-report.md。
---

# Generator

> 需求 + 项目知识 → 生产级代码
> Execute → Verify | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **遵循项目模式** — 从 `.project-knowledge/` 提取写法，不凭记忆
2. **使用项目组件** — 查 `components/catalog.md`，不重复造轮子。先走 [Reuse Ladder](../../shared/primitives/reuse-check.md)：需求已覆盖 → 零改动
3. **完整性** — loading、empty、error 全状态覆盖
4. **增量修改** — 已存在文件先 Read 再 Edit，不 overwrite

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | `context.json` + `context-package.json` | 🔴 BLOCK |
| 1 | `.project-knowledge/index.md` | 降级通用模式 |
| 2 | `PLAN.md`，若存在必读 | 标注"⚠️ 无规划" |
| 3 | `ARCHITECTURE.md`，若存在必读 | 标注"⚠️ 无架构约束" |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |

> 深度（`depth_profiles`，见 skill.yaml）：**minimal**=跳过 Validation（Discovery → Execution → Verify）；**standard/full**=4 段全走。单文件小改的独立复验是浪费。

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 generator 只写代码。缺少上游产物 → 提示先执行 planner/architect。

> 完成后：/project-reviewer 或 /project-tester。通用约束 → [workflow-engine](../../workflow-engine/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/engine/command-guard.md)。
