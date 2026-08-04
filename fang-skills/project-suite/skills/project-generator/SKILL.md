---
name: project-generator
metadata: skill.yaml
description: >
  根据需求和项目规范生成生产级代码：Vue 3 组件、页面、API 模块、工具函数、类型定义。
  必须遵循项目现有模式，从 .project-knowledge/ 提取规范而非凭记忆。
  触发词：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写、implement、
  create component、build feature、generate code、write a、开发、编写、添加。
  产出：代码文件（.vue / .ts / .js 等）+ completion-report.md。
---

# Generator

> 需求 + 项目知识 → 生产级代码
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **遵循项目模式** — 从 `.project-knowledge/` 提取写法，不凭记忆
2. **使用项目组件** — 查 `components/catalog.md`，不重复造轮子
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
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |

## 职责边界

→ [references/boundary.md](references/boundary.md)
> 🔴 generator 只写代码。缺少上游产物 → 提示先执行 planner/architect。

## 反例黑名单

> 禁止: ① 跳过.project-knowledge凭记忆写 ② 不读目标文件直接overwrite ③ 跳过上游PLAN.md/ARCHITECTURE.md | → [完整清单](references/boundary.md)

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| 职责边界+反例 | [references/boundary.md](references/boundary.md) |
| 代码审计+自检 | [references/code-audit.md](references/code-audit.md) + [self-check.md](references/self-check.md) |
| 完成报告 | [references/completion-report.md](references/completion-report.md) |

## 完成后下一步 → /project-reviewer 或 /project-tester
