# Stage Template: Code Audit

> Suite 拥有（Protocol）。现状探查 — Skill 通过 `@template: code-audit` 引用。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | Discovery 完成，范围/Goal 已确认 |
| Input  | 项目源码 + Discovery 阶段确认的范围 |
| Output | 现状标注结果（`[新][有骨架][基本完成][已完成]`）+ 修正后估时 |
| Recovery | 读 manifest.json → 若已标注 → 跳过，直入 CHECKPOINT |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 标注方法 + 范围 |
| **Exit**    | 用户确认现状标注 + 修正估时 |
| **Failure** | 源码不可读/路径不一致等场景 |

## CHECKPOINT

现状探查完成后必须 CHECKPOINT — 用户确认标注结果后才能进入 Execution。

## 示例：Planner 的现状探查

```markdown
### Stage: Code Audit
@template: code-audit

| Actions  | 标注 `[新][有骨架][基本完成][已完成]`，修正估时 |
| Exit     | 用户确认现状标注 + 修正后估时 |
| Failure  | API 文档路径与代码不一致 → 标注 `⤳ 待确认`; 上游 PLAN 过期 → 重新探查 |
```
