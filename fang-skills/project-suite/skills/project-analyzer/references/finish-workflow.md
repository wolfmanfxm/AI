# Finish Workflow — 详细执行步骤

> 此文件包含 analyzer Finish 4-Phase 的完整执行指引。SKILL.md 保留摘要 + 引用。

> **调用方**（本文件此前**零个 stage 引用** = 孤儿规格，2026-09-30 接线）：
> - **Phase A + B** ← [delivery.md](../prompts/delivery.md) **Action 0**（每次交付强制刷新根 JSON）
> - **Phase C** ← Delivery Action 7（写 manifest + state）
> - **Phase D 的契约门禁（第 16 步）** ← Delivery Action 6 + [validation.md](../prompts/validation.md) V7
>
> 本文件**不是独立 stage**（[skill.yaml](../skill.yaml) 的 `stages` 里没有 `finish`）——
> 它是 Delivery 的执行细节。规格写在没有调用方的文件里 = 没有生效的规格。

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

## Phase B — .project-knowledge/runtime/ 初始化或更新

5. 检查 `.project-knowledge/runtime/` 目录：不存在 → 按 `runtime/state/state.md` 创建（`state.json` + `knowledge.json` + `metrics/`）；已存在 → 追加本次执行记录
6. **state.json** — 写入 `{ current: { skill, started }, history: [...] }`，含 confidence + suggested_next
7. **knowledge.json** — 扫描 `.project-knowledge/` 每个文件：新文件 → Candidate；occurrences ≥3 → 保持 Candidate（达到晋升阈值，**不自动 Accepted**）；真正 Accepted 由 Reviewer/promotion-reviewer 按 [promotion-rules.md](../../../runtime/state/schemas/promotion-rules.md) 验证后更新

## Phase C — 差异化更新

仅内容变化时写入。

8. 写 `.md`（Evidence Header），仅对 `[CHANGED]` 维度
9. 非首次：标记 `[NEW]/[CHANGED]/[CONFIRMED]`
10. 写 `manifest.json` `index.md`
11. manifest 完整性校验：mode/scope/dimensions/files/executionLog 与实际一致，若被外部进程篡改则以本次参数覆盖

## Phase D — 质量验证与同步

12. **knowledge-health.json** — 逐项执行以下检测，将结果写入 `.project-knowledge/runtime/metrics/knowledge-health.json`：

   a. **broken_link** — 扫描所有 `.md` 中的 `[text](path.md)` → 检查目标文件是否存在。任一不存在 → error。
   b. **empty_document** — `wc -c < file.md`，< 200 bytes → warning。
   c. **duplicate_content** — 比较所有 `.md` 的 `# 标题`（大小写归一），完全相同的标题 → warning。
   d. **evidence_freshness** — 读 Evidence Header `generatedAt`，距今 > 90 天 → warning（证据新鲜度，≠ 知识可信度衰减 decay）。
   e. **missing_evidence_header** — 文件前 5 行无 `generatedAt:` → warning（`index.md` 豁免）。
   f. **large_file** — `wc -l` > 500 → info。

   error > 0 → manifest 标注 ⚠️；warning > 5 → context.json 标注 ⚠️。**不阻断。**

   > **为什么这些不阻断**：broken_link / empty_document / duplicate_content 是**知识质量**信号——
   > 真实知识库长期处于「有已知质量问题但可用」的状态，把知识质量变成硬拦截会让每个真实项目都跑不完。
   > 这与契约对 `statement` 合规率 0/12 的处理同理：**差距是要被记录的事实，不是要被硬拦的错误**。
   > 但下一节的「契约完整性」不是知识质量问题，而是「产出是否成型」——那里必须阻断。
13. CLAUDE.md 统计数字更新 — 读第一行，替换为 statistics.json 最新源文件数+代码行数
14. Vault 同步 + 验证 — rsync → 对比文件数差异，>3 → 标注 `⚠️ Vault sync gap`
15. 写 timeline.json
16. **契约完整性门禁（🔴 阻断）**

    ```bash
    bash shared/scripts/check-kb-contract.sh .project-knowledge
    ```

    断言契约声明的**全部目录** + **6 个固定根产物**在位（清单从契约派生，不硬编码）。

    Exit 0 → 继续；**Exit 1 → 不得执行第 17 步**，按 `.project-knowledge/kb-contract-report.md`
    的缺失清单补齐后重跑门禁。

    > **为什么与上一节相反**：目录 / 根产物缺失 = 知识链**结构性**断裂（下游按目录读取会直接读空），
    > 不存在「有质量问题但可用」的中间态。此前本文件对契约完整性**无任何检查**，且 Phase D 统一写
    > 「不阻断」——实测结果是 13/14 契约目录缺失仍能走到第 17 步声明 `status: completed`。
    > **一个不阻断的门禁等于没有门禁。**
17. manifest status → completed
