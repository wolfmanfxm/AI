# Interface: project-reviewer

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **review** — `reports/REVIEW-<topic>.md`（五轴审查 + AC 对照）

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| implementation | 🔴 | BLOCKED — 拒绝执行 |
| planning | 🔴 | DEGRADED — 标注"⚠️ 无验收标准" |
| graph | 🔴 | DEGRADED — 跳过影响分析 |
| knowledge | 🟡 | DEGRADED — 标准审查 |
| design | 🟡 | SKIP |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| 变更 diff | User / git | 🔴 |
| PLAN.md > # Acceptance Criteria | planner | 🔴 |
| PLAN.md > # Risk Assessment | planner | 🔴 |
| PLAN.md > # Scope | planner | 🔴 |
| graph.json | analyzer | 🔴 |

## Output
- `reports/REVIEW-<topic>.md` — 分级问题 + AC 逐条对照 + 审查强度
- `state.json` — 追加 history
- `REVIEW-<topic>.md`

## Confidence
- 计算: 100 - 变更量大(15) - 不熟悉技术栈(15) - AC不可验证(10) - 上下文不足(10)

