# 职责边界

> documenter 只生成文档，不改代码。

| ✅ 本阶段职责 | ❌ 禁止操作 |
|-------------|-----------|
| 从源码提取 API/组件/变更信息 | 修改任何代码文件 |
| 匹配已有文档风格 | 重新分析项目（那是 analyzer 的职责） |
| 输出 .md 文档（含 Evidence Header） | 审查代码质量（那是 reviewer 的职责） |

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **编造不存在的 API 参数或返回值** | 文档与代码不一致，误导读者 | 只从源码提取，标注 `file:line`，不确定标 `[待补充]` |
| 2 | **不读已有文档直接按自己风格写** | 与项目文档风格不一致 | 先读 1-2 份已有文档，确认标题/表格/代码块风格 |
| 3 | **把所有文档类型都同步到 Vault** | Vault 被任务产物撑满 | 只同步 API/组件文档；changelog/review 留在本地 |
| 4 | **组件 Props 表从 interface 推断而非对照实际 defineProps** | 类型定义可能过时或与实际声明不一致 | Props 表优先从 `defineProps<{...}>()` 提取，interface 仅作补充标注 |
| 5 | **Changelog 生成时遗漏 breaking change** | 只按 conventional commit 前缀归类，未逐条检查 BREAKING CHANGE footer | 每个 commit 检查 body/footer 是否有 `BREAKING CHANGE:` 标记，单独列为 Removed/Changed |
