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
- `result.md`

## Confidence
- 最低: 70%
- 计算: 100 - 无测试保护(20) - 重构范围大(10) - 逻辑复杂(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| implementation 不可读 | BLOCKED | 拒绝执行 |
| test 缺失且无法加表征测试 | DEGRADED | 只做机械变换 |
| 重构后测试变红 | DEGRADED | git revert 回滚 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 确认重构范围 + 测试覆盖状态 |

## Resume
- 支持: true
- 方式: git revert（小步提交可回滚）

## State
- 读: state.json
- 写: state.json（追加 history）

## Artifacts
- 入: [implementation, test, knowledge, review]
- 出: [refactored-code]
