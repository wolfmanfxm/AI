# Interface: project-generator

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Code** — `.vue / .ts / .js` 文件

## Consumes
- 🔴 **Context**（`context.json`，缺 REQUIRED 字段则 BLOCKED）
- 🔴 **Plan Reuse Analysis** — `PLAN.md > # Reuse Analysis`（**必读**：已有组件/模式/API/规则清单）
- 🔴 **Plan Task Breakdown** — `PLAN.md > # Task Breakdown`（**必读**：任务列表 + Decision Deps）
- 🔴 **Plan Dependency Graph** — `PLAN.md > # Dependency Graph`（**必读**：执行顺序 + Wave 分组）
- 🟡 **KnowledgeBase**（`.project-knowledge/`，缺失则 DEGRADED）
- 🟡 **Architecture**（`ARCHITECTURE.md`，若存在则必须读入 — Decision 已 resolve）
- 🟡 **Plan Risk Assessment** — `PLAN.md > # Risk Assessment`（风险级别驱动生成行为的保守程度）

## Guarantees
- 遵循 context.json 中声明的技术栈/别名/约定
- **优先复用** `# Reuse Analysis` 中声明的已有组件/模式/API — 不重复造轮子
- 代码含 loading / error / empty 全状态
- TypeScript 无 `any`（除非必要）
- 生成后输出 plan vs actual 完成报告
- **RISK HIGH 任务**：保守模式 — 额外错误处理、详细日志、完整类型

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| context.json 缺 REQUIRED 字段 | BLOCKED | 拒绝执行，提示运行 analyzer |
| PLAN.md 缺失 + 需求复杂 | DEGRADED | 标注"⚠️ 无规划"，尽量生成 |
| `# Decision` 未全部 resolve | DEGRADED | 标注"⚠️ 存在未 resolve 决策"，对受影响任务降级生成 |
| 代码已存在（重复生成） | DEGRADED | 标注 `[已存在]`，跳过 |
| 需新增依赖 | DEGRADED | 标注 `TODO: 安装`，不修改 package.json |
