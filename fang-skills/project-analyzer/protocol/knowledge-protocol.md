# Knowledge Protocol

## 数据文件

| 文件 | Schema | 写入者 | 写入时机 | 修改？ |
|------|--------|--------|---------|--------|
| `analysis-config.json` | [schema/analysis-config.schema.json](../schema/analysis-config.schema.json) | Phase 1 | 用户确认后 | 否（此后只读） |
| `manifest.json` | [schema/manifest.schema.json](../schema/manifest.schema.json) | Phase 1, 2.3, Resume | 配置确认 / 状态变更 / 完成 | 是 |
| `statistics.json` | [schema/statistics.schema.json](../schema/statistics.schema.json) | Phase 2.3 | 分析完成 | 是（每次覆盖） |
| `graph.json` | [schema/graph.schema.json](../schema/graph.schema.json) | Phase 2.2 | 各维度完成后 | 是（每次覆盖） |
| `search-index.json` | — | Phase 2.3 | 分析完成 | 是（每次覆盖） |

## 版本规范

每个 JSON 文件顶层包含：

```json
{
  "schemaVersion": "1.0",
  ...
}
```

manifest.json 额外包含：

```json
{
  "knowledgeVersion": "1.0.0",
  "schemaVersion": "1.0",
  "generatedBy": "project-analyzer",
  ...
}
```

**knowledgeVersion**：全量刷新时递增（major.minor.patch）。incremental 更新不递增。用于判断知识库新旧。

**schemaVersion**：Schema 文件版本。读取方据此选择解析器，保证升级兼容。

### 预留字段

`knowledgeCompatibility`：当前仅有 project-analyzer 一个读写方，暂不启用。将来出现多个消费者且版本不同时，在 manifest.json 中添加此字段声明兼容范围（如 `"compatibility": ">=2.0"`），供旧版本消费者判断是否可安全读取。

## 使用原则

- Analyzer（写入方）：按 schema 生成，不编造字段
- Refresh（更新方）：读 schema 确认字段含义，按协议回写
- Validator（校验方）：用 schema 验证 JSON 合法性
- Develop（消费方）：读 protocol 理解数据语义，读 schema 确认字段类型
