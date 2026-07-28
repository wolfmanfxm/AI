# Knowledge Lifecycle

## 状态转换

```
draft → confirmed → deprecated → archived
  ↓         ↓
  └─────────┘ (re-analyzed: overwrite)
```

## 状态说明

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| `draft` | 初稿，待人工确认 | 首次自动生成 |
| `confirmed` | 已确认，内容准确 | 增量扫描确认无变化，或人工标记 |
| `deprecated` | 已废弃，不再维护 | 对应代码已删除或重构 |
| `archived` | 已归档，历史参考 | 旧版本文档保留 |

## 状态升级规则

- `draft → confirmed`：增量扫描确认 `last_scan` 时间戳在源码最后修改时间之后，且内容无需更新
- `draft → deprecated`：对应源文件已被删除，且无替代
- `draft/confirmed → archived`：手动归档（人工操作）
- 重新分析时：`deprecated` 文档若检测到新源码 → 覆盖为 `draft`

## confidence 与 lifecycle 的关系

| confidence | 典型 lifecycle | 含义 |
|-----------|---------------|------|
| 90-99 | confirmed | 统计事实，可自动确认 |
| 70-89 | draft | 模式推断，建议人工复核 |
| 50-69 | draft | 人工标注，低置信度 |
