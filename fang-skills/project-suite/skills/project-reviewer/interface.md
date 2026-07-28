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
- `result.md`

## Confidence
- 最低: 50%
- 计算: 100 - 变更量大(15) - 不熟悉技术栈(15) - AC不可验证(10) - 上下文不足(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| implementation 不可读 | BLOCKED | 拒绝执行 |
| 变更文件 > 20 | DEGRADED | 只审查核心文件 |
| AC 不可验证 | DEGRADED | 标注 [需确认] |
| 不熟悉的框架 | DEGRADED | 仅通用检查 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| 审查范围确认后 | 展示审查范围 + graph 影响分析结果 |

## Resume
- 支持: true
- 方式: state.json

## State
- 读: state.json / knowledge.json / graph.json
- 写: state.json（追加 history）

## Artifacts
- 入: [implementation, planning, knowledge, design, test]
- 出: [review]
