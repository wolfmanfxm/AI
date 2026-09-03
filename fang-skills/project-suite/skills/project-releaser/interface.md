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
- `CHANGELOG.md` + `RELEASE-CHECKLIST.md`

## Confidence
- 计算: 100 - 非标准commit(15) - 无review(10) - breaking change无说明(15)

