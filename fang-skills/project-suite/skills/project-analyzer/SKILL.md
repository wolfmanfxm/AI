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

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **项目源码**（工作目录）| 🔴 BLOCKED |
| 1 | Knowledge Vault 路径 | 🟡 DEGRADED — 跳过 Vault 同步 |

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

- **禁止提前返回**：spawn 子 agent 必须等待全部完成后才返回
- **写入时机**：全部子任务完成 → 验证完整性 → 一次性写入所有产出文件
- **写入失败处理**：重试一次 → 仍失败标注 `❌ FAILED: [原因]`，主流程兜底补写
- **写入后验证**：`ls -la` 确认每个文件存在且 >100 bytes

### Agent Prompt 组合

每个维度 agent prompt 按 4 部分组装：任务描述 + 项目上下文（框架/路径别名/分层）+ 产出要求（路径/Evidence Header/最小节）+ 失败处理。详细模板 → [prompts/output-format.md](prompts/output-format.md)

### Finish

1. 写 `.md`（Evidence Header → [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md)）
2. 生成 `graph.json` `statistics.json` `search-index.json` **`context.json`**
3. 生成 **`knowledge-index.json`** → [../../runtime/state/schemas/knowledge-index.md](../../runtime/state/schemas/knowledge-index.md)
   - 扫描 `.project-knowledge/` 所有文件 → 按内容聚类为 capability
   - 每个 capability：description / files / keywords / confidence
   - 生成 aliases（中文简称 → capability 名）
   - 只包含 `status: Accepted` 的知识 → Candidate 不进入 index
4. 非首次：标记 `[NEW]/[CHANGED]/[CONFIRMED]`
5. 写 `manifest.json` `index.md`
6. **manifest 完整性校验**（防止外部进程覆盖）：
   - `mode` 字段 = 本次实际执行模式（`full` / `incremental` / `standard`）
   - `scope` 字段 = 本次实际扫描范围
   - `dimensions` 所有维度 = `completed`
   - `files` 列表覆盖全部实际产出文件
   - `executionLog` 含本次执行记录（startedAt/finishedAt/scope/changedFiles/unchangedFiles）
   - **若任何字段被外部进程篡改**，以本次执行参数覆盖，不依赖磁盘缓存
   - 校验通过后才进入后续步骤
7. **知识库健康检查** → [../../runtime/metrics/knowledge-health.md](../../runtime/metrics/knowledge-health.md)
   - 扫描 `.project-knowledge/` 全量 → 执行 7 种检测（broken_link / empty_document / duplicate_content / outdated_evidence / missing_evidence_header / stale_reference / orphan_knowledge）
   - 增量模式：只扫 `[CHANGED]` 文件 + 其引用目标，duplicate_content 全量对比
   - 生成 `knowledge-health.json`（含 summary / issues[] / trend）
   - error > 0 → manifest 标注 ⚠️；warning > 5 → context.json 标注 ⚠️
   - 不阻断 — 健康检查不影响主流程
8. 🔴 Vault 同步（若 `output` 含 `"vault"`）→ [vault-sync](../../shared/conventions/vault-sync.md)
9. 检查 `.claude/CLAUDE.md` → manifest `status` 置为 `completed`
10. 写 `timeline.json` → [../../runtime/metrics/timeline.md](../../runtime/metrics/timeline.md)

**`context.json`** 是下游 skill 的标准化项目上下文（技术栈/路径别名/编码约定/模块清单）。Schema → [../../runtime/context/context.md](../../runtime/context/context.md)

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 子 agent 超时或返回空（维度分析） | 重试一次（同 agent 同 prompt） | 标注 `❌ FAILED: [维度名] agent timeout`，主流程用已有信息补写该维度 |
| 写入文件失败（权限/磁盘满） | 重试一次 | 标注 `❌ FAILED: [原因]`，主流程记录失败维度到 manifest，不阻塞其他维度 |
| `.claude/CLAUDE.md` 不存在 | 直接生成 `.project-knowledge/`，Vault 同步照常 | 标注 `⚠️ 无 CLAUDE.md`，路径别名/命名空间从源码 package.json + tsconfig 推断 |
| Knowledge Vault 路径不可达 | 跳过 Vault 同步 | 标注 `⚠️ Vault 不可达`，`.project-knowledge/` 仍写入 |
| graph.json 生成失败（jq 不可用/JSON 格式错误） | 用 grep + 纯文本解析回退 | 标注 `⚠️ graph.json 未生成`，不影响其他产出 |

## 完成后下一步

```
analyzer 完成 → /project-planner 或 /project-architect 或 ✅
```
