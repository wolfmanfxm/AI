# Interface: project-releaser

> 标准化接口契约。Artifact types 与 `artifact-types.yaml` 对齐。

## Produces
- **release** — `CHANGELOG.md` + `RELEASE-CHECKLIST.md`

## Consumes
| artifact | 优先级 | 缺失行为 |
|----------|--------|---------|
| documentation | 🔴 | DEGRADED — 从 git log 生成 |
| review | 🟡 | DEGRADED — 标注"⚠️ 未审查" |

## Input
| 字段 | 来源 | 必须 |
|------|------|------|
| git log | git | 🔴 |
| CHANGELOG.md | documenter | 🟡 |
| REVIEW.md | reviewer | 🟡 |

## Output
- `CHANGELOG.md` — 从 conventional commits + PR + REVIEW 合成
- `RELEASE-CHECKLIST.md`
- `result.md`

## Confidence
- 最低: 70%
- 计算: 100 - 非标准commit(15) - 无review(10) - breaking change无说明(15)

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 无 conventional commits | DEGRADED | 按首词推断 |
| 无法确定版本号 | DEGRADED | 建议 PATCH bump |
| review 缺失 | DEGRADED | 标注"⚠️ 未审查" |

## Checkpoint
| 位置 | 触发条件 |
|------|---------|
| Discover 后 | 展示版本建议 + Changelog 预览 |

## Resume
- 支持: false（每次独立执行）

## State
- 读: state.json
- 写: state.json（追加 history）

## Artifacts
- 入: [documentation, review, test]
- 出: [release]
