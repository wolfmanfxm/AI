# 现状探查

> Discover 后、Execute 拆解前必做。跳过将导致严重高估或重复规划。

## 步骤

1. 从需求提取关键词，搜索代码：
   ```bash
   grep -r "关键词" workspace/router/ --include='*.ts'
   grep -r "关键词" workspace/api/ --include='*.ts'
   ls workspace/views/<关键词>/
   ```
2. 检查 `.project-knowledge/architecture/modules.md`
3. 检查 `.project-knowledge/components/catalog.md`

## 标注规则

| 标记 | 含义 | 估时调整 |
|------|------|---------|
| `[新]` | 无现有代码 | ×1.0 |
| `[有骨架]` | 路由/API 已有 | ×0.6 |
| `[基本完成]` | 核心已有，缺小功能 | ×0.2 |
| `[已完成]` | 代码完整 | 移除 |
