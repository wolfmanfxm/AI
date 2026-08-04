# Delivery — Documenter

> @engine: delivery

## Actions

1. **写入文件**：按文档类型路由
   - API 文档 → `api/<module>.md`
   - 组件文档 → `components/<name>.md`
   - README → `README.md`
   - Changelog → 参考 releaser
2. **Vault 同步** → [vault-sync](../../../shared/conventions/vault-sync.md)
   - ✅ API 文档、组件文档 → 同步到 Knowledge Vault
   - ❌ README、Changelog → 不同步
3. **文档新鲜度检查**（可选，在 analyzer 增量后执行）：
   - 读 manifest → 变更文件列表 → 交叉命中文档 `sources` 字段
   - 标注 `[OUTDATED]` / `[MATCH]` / `[NEW]`

## Exit

- 文档文件写入成功
- API/组件文档 Vault 同步验证通过
- state.json 更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
| Vault 不可达 | 跳过同步 → 标注 `⚠️ Vault 不可达` |
