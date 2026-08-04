# Delivery — Releaser

> @engine: delivery

## Actions

写入：
1. `CHANGELOG.md` — 按版本分组（Added/Changed/Fixed/Deprecated/Removed）
2. `RELEASE-CHECKLIST.md` — 逐项检查结果 + 回滚方案
3. 版本号推荐 — semver 版本号 + 推荐理由

**不执行** `npm publish` / `git push --tags` — 这些由人工执行。

## Exit

- `CHANGELOG.md` 写入成功
- `RELEASE-CHECKLIST.md` 写入成功
- 版本号推荐已呈现
- state.json 更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
