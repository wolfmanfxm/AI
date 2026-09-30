# Delivery — Analyzer

> @template: delivery
> 契约门禁 + 双同步策略 — 先跑 Finish 刷新机器产物，过门禁，再按 promotion level 同步

## Actions

### 0. 强制刷新机器可读产物（Finish Phase A/B）

→ [finish-workflow.md](../references/finish-workflow.md) 的 **Phase A + Phase B**

`statistics.json` / `context.json` / `graph.json` / `search-index.json` **每次扫描必定重新生成**——
它不等价于 markdown 是否 `[CHANGED]`，也**不是可选步骤**。后面第 6 步的门禁会检查它们是否在位。

> ⚠️ **为什么把这一步显式写进 Delivery**（2026-09-30 修复）：`finish-workflow.md` 此前**零个 stage 引用**，
> 而它正是「4 个根 JSON 每次必定生成」的唯一规格来源。结果是实测有项目产出 0/5 根 JSON
> 却仍声明 `status: completed`——规格在，但没有任何阶段执行它。**孤儿规格 = 未生效的规格。**

### 1. 读取分类报告

读取 `.project-knowledge/classification-report.yaml`，按 promotion level 执行：

### 2. Project Sync（promotion: project — 自动同步）

所有 `promotion: project` 的文件 → rsync 到 Knowledge Vault：

```bash
rsync -av --exclude='proposals/' --exclude='reports/REVIEW-*' \
  --exclude='reports/CHANGELOG.md' --exclude='reports/RELEASE-CHECKLIST.md' \
  --exclude='decisions/ARCHITECTURE-*' \
  --exclude='candidates/' \
  .project-knowledge/ "{vaultPath}/Projects/{project}/"
```

→ [vault-sync.md](../../../shared/conventions/vault-sync.md)

### 3. Archive Task Artifacts（promotion: none — 仅保留本地）

`promotion: none` 的文件 → 仅写入 `.project-knowledge/`，**不执行任何同步**。

### 4. Knowledge Promotion（promotion: personal — Reviewer 确认）

`promotion: personal` 的 candidates → 展示给 Reviewer，确认后复制到 `{vaultPath}/Knowledge/`：

```
展示: "以下知识具有跨项目价值，是否 Promotion？"
  1. pattern.form-schema-validation (confidence: 0.85)
  2. playbook.microservice-migration (confidence: 0.78)

用户确认 → rsync 到 Vault/Knowledge/
```

### 5. Trigger Background Pipeline

StageCompleted 事件触发 → [background pipeline](../../../runtime/pipeline/background.yaml)：

```
Knowledge Scan → Skill IR Refresh → Index Refresh → Promotion Review
```

Background 自动完成评分（auto-score/auto-classify/auto-suggest），但 personal promotion 的晋升动作需人工确认（见 [promotion-reviewer.md](promotion-reviewer.md)「人工 Review 边界」）。

### 6. 交付契约门禁（🔴 阻断）

```bash
bash shared/scripts/check-kb-contract.sh .project-knowledge
```

逐条断言两件事，**契约清单从 `shared/schemas/knowledge-directories.yaml` 派生，不硬编码**：

1. **契约声明的全部目录在位**（分析后应全部创建——下游 skill 按目录读取，缺目录 = 知识链断裂）
2. **6 个固定根产物在位且大小写精确**：`manifest.json` `statistics.json` `context.json` `graph.json` `search-index.json` `index.md`

Exit 0 → 继续。**Exit 1 → 不可声明 `status: completed`**，按报告的缺失清单补齐后重跑。
报告落在 `.project-knowledge/kb-contract-report.md`。

> ⚠️ **本门禁是阻断的，不是标注的**（2026-09-30 修复）。此前 `validation.md` V7 对缺目录**只标注**、
> `finish-workflow.md` Phase D 明写「不阻断」——于是实测有项目在 13/14 契约目录缺失时仍能声明完成。
> 这是治理文档本身要防的「假完成」：**一个不阻断的门禁等于没有门禁。**

### 7. Write Manifest + State

- 写入 manifest.json（status=completed）
- 写入 state.json（confidence + history）
- 追加 timeline.json

## Exit

- classification-report.yaml 已读取并执行
- Finish Phase A/B 已执行（4 个根 JSON 已重新生成）
- **契约门禁 Exit 0**（`kb-contract-report.md` 无违约项）
- Project Sync 完成（promotion: project）
- Task Artifacts 已归档（promotion: none）
- Knowledge Promotion candidates 已展示（promotion: personal）
- manifest.status = completed

## Failure

| Condition | Action |
|-----------|--------|
| **契约门禁 Exit 1** | **阻断交付**——按 `kb-contract-report.md` 补齐缺失目录/根产物后重跑门禁；不得跳过 |
| 契约门禁 Exit 2 | 参数不是 `.project-knowledge` 目录——修正调用参数 |
| classification-report.yaml 缺失 | 返回 Phase 5 生成 |
| Vault 路径不可达 | 跳过同步，标注 `⚠️ Vault unreachable` |
| rsync 失败 | 重试一次 → 仍失败标注 `❌ Sync failed` |
