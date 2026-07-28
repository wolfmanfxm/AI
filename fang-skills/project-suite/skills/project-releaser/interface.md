# Interface: project-releaser

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Release** — `CHANGELOG.md` + `RELEASE-CHECKLIST.md`

## Consumes
- 🔴 **Documentation**（`CHANGELOG.md` + git log 变更历史，缺失则从 conventional commits 生成）
- 🟡 **Review**（`REVIEW.md`，确认审查状态）

## Guarantees
- 版本号从 conventional commits 推导（breaking→MAJOR / feat→MINOR / fix→PATCH）
- Changelog 从 git log + PR + REVIEW.md 合成
- Breaking Change 显式标注 + 迁移步骤
- **不执行** `npm publish` / `git push --tags`

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 无 conventional commits | DEGRADED | 按 commit 首词推断，标注"⚠️ 非标准 commit" |
| 无法确定版本号 | DEGRADED | 读 `package.json` 当前版本建议小版本 bump |
| 无 REVIEW.md | DEGRADED | 标注"⚠️ 未审查" |
