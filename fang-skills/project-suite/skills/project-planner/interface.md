# Interface: project-planner

> 标准化接口契约。Scheduler 可只读此文件即可调用 Skill。
> Artifact types 与 `runtime/artifacts/artifact-types.yaml` 对齐。

## Produces
- **planning** — `proposals/PLAN-<feature>.md`（9 模块 Contract）

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| knowledge | 🔴 | DEGRADED — 跳过 Reuse Analysis |
| context | 🔴 | DEGRADED — 从 knowledge 提取 |
| graph | 🟡 | SKIP — 有则用于模块关系分析 |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| context.json | analyzer | 🔴 |
| state.json | .project-knowledge/runtime/ | 🟡 |
| knowledge.md | .project-knowledge/ | 🟡 |
| 用户需求 | User Prompt | 🔴 |

## Output
- `proposals/PLAN-<feature>.md` — 9 模块 Contract
- `state.json` — 追加 history（含 confidence + suggested_next）
- `validation-report.md` — Status + Confidence + Summary + What Was Done + Issues + Workflow Hint

## Confidence
- 计算: 100 - 需求模糊(20) - API缺失(15) - 规则不明(15) - 缺参考(10) - 新库(10) - 假设×5(max20)

