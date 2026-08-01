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
