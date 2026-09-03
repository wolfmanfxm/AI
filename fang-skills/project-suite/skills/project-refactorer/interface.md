# Interface: project-refactorer

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **refactored-code** — 重构后代码 + `reports/REFACTOR.md`

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| implementation | 🔴 | BLOCKED |
| test | 🟡 | DEGRADED — 无测试保护不重构 |
| knowledge | 🟡 | DEGRADED |
| review | 🟡 | SKIP |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| 待重构代码 | 用户指定 | 🔴 |
| 现有测试 | tester | 🟡 |
| .project-knowledge/patterns/ | analyzer | 🟡 |

## Output
- 重构后代码（行为不变）
- `reports/REFACTOR.md` — 变更清单 + 改善指标 + 测试结果
- `REFACTOR.md`

## Confidence
- 计算: 100 - 无测试保护(20) - 重构范围大(10) - 逻辑复杂(10)

