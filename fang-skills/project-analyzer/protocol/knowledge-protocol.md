# Knowledge Protocol

## 版本控制

| 字段 | 位置 | 含义 | 变更规则 |
|------|------|------|---------|
| `knowledgeVersion` | manifest.json | 知识库版本号 | 全量刷新时递增主版本 |
| `schemaVersion` | manifest.json | Schema 版本 | 破坏性变更时递增 |
| `skillVersion` | manifest.json | 技能版本 | 跟随 SKILL.md 发布 |
| `gitCommit` | manifest.json | 关联的 git commit hash | 每次分析记录 |

## 固定产出字段定义

### manifest.json

```json
{
  "knowledgeVersion": "2.0",
  "skillVersion": "1.0.0",
  "generatedBy": "project-analyzer",
  "generatedAt": "ISO-8601",
  "project": "项目名称",
  "gitCommit": "abc1234",
  "lastScan": "ISO-8601",
  "sourceDirectories": ["src/", "workspace/"],
  "techStack": {},
  "status": "confirmed | in_progress | partial | interrupted | completed",
  "statistics": {
    "totalFiles": 0, "totalLines": 0,
    "components": 0, "modules": 0, "apiEndpoints": 0,
    "highConfidence": 0, "inferred": 0, "manual": 0
  },
  "files": { "dimension-name": ["file1.md", "file2.md"] }
}
```

### statistics.json

聚合仪表盘数据：组件计数、API 端点、模式分布、质量指标。详见 [schema/statistics.schema.json](../schema/statistics.schema.json)。

### graph.json

结构化关系图谱：组件 → 页面引用边、API → 调用者边、模块依赖。详见 [schema/graph.schema.json](../schema/graph.schema.json)。

### search-index.json

关键词 → 文件路径倒排索引，支持快速检索。详见模板 `templates/metadata/search-index.json`。

## 生命周期

文档生命周期状态定义见 [knowledge-lifecycle.md](knowledge-lifecycle.md)。
