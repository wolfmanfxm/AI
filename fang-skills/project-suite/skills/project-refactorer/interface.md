# Interface: project-refactorer

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **RefactoredCode** — 重构后代码 + `reports/REFACTOR.md`

## Consumes
- 🔴 **Code**（待重构代码，缺失则 BLOCKED）
- 🟡 **Test**（现有测试，缺失则 DEGRADED）
- 🟡 **KnowledgeBase**（`.project-knowledge/patterns/`，缺失则 DEGRADED）

## Guarantees
- 重构前后外部行为完全一致
- 小步提交：每步 1 个动作，可独立回滚
- 改善可量化（圈复杂度/行数/lint）
- 有测试跑测试，无测试先加表征测试

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 被测代码不可读 | BLOCKED | 拒绝执行 |
| 无现有测试且无法加表征测试 | DEGRADED | 只做机械变换，标注"⚠️ 部分无测试保护" |
| 重构后测试变红 | DEGRADED | `git revert` 回滚，记录 REFACTOR.md |
