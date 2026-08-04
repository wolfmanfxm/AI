# Review Cadence v1.0

> project-suite Skill 审查节奏定义。yao-meta-skill Governed 模式要求。

## 审查节奏

| 触发条件 | 审查范围 | 审查者 |
|----------|---------|--------|
| **SUITE_SPEC 版本 bump** | 全部 9 个 Skill | Dispatcher（人）+ Reviewer Agent |
| **每 90 天** | 单个 Skill（按 `last_reviewed` 排序） | Reviewer Agent |
| **Skill 自身版本 bump** | 该 Skill | Reviewer Agent |
| **新增 Skill** | 新 Skill | Dispatcher + 全部 Gate 检查 |

## 审查内容

每次审查检查：

1. **Contract 一致性**：SKILL.md 声明的能力与 skill.yaml `interface.produces` 一致
2. **Stage 完整性**：`stages:` 声明与 `prompts/<stage>.md` 一一对应
3. **反例有效性**：boundary.md / SKILL.md 的反例是否仍然适用（代码库可能已演进）
4. **触发词新鲜度**：trigger words 是否仍准确覆盖用户意图
5. **上游兼容性**：depends_on 的 skill 版本是否兼容

## skill.yaml 字段

每个 Skill 的 `skill.yaml` 中新增：

```yaml
last_reviewed: "2026-08-04"    # ISO-8601 date
review_cadence_days: 90        # 最大审查间隔
```

## 过期检测

`shared/scripts/check-conformance.sh` 的 G17 检查：

```
if now - last_reviewed > review_cadence_days:
  → WARNING: "Skill X 上次审查于 Y，已超过 Z 天，建议审查"
```

## 审查记录

审查完成后更新 `last_reviewed` 日期，commit message 格式：

```
review: project-analyzer — contract/stage/anti-pattern/trigger check passed
```
