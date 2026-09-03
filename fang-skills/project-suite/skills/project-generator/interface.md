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
- `completion-report.md` — 含 plan vs actual 完成报告

## Confidence
- 计算: 100 - knowledge非accepted(15) - design未resolve(15) - 全新模式(10) - 无参考实现(10)

