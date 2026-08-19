# Output Quality Scorecard v1.0

> 评估 Skill 产出质量的标准化评分卡。由 workflow-protocol 或独立 Reviewer 填写。
> yao-meta-skill Governed 模式要求。

## Scorecard Template

| Dimension | Weight | Score (0-100) | Evidence |
|-----------|--------|---------------|----------|
| **Completeness** — all claimed dimensions covered | 25% | | |
| **Correctness** — facts match source (code, docs, contracts) | 25% | | |
| **Consistency** — no cross-file contradictions | 15% | | |
| **Structure** — follows project conventions, readable | 15% | | |
| **Actionability** — downstream consumers can use directly | 10% | | |
| **Confidence** — self-assessed confidence aligns with evidence | 10% | | |
| **Total** | 100% | | |

## Scoring Guidelines

| Score | Completeness | Correctness | Consistency |
|-------|-------------|-------------|-------------|
| 90-100 | All claimed outputs present and verified | All assertions verified against source | Zero contradictions |
| 70-89 | Minor gaps, marked with `[WARNING]` | ≤2 unverified assertions | ≤1 minor inconsistency |
| 40-69 | Significant gaps, missing sections | ≥3 unverified or wrong assertions | Multiple contradictions |
| <40 | Major sections missing | Fundamental errors | Self-contradictory |

## Governed Thresholds

| Mode | Min Score | Action if Below |
|------|-----------|-----------------|
| Scaffold | 40 | No action required |
| Production | 70 | Review recommended |
| Governed | 85 | **Block downstream consumption** |

## Skill Instance

Replace `<skill-name>` and `<date>` when filling:

```markdown
# Output Quality Scorecard: <skill-name>

> Date: <ISO-8601> | Reviewer: <agent/name> | Mode: Governed

## Scores

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Completeness | | |
| Correctness | | |
| Consistency | | |
| Structure | | |
| Actionability | | |
| Confidence | | |
| **Total** | | |

## Findings

| # | Severity | Dimension | Description |
|---|----------|-----------|-------------|
| 1 | | | |

## Verdict

- [ ] PASS (≥85) — approved for downstream consumption
- [ ] NEEDS_FIX (70-84) — fix issues, re-score
- [ ] REJECT (<70) — re-do

## Missing Evidence

Items from yao-meta-skill Governed Package Boundary not yet available:
- [ ] telemetry: `missing evidence`
- [ ] approvals: `missing evidence`
- [ ] metrics: `missing evidence`
- [ ] benchmarks: `missing evidence`
```
