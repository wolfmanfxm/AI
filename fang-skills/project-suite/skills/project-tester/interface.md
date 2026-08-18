# Interface: project-tester

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **test** — 测试文件（按项目测试框架）+ `reports/TEST-REPORT.md`

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| implementation | 🔴 | BLOCKED |
| planning | 🔴 | DEGRADED — 从代码推断 |
| knowledge | 🟡 | DEGRADED |
| design | 🟡 | SKIP |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| 被测代码 | generator | 🔴 |
| PLAN.md > # Acceptance Criteria | planner | 🔴 |
| PLAN.md > # Risk Assessment | planner | 🟡 |
| ARCHITECTURE.md | architect | 🟡 |

## Output
- 测试文件（按项目测试框架）
- `reports/TEST-REPORT.md` — 覆盖率 + AC 对照表
- `TEST-REPORT.md`

## Confidence
- 最低: 70%
- 计算: 100 - AC不可验证(15) - 被测代码复杂(10) - 无测试框架(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| implementation 不可读 | BLOCKED | 拒绝执行 |
| planning AC 缺失 | DEGRADED | 从代码推断 |
| 无测试框架 | DEGRADED | 默认 jest |
| 测试执行失败 | DEGRADED | 记录报告，不修改源码 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 确认测试范围 + 框架选择 |

## Resume
- 支持: true
- 方式: state.json

## State
- 读: state.json
- 写: state.json（追加 history）

## Artifacts
- 入: [implementation, planning, knowledge, context]
- 出: [test]
