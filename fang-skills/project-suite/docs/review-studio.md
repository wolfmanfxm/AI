# Review Studio v1.0

> 结构化审查会话模板。记录每次 Skill 审查的发现和决策。
> yao-meta-skill Review Studio 要求。

## 审查会话模板

每次对 Skill 做审查时，填写以下模板并保存到 `reviews/<skill>-<date>.md`：

```markdown
# Review: <skill-name>

> Date: <ISO-8601> | Reviewer: <name/agent> | Type: scheduled / triggered / ad-hoc

## Scope

- [ ] Contract 一致性（SKILL.md vs skill.yaml）
- [ ] Stage 完整性（stages vs prompts/）
- [ ] 反例有效性（anti-patterns）
- [ ] 触发词覆盖（trigger words）
- [ ] 链接可达性（all references resolve）
- [ ] 上游兼容性（depends_on versions）
- [ ] Prompt 质量（self-assessment）
- [ ] 产出质量（quality scorecard）

## Findings

| # | Severity | Category | Description | Resolution |
|---|----------|----------|-------------|------------|
| 1 | | | | |

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | | |

## Gate Status

| Gate | Before | After | Action |
|------|--------|-------|--------|
| G1 | | | |
| ... | | | |

## Confidence Change

Before: XX → After: XX (Δ: ±X)

## Sign-off

- [ ] All findings resolved or waived
- [ ] quality_scorecard updated
- [ ] trust_report updated (if score changed)
- [ ] last_reviewed bumped in skill.yaml
```

## 审查触发

| Trigger | Action |
|---------|--------|
| SUITE_SPEC bump | 全量审查（10 skills） |
| Skill version bump | 单 Skill 审查 |
| G17 过期警告 | 单 Skill 审查 |
| 用户请求 `/review <skill>` | 单 Skill 审查 |
