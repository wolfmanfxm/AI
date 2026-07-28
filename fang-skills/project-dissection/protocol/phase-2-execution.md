# Phase 2: 执行

## Phase 2 Resume：恢复执行

> 入口条件：manifest 状态为 `interrupted` / `partial` / `in_progress`

1. 读 manifest，列出各维度状态（`completed` / `pending` / `partial`）
2. 跳过 `completed` 维度，仅执行 `pending` 和 `partial`
3. 已有文件保留，仅更新变更部分
4. 完成后 manifest `status` → `completed`

## 2.1 Execution

🔴 **CHECKPOINT · 🛑 STOP**：展示预计产出清单，用户确认后执行。

**预执行清单**（按当前 mode + scope 生成，逐项列出）：

```
📋 本次分析计划
─────────────────────────────────────
项目：{projectName}
模式：{mode}（quick/standard → 7维度 | deep → 8维度）
范围：{scope}
输出：{output targets}
─────────────────────────────────────
预计产出文件：
  architecture/   → overview.md {+ 按需 N 个}
  components/     → catalog.md {+ 按需 N 个}
  api/            → overview.md, request.md {+ 按需 N 个}
  patterns/       → {mode-specific} {+ 按需 N 个}
  observations/   → statistics.md {+ 按需 N 个}
  reports/        → {deep模式: latest.md} {标准/快速: 跳过}
─────────────────────────────────────
固定产出：manifest.json, statistics.json, graph.json, search-index.json, index.md
Vault 同步：{是/否}
─────────────────────────────────────
预计耗时：{quick: ~3min | standard: ~6min | deep: ~10min}
```

> 并行策略见 `capability-matrix.md` 的 Wave 0→1→2→3。

快速/标准模式跳过 `change-analysis`，详尽模式全执行。
读 config → 按 scope、mode 并行执行（各维度独立，无依赖的可并行）。

**Agent 默认 `general-purpose`**（需 Write 权限，不可用只读 `Explore`）。若环境仅支持只读 agent，主 agent 必须在 agent 返回后自行写文件。

### 维度表

| 维度 | 指南 | 输出目录 | 预期产出（必选 + 可选） |
|------|------|---------|---------------------|
| 架构 | [prompts/architecture.md](../prompts/architecture.md) | architecture/ | `overview.md`（必选），可选 `modules.md` `tech-stack.md` `directory-tree.md` |
| 组件 | [prompts/components.md](../prompts/components.md) | components/ | `catalog.md`（必选），可选 高复用组件独立 `.md` |
| 编码 | [prompts/coding-style.md](../prompts/coding-style.md) | patterns/ | 按需: `vue.md` `typescript.md` `naming.md` `folder.md` |
| UI | [prompts/ui-pattern.md](../prompts/ui-pattern.md) | patterns/ | 按需: `table.md` `form.md` `dialog.md` `layout.md` `upload.md` |
| API | [prompts/api-pattern.md](../prompts/api-pattern.md) | api/ | `overview.md` `request.md`（必选），可选 `modules.md` `auth.md` |
| 模式 | [prompts/patterns.md](../prompts/patterns.md) | patterns/ | 按需: `crud.md` `approval.md` `import-export.md` |
| 观察 | [prompts/observations.md](../prompts/observations.md) | observations/ | `statistics.md`（必选），可选 `dead-code.md` |
| 变更 | [prompts/change-analysis.md](../prompts/change-analysis.md) | reports/ | `change-log.md`（详尽模式必选） |

### Agent 协调规则

> 防止维度 agent 内部子 agent 状态混乱导致文件未写入。

- **禁止提前返回**：若 agent 内部 spawn 子 agent，必须等待**全部**子 agent 完成后才返回结果
- **写入时机**：所有子任务完成 → 验证结果完整性 → 一次性写入所有产出文件
- **写入后验证**：每个文件写完后 `ls -la` 确认存在且非空（>100 bytes）
- **写入失败处理**：
  1. 重试一次写入
  2. 仍失败 → 在对应文件写入 `❌ FAILED: [具体原因]` 占位内容
  3. 返回结果中明确标注失败项，由主流程 Finish 阶段二次处理
- **主流程兜底**：Finish 阶段逐文件验证，发现未更新或缺失的由主 agent 补写

### Agent Prompt 组合模板

每个维度 agent 的 prompt 按以下结构组装，4 部分缺一不可：

```
## 任务：[维度名称]分析
[从 prompts/ 读取 Goal + Analysis 步骤]

## 项目上下文（必须注入）
- 框架：[版本] · UI库：[名称+版本+命名空间前缀]
- 路径别名：@/ → src, @workspace/ → workspace, [其他]
- 分层：src/ = 框架层, workspace/ = 业务层
- ⚠️ 优先参考 workspace/ 下的内容

## 产出要求
- 文件路径：`.project-knowledge/[category]/[file].md`
- Evidence Header：[../../shared/templates/evidence-header.md]
- 最小节要求：[列出必选节标题]

## 失败处理
- 写入完成 → stat 验证文件存在且 >100 bytes
- 失败 → 重试一次 → 仍失败标注 `❌ FAILED: [原因]`
- 不存在的目录标注 `⚠️ 未找到期望路径 [path]`
```
