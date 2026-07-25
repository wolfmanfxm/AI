# Phase 2: 收尾

维度 agent 全部完成后执行：

1. 目录初次运行时全部创建：`architecture/` `components/` `api/` `patterns/` `observations/` `proposals/` `reports/` `rules/` `experience/` `playbooks/` `decisions/`
2. 根据分析发现填充各目录，有内容才建文件。详见 [prompts/output-format.md](../prompts/output-format.md)
3. 每个 `.md` 文件包含 Evidence Header。详见 [prompts/output-format.md](../prompts/output-format.md)
4. 准备 `graph.json`、`statistics.json`、`search-index.json` 数据
5. 非首次运行：对比标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`
6. 统一写入固定产出：`manifest.json` `statistics.json` `search-index.json` `graph.json` `index.md`
7. 检查/创建 `.claude/CLAUDE.md`
8. 报告摘要 → manifest `status` → `completed`
