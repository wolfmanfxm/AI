# Finish Workflow — 详细执行步骤

> 此文件包含 analyzer Finish 4-Phase 的完整执行指引。SKILL.md 保留摘要 + 引用。

## Phase A — 强制刷新机器可读产物

每次扫描必定执行，不等价于 markdown 是否 `[CHANGED]`。

1. **statistics.json** — 从 Wave 0-3 所有 agent 汇总数据：总文件数/行数、byLayer/byType 分布、模块 Top10、组件引用 Top10、API 方法数、质量指标
2. **context.json** — 从 statistics.json + architecture/ 提取：
   - `layers.files` 与 `statistics.byLayer` 对齐
   - `modules` 列表与最新模块目录对齐
   - `apiFunctionCount` 与 `statistics.topApiModules` 汇总对齐
   - `routeCount` 从 router 文件实际解析
   - ⚠️ **禁止复用旧 version/数字** — 每个字段必须从本次扫描数据重新提取
3. **graph.json** — 从 modules 列表重建节点：每个业务模块目录 → node，每个 `patterns/*.md` → node，新增模块自动追加，已删除自动移除，`dependsOn` 按 import 关系推导
4. **search-index.json** — 扫描全部 `.md` 提取关键词（组件名/API 函数名前缀/模式名），目标条目数 `min(80, 模块数×3 + 组件数×1 + API模块数×2)`，⚠️ 禁止只复制旧 index

## Phase B — .project-runtime/ 初始化或更新

5. 检查 `.project-runtime/` 目录：不存在 → 按 `runtime/state/state.md` 创建（`state.json` + `knowledge.json` + `metrics/` + `artifacts/`）；已存在 → 追加本次执行记录
6. **state.json** — 写入 `{ current: { skill, started }, history: [...] }`，含 confidence + suggested_next
7. **knowledge.json** — 扫描 `.project-knowledge/` 每个文件：新文件 → Candidate；occurrences ≥3 → Accepted

## Phase C — 差异化更新

仅内容变化时写入。

8. 写 `.md`（Evidence Header），仅对 `[CHANGED]` 维度
9. 非首次：标记 `[NEW]/[CHANGED]/[CONFIRMED]`
10. 写 `manifest.json` `index.md`
11. manifest 完整性校验：mode/scope/dimensions/files/executionLog 与实际一致，若被外部进程篡改则以本次参数覆盖

## Phase D — 质量验证与同步

12. **knowledge-health.json** — 逐项执行以下检测，将结果写入 `.project-runtime/metrics/knowledge-health.json`：

   a. **broken_link** — 扫描所有 `.md` 中的 `[text](path.md)` → 检查目标文件是否存在。任一不存在 → error。
   b. **empty_document** — `wc -c < file.md`，< 200 bytes → warning。
   c. **duplicate_content** — 比较所有 `.md` 的 `# 标题`（大小写归一），完全相同的标题 → warning。
   d. **outdated_evidence** — 读 Evidence Header `generatedAt`，距今 > 90 天 → warning。
   e. **missing_evidence_header** — 文件前 5 行无 `generatedAt:` → warning（`index.md` 豁免）。
   f. **large_file** — `wc -l` > 500 → info。

   error > 0 → manifest 标注 ⚠️；warning > 5 → context.json 标注 ⚠️。不阻断。
13. CLAUDE.md 统计数字更新 — 读第一行，替换为 statistics.json 最新源文件数+代码行数
14. Vault 同步 + 验证 — rsync → 对比文件数差异，>3 → 标注 `⚠️ Vault sync gap`
15. 写 timeline.json
16. manifest status → completed
