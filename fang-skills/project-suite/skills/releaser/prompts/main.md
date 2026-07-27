# Main Prompt — Releaser

> 入口 prompt。按发布步骤依次执行：检查→版本→Changelog。

## 发布流程

```
发布前检查 → 版本号推荐 → Changelog 生成 → 发布就绪
```

## 路由规则

| 步骤 | 路由到 |
|------|--------|
| 只做版本号推荐 | [version-bump.md](version-bump.md) |
| 只生成 Changelog | [changelog-gen.md](changelog-gen.md) |
| 只做发布检查 | [release-checklist.md](release-checklist.md) |
| 完整发布流程 | 全部三个，按序执行 |

## 前置要求

1. 确认当前版本（`git describe --tags` 或 `package.json` version）
2. 收集 git log（上次 release tag 到 HEAD）
3. 收集 PR 列表 + REVIEW.md + TEST-REPORT.md（若存在）

## 要求

遵循 SKILL.md 中的完整工作流。不执行 `npm publish` / `git push --tags`。
