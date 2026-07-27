# 失败处理

| 触发条件 | 一线修复 | 兜底 |
|---------|---------|------|
| git log 无 conventional commits | 按 commit message 首词推断 | 标注"⚠️ 非标准 commit" |
| CHANGELOG.md 格式不兼容 | 追加到末尾，标注分隔符 | 备份旧文件后重建 |
| 无法确定版本号 | 读 package.json 当前版本 | AskUserQuestion |
| 无 REVIEW.md | 跳过审查状态检查 | 标注"⚠️ 未审查" |
