# Interface: project-planner

> Project Planning Engine — 对外契约。

## Produces
- **Plan** — `proposals/PLAN-<feature>.md`（9 模块 Contract）

| # | Section | 下游消费者 |
|---|---------|-----------|
| 1 | `# Goal` | 全部 Skill |
| 2 | `# Scope` | Generator、Reviewer |
| 3 | `# Context` | Architect、Generator |
| 4 | `# Reuse Analysis` | Generator |
| 5 | `# Decision` | Architect |
| 6 | `# Task Breakdown` | Generator |
| 7 | `# Dependency Graph` | Generator、Runtime |
| 8 | `# Risk Assessment` | Reviewer、Tester |
| 9 | `# Acceptance Criteria` | Tester、Reviewer |

## Consumes
- 🔴 **Context**（`context.json`，缺失则 DEGRADED）
- 🔴 **KnowledgeBase**（`.project-knowledge/`，缺失则 DEGRADED — 跳过 Reuse Analysis）
- 🟢 Requirement（用户需求描述，缺失则 BLOCKED）

## Guarantees
- 每个 Section 标注 Primary Consumer — 下游 Skill 只读自己关心的
- Task 含：ID / 依赖 / 估时 / 优先级 / 风险 / Decision Deps / Verification
- 依赖标注：→硬依赖 / ⇢软依赖 / ⤳外部依赖，Wave 分组
- 现状探查：`[新][有骨架][基本完成][已完成]`
- Risk Assessment 含：类别/级别/概率/影响任务/缓解措施 + 下游行为指引表
- Reuse Analysis 含：已有组件/模式/API/规则 — Generator 直接引用
- Decision 含：决策点 + ≥2 候选方案 + 影响 Tasks — Architect 入口
- Scope 含：In/Out 边界 + Confidence 评分 + Gap List
- Confidence < 40% 拒绝产出，只输出 `# Goal` + `# Scope`（含 Gap List）

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| context.json 缺失 | DEGRADED | 从 `.project-knowledge/` 提取 |
| `.project-knowledge/` 缺失 | DEGRADED | 跳过 Reuse Analysis，标注"⚠️ 缺少知识库" |
| 需求自相矛盾 | DEGRADED | 标注于 Context 假设表，产出两个方案 |
| 现状探查无结果 | DEGRADED | 标注 `⚠️ 未找到现有代码`，假定全部 [新] |
| Confidence < 40% | DEGRADED | 拒绝产出完整 PLAN.md，只输出 Goal + Scope + Gap List |
| 无任何需求输入 | BLOCKED | 拒绝执行 |
