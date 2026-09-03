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
- 计算: 100 - AC不可验证(15) - 被测代码复杂(10) - 无测试框架(10)

