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
| state.json | .project-runtime/ | 🟡 |
| knowledge.md | .project-knowledge/ | 🟡 |
| 用户需求 | User Prompt | 🔴 |

## Output
- `proposals/PLAN-<feature>.md` — 9 模块 Contract
- `state.json` — 追加 history（含 confidence + suggested_next）
- `validation-report.md` — Status + Confidence + Summary + What Was Done + Issues + Workflow Hint

## Confidence
- 最低: 40%（低于此拒绝产出完整计划）
- 计算: 100 - 需求模糊(20) - API缺失(15) - 规则不明(15) - 缺参考(10) - 新库(10) - 假设×5(max20)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| knowledge 缺失 | DEGRADED | 跳过 Reuse Analysis |
| context 缺失 | DEGRADED | 从 knowledge 提取 |
| 需求自相矛盾 | DEGRADED | 标注于 Context 假设表 |
| Confidence < 40% | DEGRADED | 拒绝产出完整 PLAN.md |
| 无需求输入 | BLOCKED | 拒绝执行 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 展示 Goal + Scope，用户确认 |
| 现状探查后 | 展示标注结果 + 修正估时 |
| Execute 后 | 展示 PLAN.md 摘要（任务数+估时+风险TOP3） |

## Resume
- 支持: true
- 方式: 读 `state.json` → 定位当前 phase → 从断点继续

## State
- 读: state.json / knowledge.json / graph.json
- 写: state.json（追加 history + suggested_next）

## Artifacts
- 入: [knowledge, context, graph]
- 出: [planning]
