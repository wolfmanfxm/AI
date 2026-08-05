# Delivery — Analyzer

> @engine: delivery
> v3.0: 双同步策略 — 读取 classification-report.yaml，按 promotion level 同步

## Actions

### 1. 读取分类报告

读取 `.project-knowledge/classification-report.yaml`，按 promotion level 执行：

### 2. Project Sync（promotion: project — 自动同步）

所有 `promotion: project` 的文件 → rsync 到 Knowledge Vault：

```bash
rsync -av --exclude='proposals/' --exclude='reports/REVIEW-*' \
  --exclude='reports/CHANGELOG-*' --exclude='decisions/ARCHITECTURE-*' \
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
Knowledge Scan → Decay Check → Graph Refresh → Index Refresh → Promotion Review
```

全自动，无需用户干预。`promotion_review` 中 auto_promote 自动执行，promote_candidate 留待人工确认。

### 6. Write Manifest + State

- 写入 manifest.json（status=completed）
- 写入 state.json（confidence + history）
- 追加 timeline.json

## Exit

- classification-report.yaml 已读取并执行
- Project Sync 完成（promotion: project）
- Task Artifacts 已归档（promotion: none）
- Knowledge Promotion candidates 已展示（promotion: personal）
- manifest.status = completed

## Failure

| Condition | Action |
|-----------|--------|
| classification-report.yaml 缺失 | 返回 Phase 5 生成 |
| Vault 路径不可达 | 跳过同步，标注 `⚠️ Vault unreachable` |
| rsync 失败 | 重试一次 → 仍失败标注 `❌ Sync failed` |
