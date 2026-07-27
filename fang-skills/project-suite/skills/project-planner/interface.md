# Interface: project-planner

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Plan** — `proposals/PLAN-<feature>.md`

## Consumes
- 🔴 **Context**（`context.json`，缺失则 DEGRADED）
- 🔴 **KnowledgeBase**（`.project-knowledge/`，缺失则 DEGRADED）
- 🟢 Requirement（用户需求描述，缺失则 BLOCKED）

## Guarantees
- 任务列表含：ID / 依赖 / 估时 / 优先级 / 风险 / DoD
- 依赖标注：→硬依赖 / ⇢软依赖 / ⤳外部依赖
- 现状探查标记：`[新][有骨架][基本完成][已完成]`
- 风险矩阵含：可能性 / 影响 / 缓解措施

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| context.json 缺失 | DEGRADED | 从 `.project-knowledge/` 提取模块信息 |
| 需求自相矛盾 | DEGRADED | 标注矛盾，产出两个方案 |
| 现状探查无结果 | DEGRADED | 标注 `⚠️ 未找到现有代码`，假定全部 [新] |
| 无任何需求输入 | BLOCKED | 拒绝执行 |
