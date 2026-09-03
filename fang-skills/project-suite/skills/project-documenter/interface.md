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
- 文档本身（含 Evidence Header）

## Confidence
- 计算: 100 - 源码不可读(20) - 注释缺失(15) - 无风格参考(10)

