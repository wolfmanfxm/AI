# Evidence Header Template

所有 skill 产出的 `.md` 文件使用以下 Frontmatter 模板：

```yaml
---
id: <unique-id>
generatedBy: <skill-name>
generatedAt: <ISO-8601-timestamp>
last_scan: <ISO-8601-timestamp>
lifecycle: Artifact
confidence: <0-100>
sources:
  - <source-file-path>
---
```

## 字段规范

| 字段 | 含义 | 示例 |
|------|------|------|
| `id` | 文档唯一标识，kebab-case | `architecture-overview` |
| `generatedBy` | 生成 skill 名 | `analyzer` `documenter` |
| `generatedAt` | 首次生成时间 | `2026-07-27T14:00:00Z` |
| `last_scan` | 最后校验时间 | 同上 |
| `lifecycle` | 生命周期（v2.0） | `Artifact` `Candidate` `Accepted` `Deprecated` |
| `confidence` | 置信度 0-100 | 95（统计事实） 75（模式推断） |
| `sources` | 证据源文件 | `src/api/user.ts` |
