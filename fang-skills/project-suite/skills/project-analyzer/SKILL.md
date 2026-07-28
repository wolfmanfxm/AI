---
name: project-analyzer
metadata: skill.yaml
description: >
  分析软件项目并生成可复用的项目知识库，覆盖架构、组件、API、模式、编码风格等维度。
  触发词：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、刷新项目知识、
  项目规范、编码规范、analyze codebase、scan project、project refresh。
  产出：.project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
---

# Analyzer

> 代码扫描 → 7 维度分析 → 结构化知识库 → Vault 同步

## 职责边界

→ [references/boundary.md](references/boundary.md)

## Quick Start

```
"分析/扫描/刷新"              → Analysis Flow
manifest status = completed    → 询问: 🔁全量 / 📝增量 / ❌取消
```

### Discover

1. 探测技术栈、目录结构、Vault 路径（`$HOME/Data/Knowledge Vault` → `./Knowledge Vault` → `$HOME/Documents/Knowledge Vault`）
2. `AskUserQuestion` 确认：项目名/深度/范围/输出位置
3. 写入 `analysis-config.json`（含 `vaultPath`）+ `manifest.json`
4. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

按 scope、mode 并行 spawn agent。反例 → [references/anti-patterns.md](references/anti-patterns.md)

| 维度 | 指南 | 输出 |
|------|------|------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | `overview.md` + `modules.md` `tech-stack.md` |
| 组件 | [prompts/components.md](prompts/components.md) | `catalog.md` |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | `vue.md` `typescript.md` `naming.md` |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | `table.md` `form.md` `dialog.md` |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | `overview.md` `request.md` |
| 模式 | [prompts/patterns.md](prompts/patterns.md) | `crud.md` 等 |
| 观察 | [prompts/observations.md](prompts/observations.md) | `statistics.md` |
| 变更 | [prompts/change-analysis.md](prompts/change-analysis.md) | `change-log.md`（详尽必选） |

### Agent 协调规则

> 防止维度 agent 内部子 agent 状态混乱导致文件未写入。

- **禁止提前返回**：若 agent 内部 spawn 子 agent（如同时分析 TypeScript + composables + API 命名），必须等待**全部**子 agent 完成后才返回结果
- **写入时机**：所有子任务完成 → 验证结果完整性 → 一次性写入所有产出文件
- **写入后验证**：每个文件写完后 `ls -la` 确认存在且非空（>100 bytes）
- **写入失败处理**：
  1. 重试一次写入
  2. 仍失败 → 在对应文件写入 `❌ FAILED: [具体原因]` 占位内容
  3. 返回结果中明确标注失败项，由主流程二次处理
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
- ⚠️ 优先参考 workspace/ 下的内容（组件、API、编码模式等）

## 产出要求
- 文件路径：`.project-knowledge/[category]/[file].md`
- Evidence Header：[../../shared/templates/evidence-header.md]
- 最小节要求：[列出必选节标题]

## 失败处理
- 写入完成 → stat 验证文件存在且 >100 bytes
- 失败 → 重试一次 → 仍失败标注 `❌ FAILED: [原因]`
- 不存在的目录标注 `⚠️ 未找到期望路径 [path]`
- 不确定的结论标注 `⚠️ 待确认`
```

### Finish

1. 写 `.md`（Evidence Header → [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md)）
2. 生成 `graph.json` `statistics.json` `search-index.json` **`context.json`**
3. 非首次：标记 `[NEW]/[CHANGED]/[CONFIRMED]`
4. 写 `manifest.json` `index.md`
5. **manifest 完整性校验**（防止外部进程覆盖）：
  - `mode` 字段 = 本次实际执行模式（`full` / `incremental` / `standard`）
  - `scope` 字段 = 本次实际扫描范围
  - `dimensions` 所有维度 = `completed`
  - `files` 列表覆盖全部实际产出文件
  - `executionLog` 含本次执行记录（startedAt/finishedAt/scope/changedFiles/unchangedFiles）
  - **若任何字段被外部进程篡改**，以本次执行参数覆盖，不依赖磁盘缓存
  - 校验通过后才进入 Vault 同步
6. 🔴 Vault 同步（若 `output` 含 `"vault"`）→ [vault-sync](../../shared/conventions/vault-sync.md)
7. 检查 `.claude/CLAUDE.md` → manifest `status` 置为 `completed`

**`context.json`** 是下游 skill 的标准化项目上下文（技术栈/路径别名/编码约定/模块清单）。Schema → [../../runtime/context/context.md](../../runtime/context/context.md)

## 完成后下一步

```
analyzer 完成 → /project-planner 或 /project-architect 或 ✅
```
