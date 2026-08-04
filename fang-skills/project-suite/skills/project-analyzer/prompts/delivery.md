# Delivery — Analyzer

> @engine: delivery

## Actions

4-Phase 执行 → 详细步骤：[references/finish-workflow.md](../references/finish-workflow.md)

| Phase | 做什么 | 触发条件 |
|-------|--------|---------|
| **A** 强制刷新 | `statistics.json` / `context.json` / `graph.json` / `search-index.json` 必定重新生成。⚠️ **禁止复用缓存数字**，必须从本次扫描数据重新提取 | 每次扫描 |
| **B** 状态初始化 | 创建或追加 `.project-runtime/`（state.json + knowledge.json） | 首次/每次 |
| **C** 差异化更新 | 写 `.md` + manifest + index，仅 `[CHANGED]` 维度 | 内容变化 |
| **D** 质量验证 | `knowledge-health` 检查 + `CLAUDE.md` 更新（统计数字必须为最新值）+ Knowledge Vault 同步 + timeline 写入 | 每次扫描 |

### Phase D 详细规则

- **CLAUDE.md 更新**：统计数字（源文件数/行数/组件数/API数）必须与本次扫描一致
- **Vault 同步**：同步后验证本地与 Vault 文件数差异，>3 时标注 `⚠️ Vault 文件数差异: N`
- **timeline 写入**：追加到 `timeline.json`
- **manifest 完整性**：校验所有 subtask 有 status + fixedOutputs 全部存在，才置 `completed`

## Exit

- `manifest.status` = `completed`
- `CLAUDE.md` 统计数字已更新
- Vault 同步验证通过（文件差 ≤3）
- `timeline.json` 已追加本次执行记录

## Failure

| Condition | Action |
|-----------|--------|
| `graph.json` 生成失败（jq 不可用/JSON 格式错误） | grep + 纯文本解析回退 → 标注 `⚠️ graph.json 未生成`，不影响其他产出 |
| Knowledge Vault 路径不可达 | 跳过 Vault 同步 → 标注 `⚠️ Vault 不可达`，`.project-knowledge/` 仍正常写入 |
| `CLAUDE.md` 不存在 | 从 `package.json` + `tsconfig.json` 推断路径别名/命名空间 → 标注 `⚠️ 无 CLAUDE.md` |
| 写入文件失败（权限/磁盘满） | 重试一次 → 仍失败标注 `❌ FAILED: [原因]`，不阻塞其他产出 |
