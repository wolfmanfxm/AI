# Interface: project-generator

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **implementation** — 生产级代码（扩展名按项目技术栈）

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| context | 🔴 | BLOCKED（缺 REQUIRED 字段） |
| knowledge | 🔴 | DEGRADED — 降级通用模式 |
| planning | 🔴 | DEGRADED — 标注"⚠️ 无规划" |
| graph | 🔴 | DEGRADED — 跳过 graph 查询 |
| design | 🟡 | DEGRADED — 降级生成 |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| context.json | analyzer | 🔴 |
| PLAN.md > # Task Breakdown + # Dependency Graph | planner | 🔴 |
| PLAN.md > # Reuse Analysis | planner | 🔴 |
| graph.json | analyzer | 🔴 |
| ARCHITECTURE.md | architect | 🟡 |

## Output
- 代码文件（按项目技术栈）
- `state.json` — 追加 history
- `result.md` — 含 plan vs actual 完成报告

## Confidence
- 最低: 70%
- 计算: 100 - knowledge非accepted(15) - design未resolve(15) - 全新模式(10) - 无参考实现(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| context 缺 REQUIRED 字段 | BLOCKED | 拒绝执行 |
| planning 缺失 | DEGRADED | 标注"⚠️ 无规划" |
| design 未全部 resolve | DEGRADED | 降级生成 |
| 代码已存在 | DEGRADED | 标注 [已存在] |
| 需新增依赖 | DEGRADED | 标注 TODO |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 展示改动范围（文件清单+预估行数） |
| Execute 后 | 展示代码摘要 |

## Resume
- 支持: true
- 方式: state.json

## State
- 读: state.json / knowledge.json / graph.json
- 写: state.json（追加 history）

## Artifacts
- 入: [knowledge, context, graph, planning, design]
- 出: [implementation]
