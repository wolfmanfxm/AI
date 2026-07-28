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
- 最低: 70%
- 计算: 100 - 源码不可达(30) - 维度agent失败(10/维度) - 推断内容比例(5/10%)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 源码不可读 | BLOCKED | 终止 |
| 维度 agent 失败 | DEGRADED | 该维度标记 failed |
| vaultPath 不可达 | DEGRADED | 跳过 Vault 同步 |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 确认项目名/深度/范围/输出位置 |

## Resume
- 支持: true
- 方式: manifest.json（checkpoint 协议）

## State
- 读: manifest.json
- 写: knowledge.json（全部初始标记 draft）

## Artifacts
- 入: [implementation]
- 出: [knowledge, context, graph]
