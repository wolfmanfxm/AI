# Discovery — Releaser

> @engine: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：查询已有 decisions/risks → 检查是否有未 resolve 的决策影响发布
1. 读 `git log` → 解析 conventional commits（feat/fix/refactor/docs/breaking change）
2. 读 `CHANGELOG.md`（若存在）→ 确定追加或新建
3. 读 `REVIEW.md`（若存在）→ 确认审查状态
4. CHECKPOINT — 展示 commit 解析结果 + 现有 CHANGELOG + 审查状态

## Exit

- commit 历史已解析（类型分布统计）
- 现有 CHANGELOG 状态已知
- 审查状态已知

## Failure

| Condition | Action |
|-----------|--------|
| `git log` 无 conventional commits | 按 commit 首词推断类型（feat→MINOR, fix→PATCH），标注 `⚠️ 非标准 commit` |
| 无历史 tag | 从 `package.json` 读当前版本，推荐 `1.0.0` 为首个正式版 |
| `REVIEW.md` 不存在 | 标注 `⚠️ 未审查`，不阻塞 |

## CHECKPOINT

🔴 CHECKPOINT
