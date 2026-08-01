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

4-Phase 执行，详见 [references/finish-workflow.md](references/finish-workflow.md)：

| Phase | 做什么 | 触发条件 |
|-------|--------|---------|
| **A** 强制刷新 | statistics / context / graph / search-index 必定重新生成 | 每次扫描 |
| **B** 状态初始化 | 创建或追加 `.project-runtime/`（state + knowledge） | 首次/每次 |
| **C** 差异化更新 | 写 `.md` + manifest + index，仅 `[CHANGED]` 维度 | 内容变化 |
| **D** 质量验证 | knowledge-health + CLAUDE.md 更新 + Vault sync + timeline | 每次扫描 |

核心规则：
- ⚠️ Phase A JSON 产物**禁止复用缓存数字**，必须从本次扫描数据重新提取
- ⚠️ Phase D CLAUDE.md 统计数字必须更新为最新值
- ⚠️ Vault 同步后验证文件数差异，>3 时标注
- 🔴 manifest 完整性校验后才置 `completed`

**`context.json`** 是下游 skill 的标准化项目上下文。Schema → [../../runtime/context/context.md](../../runtime/context/context.md)

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 子 agent 超时或返回空（维度分析） | 重试一次（同 agent 同 prompt） | 标注 `❌ FAILED: [维度名] agent timeout`，主流程用已有信息补写该维度 |
| 写入文件失败（权限/磁盘满） | 重试一次 | 标注 `❌ FAILED: [原因]`，主流程记录失败维度到 manifest，不阻塞其他维度 |
| `.claude/CLAUDE.md` 不存在 | 直接生成 `.project-knowledge/`，Vault 同步照常 | 标注 `⚠️ 无 CLAUDE.md`，路径别名/命名空间从源码 package.json + tsconfig 推断 |
| Knowledge Vault 路径不可达 | 跳过 Vault 同步 | 标注 `⚠️ Vault 不可达`，`.project-knowledge/` 仍写入 |
| graph.json 生成失败（jq 不可用/JSON 格式错误） | 用 grep + 纯文本解析回退 | 标注 `⚠️ graph.json 未生成`，不影响其他产出 |

## 引用索引

| 资源 | 路径 |
|------|------|
| Finish 详细步骤 | [references/finish-workflow.md](references/finish-workflow.md) |
| 产出格式规范 | [prompts/output-format.md](prompts/output-format.md) |
| 维度 Prompt | [prompts/](prompts/) |
| 职责边界+反例 | [references/boundary.md](references/boundary.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |

## 完成后下一步

```
analyzer 完成 → /project-planner 或 /project-architect 或 ✅
```
