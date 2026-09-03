# Interface: project-analyzer

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **knowledge** — `.project-knowledge/`
- **context** — `context.json`
- **graph** — `graph.json`

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| implementation | 🔴 | BLOCKED |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| 项目源码 | 工作目录 | 🔴 |
| 分析范围 | User Prompt | 🟡 |

## Output
- `.project-knowledge/` — 架构/组件/API/模式/观察
- `context.json` — 技术栈/别名/约定/模块清单
- `graph.json` — 节点+边关系图谱
- `manifest.json` — 执行状态追踪

## Confidence
- 计算: 100 - 源码不可达(30) - 维度agent失败(10/维度) - 推断内容比例(5/10%)

