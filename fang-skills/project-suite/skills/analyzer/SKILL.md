---
name: analyzer
description: >
  分析软件项目并生成可复用的项目知识库，覆盖架构、组件、API、模式、编码风格等维度。
  触发词：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、刷新项目知识、
  项目规范、编码规范、analyze codebase、scan project、project refresh。
  产出：.project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
---

## Quick Start

收到用户请求 → 按意图路由：

```
"分析/扫描/刷新"              → Analysis Flow（见下方）
"继续分析/resume"             → Resume（../../runtime/engine/scheduler.md）
"新增/创建/实现/开发前检查"    → Development Flow（references/development-flow.md）
```

## Analysis Flow

```
analysis-config.json 不存在     → Discover 阶段（../../runtime/engine/state-machine.md#discover）
manifest status = completed      → 询问: 🔁全量刷新 / 📝增量更新 / ❌取消
manifest status = interrupted/
  partial / in_progress          → Resume（../../runtime/engine/checkpoint.md）
```

### Discover 阶段

1. 探测技术栈、目录结构、源码目录、Vault 根路径
2. 使用 `AskUserQuestion` 确认配置：

   | Q | 首次 | 非首次 |
   |---|------|--------|
   | 项目名称 | 4选1（package name/目录名/Vault名/其他） | 跳过 |
   | 分析深度 | 🚀快速 / 📊标准 / 🔬详尽 | 同左 |
   | 扫描范围 | 全量 / 增量 | 🔄上次变更(默认) / 全量 / 增量 |
   | 输出位置 | Vault+本地 / 仅本地 / 仅Vault | 跳过 |

3. 完成 → 写入 `analysis-config.json` + `manifest.json`（status: confirmed）→ Execute 阶段

### Execute 阶段

🔴 **CHECKPOINT · 🛑 STOP**：展示预计产出清单，用户确认后执行。

快速/标准模式跳过 `change-analysis`，详尽模式全执行。
读 config → 按 scope、mode 并行执行。

**Agent 默认 `general-purpose`**（需 Write 权限）。若环境仅支持只读 agent，主 agent 必须在 agent 返回后自行写文件。

#### 维度表

| 维度 | 指南 | 输出目录 | 预期产出 |
|------|------|---------|---------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | architecture/ | `overview.md`（必选），可选 `modules.md` `tech-stack.md` |
| 组件 | [prompts/components.md](prompts/components.md) | components/ | `catalog.md`（必选），可选 高复用组件独立 `.md` |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | patterns/ | 按需: `vue.md` `typescript.md` `naming.md` |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | patterns/ | 按需: `table.md` `form.md` `dialog.md` |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | api/ | `overview.md` `request.md`（必选） |
| 模式 | [prompts/patterns.md](prompts/patterns.md) | patterns/ | 按需: `crud.md` `approval.md` |
| 观察 | [prompts/observations.md](prompts/observations.md) | observations/ | `statistics.md`（必选） |
| 变更 | [prompts/change-analysis.md](prompts/change-analysis.md) | reports/ | `change-log.md`（详尽模式必选） |

### Finish 阶段

1. 目录初次运行时全部创建
2. 根据分析发现填充各目录，有内容才建文件
3. 每个 `.md` 文件包含 Evidence Header（见 [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md)）
4. 准备 `graph.json`、`statistics.json`、`search-index.json` 数据
5. 非首次运行：对比标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`
6. 写固定产出：`manifest.json` `statistics.json` `search-index.json` `graph.json` `index.md`
7. 检查/创建 `.claude/CLAUDE.md`
8. 报告摘要 → manifest `status` → `completed`

## Development Flow

→ [references/development-flow.md](references/development-flow.md)

## Runtime 协议（由 suite 提供）

| 协议 | 路径 | 用途 |
|------|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) | 生命周期状态定义 |
| 断点续传 | [../../runtime/engine/checkpoint.md](../../runtime/engine/checkpoint.md) | manifest 读写 + 恢复 |
| 调度 | [../../runtime/engine/scheduler.md](../../runtime/engine/scheduler.md) | 续执行判定 |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) | 异常分级 + 恢复策略 |
| 路由 | [../../runtime/protocols/routing.md](../../runtime/protocols/routing.md) | 意图识别 |

## Shared 资源

| 资源 | 路径 | 用途 |
|------|------|------|
| Manifest Schema | [../../shared/schemas/manifest.schema.json](../../shared/schemas/manifest.schema.json) | 执行状态结构 |
| Analysis Config Schema | [../../shared/schemas/analysis-config.schema.json](../../shared/schemas/analysis-config.schema.json) | 用户配置结构 |
| Graph Schema | [../../shared/schemas/graph.schema.json](../../shared/schemas/graph.schema.json) | 知识图谱结构 |
| Evidence Header | [../../shared/templates/evidence-header.md](../../shared/templates/evidence-header.md) | 产出文件模板 |
| Conventions | [../../shared/conventions/README.md](../../shared/conventions/README.md) | 命名与格式约定 |

## References

| 资源 | 路径 |
|------|------|
| 维度 Prompts | [prompts/](prompts/) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 开发流程 | [references/development-flow.md](references/development-flow.md) |
| 产出示例 | [../../shared/examples/analyzer-output.md](../../shared/examples/analyzer-output.md) |
