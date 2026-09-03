# Interface: project-architect

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **design** — `decisions/ARCHITECTURE-<topic>.md`（ADR 格式）

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| knowledge | 🔴 | DEGRADED — 通用模式设计 |
| planning | 🔴 | DEGRADED — 自行识别决策点 |
| context | 🔴 | DEGRADED — 从 knowledge 提取 |
| graph | 🟡 | SKIP — 有则做模块耦合分析 |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| context.json | analyzer | 🔴 |
| PLAN.md > # Decision + # Context | planner | 🔴 |
| graph.json | analyzer | 🟡 |

## Output
- `decisions/ARCHITECTURE-<topic>.md` — ADR（Context→Options→Decision→Rationale）
- `state.json` — 追加 history + confidence
- `ARCHITECTURE-<topic>.md`（ADR 即收尾报告）

## Confidence
- 计算: 100 - 信息不足(20) - 无参考架构(15) - 候选分差<10%(10) - 未核实源码(10)

