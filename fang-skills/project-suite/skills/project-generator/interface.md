# Interface: project-generator

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Code** — `.vue / .ts / .js` 文件

## Consumes
- 🔴 **Context**（`context.json`，缺 REQUIRED 字段则 BLOCKED）
- 🟡 **KnowledgeBase**（`.project-knowledge/`，缺失则 DEGRADED）
- 🟡 **Plan**（`PLAN.md`，若存在则必须读入）
- 🟡 **Architecture**（`ARCHITECTURE.md`，若存在则必须读入）

## Guarantees
- 遵循 context.json 中声明的技术栈/别名/约定
- 代码含 loading / error / empty 全状态
- TypeScript 无 `any`（除非必要）
- 生成后输出 plan vs actual 完成报告

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| context.json 缺 REQUIRED 字段 | BLOCKED | 拒绝执行，提示运行 analyzer |
| PLAN.md 缺失 + 需求复杂 | DEGRADED | 标注"⚠️ 无规划"，尽量生成 |
| 代码已存在（重复生成） | DEGRADED | 标注 `[已存在]`，跳过 |
| 需新增依赖 | DEGRADED | 标注 `TODO: 安装`，不修改 package.json |
