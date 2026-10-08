# Delivery — Analyzer

> @template: delivery
> 两道阻断门禁（契约完整性 + 项目入口）+ 双同步策略 — 先跑 Finish 刷新机器产物，过门禁，再按 promotion level 同步

## Actions

### 0. 强制刷新机器可读产物（Finish Phase A/B）

→ [finish-workflow.md](../references/finish-workflow.md) 的 **Phase A + Phase B**

`statistics.json` / `context.json` / `graph.json` / `search-index.json` **每次扫描必定重新生成**——
它不等价于 markdown 是否 `[CHANGED]`，也**不是可选步骤**。后面第 6 步的门禁会检查它们是否在位。

> ⚠️ **为什么把这一步显式写进 Delivery**：`finish-workflow.md` 正是「4 个根 JSON 每次必定生成」的
> 规格来源。规格若只存在于一个**没有任何阶段执行它的文件**里 = 未生效的规格——产出可能缺根 JSON
> 却仍声明 `status: completed`。本步骤保证它被交付流程调用。

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

> ⚠️ **本门禁是阻断的，不是标注的**：目录 / 根产物缺失 = 知识链**结构性**断裂，没有
> 「质量问题但可用」的中间态。只标注不阻断 = 契约目录缺到只剩 1/14 仍能声明完成，
> 这是「假完成」。**一个不阻断的门禁等于没有门禁。**

### 7. 项目级 CLAUDE.md 入口（🔴 阻断）

→ [finish-workflow.md](../references/finish-workflow.md) 的 **步骤 13**（写入）+ **步骤 17**（门禁）

写入/更新 `<项目根>/.claude/CLAUDE.md`，然后：

```bash
bash shared/scripts/check-claude-md.sh .
```

断言三件事——**第 6 步查知识是否成型，本步查知识是否送达到 agent**：

1. `.claude/CLAUDE.md` 存在（大小写精确）
2. 含 `.project-knowledge/` 引用 + `.project-knowledge/index.md` 入口链接
3. `kb-stats` 标记与本次 `statistics.json` 一致

写入是**幂等**的：不存在则创建；已存在但无 KB 引用则追加；已有引用则**只重写首行标记**——
人工撰写的段落永不被改写。

Exit 0 → 继续。**Exit 1 → 不可声明 `status: completed`**，回到步骤 13 补齐后重跑。
报告落在 `.project-knowledge/claude-md-report.md`。

> ⚠️ **为什么这条要写成「断言产出」而非「更新文件」**：规格里留着一句读起来还在的动作名不算数——
> 只有入口文件**真的生成**，知识库才被送达 agent。故本门禁断言的是产出本身，不是「有没有检查过」。

### 8. Write Manifest + State

- 写入 manifest.json（status=completed）
- 写入 state.json（confidence + history）
- 追加 timeline.json

## Exit

- classification-report.yaml 已读取并执行
- Finish Phase A/B 已执行（4 个根 JSON 已重新生成）
- **契约门禁 Exit 0**（`kb-contract-report.md` 无违约项）
- **项目入口门禁 Exit 0**（`claude-md-report.md` 无违约项）
- Project Sync 完成（promotion: project）
- Task Artifacts 已归档（promotion: none）
- Knowledge Promotion candidates 已展示（promotion: personal）
- manifest.status = completed

## Failure

| Condition | Action |
|-----------|--------|
| **契约门禁 Exit 1** | **阻断交付**——按 `kb-contract-report.md` 补齐缺失目录/根产物后重跑门禁；不得跳过 |
| 契约门禁 Exit 2 | 参数不是 `.project-knowledge` 目录——修正调用参数 |
| **项目入口门禁 Exit 1** | **阻断交付**——按 `claude-md-report.md` 回到 Finish 步骤 13 补齐/刷标记后重跑；不得跳过 |
| 项目入口门禁 Exit 2 | 参数不是含 `.project-knowledge/` 的项目根——修正调用参数 |
| classification-report.yaml 缺失 | 返回 Phase 5 生成 |
| Vault 路径不可达 | 跳过同步，标注 `⚠️ Vault unreachable` |
| rsync 失败 | 重试一次 → 仍失败标注 `❌ Sync failed` |
