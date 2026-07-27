# Vault 同步协议

仅 analyzer 和 documenter（API/组件文档）使用此协议。

## 触发条件

`analysis-config.json` 中 `output` 数组含 `"vault"` 且 `vaultPath` 非空。

## 同步流程

1. 读 `analysis-config.json` → `vaultPath`
2. 目标目录：`{vaultPath}/Projects/{projectName}/`
3. `rsync -av --include='*/' --include='*.md' --include='*.json' --exclude='*' .project-knowledge/ "{vaultPath}/Projects/{projectName}/"`
4. 保留 Vault 独有文件（不删除不覆盖）
5. 验证：`find "{vaultPath}/Projects/{projectName}/" -type f | wc -l`

## 同步内容

| Skill | 同步文件 |
|-------|---------|
| analyzer | 全部 `.project-knowledge/`（architecture/components/api/patterns/observations/ + graph.json/statistics.json/search-index.json） |
| documenter | API 文档 + 组件文档（不包含 reports/CHANGELOG*.md） |

## Vault 目录

```
{vaultPath}/Projects/{projectName}/
├── index.md / manifest.json / analysis-config.json
├── graph.json / statistics.json / search-index.json
├── architecture/ components/ api/ patterns/ observations/
├── decisions/ rules/ experience/ playbooks/  ← 人工维护不覆盖
```
