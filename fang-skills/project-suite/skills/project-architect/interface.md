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
- 最低: 50%（候选方案无最优时降低）
- 计算: 100 - 信息不足(20) - 无参考架构(15) - 候选分差<10%(10) - 未核实源码(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| knowledge 缺失 | DEGRADED | 通用模式设计 |
| planning 无 # Decision | DEGRADED | 自行识别 |
| 源码不可读 | DEGRADED | 标注"⚠️ 未核实" |
| 候选无最优 | DEGRADED | 展示对比+权衡 |
| 范围未指定 | BLOCKED | 拒绝执行 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 展示设计范围 + 约束清单 |
| 现状核实 + Graph 分析后 | 展示标注结果 + 循环依赖检测 |

## Resume
- 支持: true
- 方式: state.json

## State
- 读: state.json / knowledge.json / graph.json
- 写: state.json（追加 history）

## Artifacts
- 入: [knowledge, planning, context, graph]
- 出: [design]
