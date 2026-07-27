# Anti-Patterns — Releaser

> 执行 releaser 时的禁止操作。

## 通用反例

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 执行 `npm publish` / `git push --tags` | 只建议，不执行发布命令 |
| 2 | 跳过发布检查直接建议版本号 | 先检查，再 bump |
| 3 | Breaking Change 不写迁移步骤 | 必须写清楚：旧的是什么、新的怎么改 |
| 4 | Changelog 按 git log 原样输出 | 转译为用户友好的描述 |
| 5 | 编造不存在的 PR 或 issue 引用 | 没有 PR 就不写 `(#NNN)` |
| 6 | 测试失败还建议发布 | 测试不通过 → 🔴 阻断 |

## 版本号反例

| # | 反模式 | 正确做法 |
|---|--------|---------|
| 1 | 一个 fix 就 bump MAJOR | fix = PATCH，除非标注了 BREAKING |
| 2 | 多个新功能只 bump PATCH | feat = MINOR |
| 3 | 0.x 版本严格遵守 semver | 0.x 可以宽松，MINOR 允许 Breaking |

## Changelog 反例

| # | 反模式 | 正确做法 |
|---|--------|---------|
| 1 | "修复了一些 bug" | 具体："修复表格筛选条件重置后分页不更新" |
| 2 | 技术实现细节替代用户可见变化 | 写用户视角："搜索支持模糊匹配"不是"SQL 改用 ILIKE" |
| 3 | 把 `refactor:` 放到 🚀 Features | refactor 不放 Features，放 Maintenance |
