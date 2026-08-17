# 职责边界

> releaser 只检查、建议、生成发布产物，不执行发布命令。

| ✅ 本阶段职责 | ❌ 禁止操作 |
|-------------|-----------|
| 版本号 bump 建议、changelog 合成 | 执行 `npm publish` / `git push --tags` |
| 发布前检查清单、回滚方案 | 直接操作远程仓库 |
| 输出 CHANGELOG.md + RELEASE-CHECKLIST.md | 修改业务代码 |

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **执行 `git push --tags` 或 `npm publish`** | releaser 只检查建议，不执行危险操作 | 生成检查清单，由人工或 CI 执行发布 |
| 2 | **不检查 breaking change 就建议版本号** | 可能建议错误的 semver bump | 从 conventional commits 解析，显式标注 BREAKING CHANGE |
| 3 | **changelog 手工编造条目** | 与 git log 不一致 | 从 git log + PR + REVIEW.md 自动合成 |
| 4 | **未检查 CI/Review 状态就标记发布就绪** | 测试未通过或有 BLOCKER 问题仍进入生产线 | RELEASE-CHECKLIST 必须逐项验证后才标记 ✅ |
| 5 | **回滚方案只写"git revert"无具体步骤** | 紧急回滚时不知道版本号、影响范围、验证方法 | 回滚方案含：回滚到的 commit hash + revert 命令 + 验证步骤（至少1条） |

## 失败兜底

| 触发条件 | 一线修复 | 兜底 |
|---------|---------|------|
| git log 无 conventional commits | 按 commit message 首词推断 | 标注"⚠️ 非标准 commit" |
| CHANGELOG.md 格式不兼容 | 追加到末尾，标注分隔符 | 备份旧文件后重建 |
| 无法确定版本号 | 读 package.json 当前版本 | AskUserQuestion |
| 无 REVIEW.md | 跳过审查状态检查 | 标注"⚠️ 未审查" |

## 常见借口（Common Rationalizations）

| # | LLM 会说的借口 | 为什么拒绝 |
|---|---------------|-----------|
| 1 | 「改动很小，PATCH 就行」 | → 仍然按 conventional commits 推导 |
| 2 | 「回滚很简单，git revert 就行」 | → 必须写具体命令+验证步骤 |
| 3 | 「REVIEW 里没有 BLOCKER，可以发布」 | → 仍然检查全链路 Confidence |
