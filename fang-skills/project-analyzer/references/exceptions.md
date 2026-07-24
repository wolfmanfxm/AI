# 异常处理

| 步骤 | 触发条件 | 一线修复 | 仍失败兜底 |
|------|---------|---------|-----------|
| 读 `package.json` | 不存在/解析失败 | 检查是否在根目录 | AskUserQuestion：输入框架名/跳过/自定义目录 |
| 探测目录结构 | find 空/权限拒绝 | 排除 node_modules/dist | AskUserQuestion：输入目录/降级ls/取消 |
| 统计命令 | 零匹配 | 扩大搜索范围 | 标注⚠️，不编造数据 |
| 读 Vault | 路径不可达 | 尝试本地 `.project-knowledge/` | AskUserQuestion：重输路径/仅本地/取消 |
| 组件引用计数 | 无结果 | 尝试 PascalCase + kebab-case | 标注"引用计数=0" |
| 增量扫描 | 本地副本为空 | 回退全量扫描 | 新建目录 + 全量 |
