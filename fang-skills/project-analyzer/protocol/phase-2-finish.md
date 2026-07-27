# Phase 2: 收尾

维度 agent 全部完成后执行：

1. 目录初次运行时全部创建：`architecture/` `components/` `api/` `patterns/` `observations/` `proposals/` `reports/` `rules/` `experience/` `playbooks/` `decisions/`
2. 根据分析发现填充各目录，有内容才建文件。详见 [prompts/output-format.md](../prompts/output-format.md)
3. 每个 `.md` 文件包含 Evidence Header。详见 [prompts/output-format.md](../prompts/output-format.md)
4. 准备 `graph.json`、`statistics.json`、`search-index.json` 数据
5. 非首次运行：对比标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`
6. 统一写入固定产出：`manifest.json` `statistics.json` `search-index.json` `graph.json` `index.md`
7. 若 `analysis-config.json` 中 `output` 含 `"vault"`，同步 `.project-knowledge/` 到 Knowledge Vault：
   ⚠️ 此步骤至关重要 — 遗漏将导致 Vault 无最新分析结果。同步策略：本地为权威源 → 单向同步到 Vault。
   1) 从 `analysis-config.json` 读取 `vaultPath`，目标目录：`{vaultPath}/Projects/{projectName}/`
   2) 同步所有 `.md` 文件到 Vault（覆盖同名，新增本地独有的）
   3) 保留 Vault 独有文件（Vault 中有但本地没有的，不删除不覆盖）
   4) 同步结构化 JSON：`manifest.json` `analysis-config.json` `graph.json` `statistics.json` `search-index.json`
   5) `graph.json`：补充本次新发现的组件/模块节点和关系边
   6) `statistics.json`：刷新为最新数字
   7) `search-index.json`：补充新关键词索引条目
   8) 验证：`find "{vaultPath}/Projects/{projectName}/" -type f | wc -l` 与本地文件数对比
   9) 首次同步：全量写入；`graph.json`/`statistics.json`/`search-index.json` 从零生成；创建人工维护目录 `index.md`
   10) 增量同步：覆盖已变更 + 新增 + 保留 Vault 独有；增量更新（加节点/刷新数字/加索引）；不覆盖人工维护目录
8. 产出验证（每个文件必过）：
   1) 每个 `.md` 有 Evidence Header（id/generatedBy/generatedAt/last_scan/lifecycle/confidence/sources）
   2) 每个结论有 `file:line` 引用，无编造内容
   3) 固定产出 JSON（manifest/statistics/graph/search-index）schema 校验通过
   4) `index.md` 导航链接全部可达
   5) 若验证失败 → 标注 `⚠️` 并记录到 manifest，不阻塞完成
9. 检查/创建 `.claude/CLAUDE.md`
10. 报告摘要 → manifest `status` → `completed`
