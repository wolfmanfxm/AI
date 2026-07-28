# Interface: project-documenter

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **documentation** — API/组件/Changelog 文档（`.md` + Evidence Header）

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| implementation | 🔴 | BLOCKED |
| review | 🟡 | SKIP |
| knowledge | 🟢 | SKIP — 无则默认风格 |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| 源码文件 | generator | 🔴 |
| REVIEW.md | reviewer | 🟡 |
| .project-knowledge/ | analyzer | 🟢 |

## Output
- API/组件文档（含 Evidence Header + `file:line`）
- `result.md`

## Confidence
- 最低: 60%
- 计算: 100 - 源码不可读(20) - JSDoc缺失(15) - 无风格参考(10)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 源码不可读 | DEGRADED | 标注跳过 |
| 无风格参考 | DEGRADED | 默认模板 |
| 文档已存在 | DEGRADED | 增量更新，不覆盖人工章节 |
| content 冲突 | DEGRADED | 标记 [CONFLICT] |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 确认文档类型 + 范围 |
| Execute 后 | 展示文档预览 |

## Resume
- 支持: true
- 方式: state.json

## State
- 读: state.json
- 写: state.json（追加 history）

## Artifacts
- 入: [implementation, review, knowledge, context]
- 出: [documentation]
