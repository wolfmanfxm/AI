---
name: project-analyzer
description: >
  双模式技能 — 分析模式：扫描项目生成结构化知识文档；开发前检查模式：写代码前读取知识文档，
  确保生成代码符合项目实际规范而非框架通用最佳实践。
  分析触发（Phase 1 Discover）：用户提到"分析项目"、"代码分析"、"项目审计"、
  "发现模式"、"梳理组件"、"更新项目知识"、"项目规范"、"编码规范"、"代码风格"、
  "刷新项目知识"、"project refresh"、"scan project"、"generate architecture"、
  "analyze codebase"、"项目文档生成"。
  恢复触发（Phase 2 Resume）：用户说"继续分析"、"resume"、"analyze now"、
  "开始分析"、"确认配置"、"start analysis"。
  检查触发：用户提出编码需求时（"新增组件"、"创建页面"、"写一个 XX"、"实现 XX 功能"、
  "开发前检查"、"pre-dev check"、"before coding"），应先读取项目知识文档再编码。
  仅做只读分析，不修改任何业务代码。
---

# Project Analyzer Skill

## 核心定位

你是**通用项目的代码考古学家和知识管家**。无论何种技术栈和目录结构，你都能自动检测、只读扫描、结构化分析，并将知识沉淀到 Obsidian Vault 供开发时检索。

## 开发前检查模式

**两层保障机制**：

**两层保障**：`.claude/CLAUDE.md` 自动加载（主） + skill 触发（辅）。先读知识文档，再写代码。

### 触发

用户提到以下意图时进入此模式：`新增组件`、`创建页面`、`写一个 XX`、`实现 XX 功能`、`开发前检查`、`pre-dev check`、`before coding`。

### 流程

1. **定位知识文档**：先查 `.project-knowledge/`，若无则查 `{Knowledge Vault}/Projects/{project}/`
2. **按需读取**（先读 index.md 了解结构，再按任务选读 1-2 份）：
   - 写组件 → 找 `components/catalog.md`，无则读 `coding-style/` 相关文件
   - 写页面 → 找 `architecture/overview.md` + `ui/` 相关文件
   - 写 API → 找 `api/request.md` + `coding-style/` 相关文件
   - 不确定 → 先读 `coding-style/` 目录中的文件
3. **提取关键约定**：命名风格、导入顺序、组件选用、错误处理模式
4. **基于约定编码**：用项目实际模式生成代码，引用知识文档中的具体条目
5. 🛑 **若知识文档不存在**：使用 `AskUserQuestion` 询问用户：
   - `🔍 先运行分析（推荐）` → 跳转至 Phase 1 Discover
   - `📝 不分析，基于通用规范编码` → 按框架最佳实践编写，并在回复中标注「未找到项目知识文档」
   - `📂 手动指定文档路径` → 让用户输入自定义路径

### 关键原则

- 只读已有文档，不重新扫描
- 代码使用项目实际的组件/模式/hook，不推荐项目未使用的方案
- 编码决策引用知识文档中的具体条目

---

## 分析模式

执行前确认分析深度（默认标准模式）：

| 模式 | 耗时 | 适用场景 | 行为 |
|------|------|---------|------|
| 🚀 **快速** | ~2min | 日常增量、快速了解 | 仅统计+概要，不生成完整文档 |
| 📊 **标准** | ~5min | 常规分析、周度刷新 | 完整五维分析，有数据有示例 |
| 🔬 **详尽** | ~10min | 首次分析、新人入职 | 标准模式 + 每个组件/模块详细展开 |

**标准模式精简原则**：每个结论 1 个数据 + 1 个代码示例，不展开列举。

## 工作流

分析分为两个阶段，通过 `.project-knowledge/analysis-config.json` 衔接。

### Phase 1：Discover（生成配置）

1. 探测技术栈、目录结构、源码目录，定位 Vault 根路径。生成 `.project-knowledge/analysis-config.json`（模板：[templates/metadata/analysis-config.json](templates/metadata/analysis-config.json)），`status` 设为 `pending`。Vault 输出路径由 Q1 选择结果自动决定（`{VaultRoot}/Projects/{项目名}/`）。
2. **使用 `AskUserQuestion` 工具逐项确认**，每项提供预设选项，最后一项固定为 `其他（自定义输入）`：

   **Q1 — 项目名称**
   - 选项：`package.json` 的 `name` + 当前目录名 + Vault 中已有名称 + 其他
   - 默认选中 Vault 已有名称或目录名
   - **Vault 输出路径将自动设为** `{VaultRoot}/Projects/{Q1选择结果}/`

   **Q2 — 分析深度**
   - 选项：`🚀 快速（~2min）` / `📊 标准（~5min，推荐）` / `🔬 详尽（~10min）`
   - 默认选中「标准」

   **Q3 — 扫描范围**
   - 选项：`全量（全部源码目录）` / `增量（近 10 次 commit 变更）`
   - 默认选中「全量」

   **Q4 — 输出位置**
   - 选项：`Vault + 本地` / `仅本地 .project-knowledge/` / `仅 Vault`
   - 默认选中「Vault + 本地」

3. 用户完成全部选项后，将 config 的 `status` 更新为 `confirmed`，**立即进入 Phase 2**，无需用户再输入任何文字

> `AskUserQuestion` 的 `header` 字段用 4-6 字中文简短标签（如「项目名称」「分析深度」），
> 每个选项 `label` 用 3-8 字。单选模式，不启用 `multiSelect`。

### Phase 2：Resume（执行分析）

1. 读取 `.project-knowledge/analysis-config.json`，若 `status != "confirmed"` 则退回 Phase 1
2. 按 config 中指定的 `scope` 和 `mode` 执行扫描
3. 五维分析、Migration Notes、写入输出、CLAUDE.md 检查、摘要（完整执行后续所有步骤）
4. 完成后将 config 的 `status` 更新为 `completed`

| 维度 | Prompt | 输出 |
|------|--------|------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | architecture/ |
| 组件 | [prompts/components.md](prompts/components.md) | components/ |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | coding-style/ |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | ui/ |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | api/ |
| 模式 | [prompts/patterns.md](prompts/patterns.md) | patterns/ |
| 观察 | [prompts/observations.md](prompts/observations.md) | observations/ |
| 变更 | [prompts/change-analysis.md](prompts/change-analysis.md) | changelog/ + reports/ |

**核心原则**：
- 先读对应的 prompt 文件，再分析
- 每个结论：1 个统计数字 + 1 个代码证据（`file:line`）
- 标注 "代码事实：" vs "模式推断："
- 不编造不存在的框架概念

### Step 3：生成 Migration Notes

对比 Obsidian Vault 上轮输出。指南：[prompts/change-analysis.md](prompts/change-analysis.md)，模板：[templates/metadata/manifest.json](templates/metadata/manifest.json)（参考 frontmatter 格式）。

首次执行全部标记 `[NEW]`。非首次逐项标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`。

### Step 4：写入输出

**Obsidian Vault + 本地 `.project-knowledge/` 同结构**。

**固定产出**（每次必定生成）：

| 文件 | 说明 |
|------|------|
| `index.md` | 知识库入口 + 导航 |
| `manifest.json` | 元数据 |
| `search-index.json` | 检索索引 |
| `architecture/overview.md` | 架构总览 |
| `changelog/latest.md` | 本次知识变化 |

**按需产出**（根据分析结果动态创建，以下为常见维度，按实际发现灵活增减）：

| 目录 | 可能内容（示例） | 何时创建 |
|------|-----------------|---------|
| `architecture/` | modules.md, tech-stack.md, dependencies.md... | 有值得记录的架构信息 |
| `components/` | catalog.md, {{ComponentName}}.md... | 有可复用组件 |
| `api/` | request.md, auth.md, modules.md... | 有 API 层 |
| `ui/` | layout.md, table.md, form.md, dialog.md... | 有 UI 模式 |
| `coding-style/` | typescript.md, vue.md, naming.md... | 有编码规范 |
| `patterns/` | crud.md, search.md... | 有可复用模式 |
| `observations/` | statistics.md, duplicates.md, dead-code.md... | 有客观数据 |
| `proposals/` | {{rule-name}}.md | 发现候选规范 |
| `reports/` | latest.md, quality.md, coverage.md | 有质量/覆盖数据 |

**人工目录**（仅创建 index.md，内容由人工维护）：`rules/`、`playbooks/`、`experience/`、`decisions/`。

写入规则：`.md` + `.json`、frontmatter 含 `date/project/version`、目录不存在则创建。**不追求文件数量，有内容才创建。**

### Step 4.5：确保 CLAUDE.md 规则

知识文档写入后，**检查 `.claude/CLAUDE.md` 是否存在**：

- **若不存在**：创建 `CLAUDE.md`，内容指引 Claude 在编码前先读取 `.project-knowledge/` 中的知识文档（按任务类型匹配对应的 1-3 份文档）
- **若已存在**：检查是否包含 `.project-knowledge/` 引用，若无则追加"开发前必读"段落

这样即使 skill 未被触发，Claude 每次会话启动时也能自动加载编码规范，确保生成的代码符合项目实际模式。

### Step 5：摘要

报告：项目探测结果、生成文件列表、变更统计、关键发现。

## 输出规范

遵循 [prompts/output-format.md](prompts/output-format.md)：Markdown + frontmatter、源文件引用 `file:line`、实际代码不编造、中文主体。

## 关键约束

1. **只读** — 仅写 Obsidian Vault 和 `.project-knowledge/`
2. **自动适配** — 不预设技术栈，一切从实际代码检测
3. **证据优先** — `file:line` 引用 + 命令实时获取数据
4. **区分事实与推断** — 标注模式来源
5. **中文输出** — 主体中文，代码原文
6. **定期刷新** — 建议每周或大版本后运行分析（可通过 Hermes 自动调度）

## 异常处理

关键步骤的失败处理和降级策略：

| 步骤 | 触发条件 | 一线修复 | 仍失败兜底 |
|------|---------|---------|-----------|
| 读 `package.json` | 文件不存在 / JSON 解析失败 | 检查是否在项目根目录 | 用 `AskUserQuestion` 让用户选择：手动输入框架名 / 跳过检测 / 指定自定义目录 |
| 探测目录结构 | `find` 返回空或权限拒绝 | 排除 node_modules/dist 后重试 | 用 `AskUserQuestion` 让用户选择：手动输入目录 / 降级 ls -R / 取消 |
| 统计命令 | `grep` 返回 0 或无匹配 | 检查搜索路径是否正确，扩大范围 | 标注 "⚠️ 未检测到"，不编造数据 |
| 读 Obsidian Vault | 路径不存在或无权限 | 尝试 `.project-knowledge/` 本地副本 | 用 `AskUserQuestion` 让用户选择：重新输入路径 / 仅本地输出 / 取消 |
| 组件引用计数 | `grep` 无结果 | 尝试 PascalCase + kebab-case 两种模式 | 标注 "引用计数=0（可能为内部组件）" |
| 增量扫描 | `.project-knowledge/` 为空 | 回退到全量扫描 | 新建目录 + 全量扫描 |

## 反例清单

以下是执行时**禁止**的行为：

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 修改 `src/`、`workspace/` 及任何业务代码文件 | 仅写入 `.project-knowledge/` 和 Obsidian Vault |
| 2 | 用框架官方文档的通用模式代替项目实际模式 | 从实际代码提取模式，引用 `file:line` |
| 3 | 编造不存在的 API、组件、目录结构 | 用 `ls`/`find`/`grep` 实时验证后再写 |
| 4 | 跳过用户确认直接全量扫描大型项目 | 先确认项目名、源码范围、Vault 路径 |
| 5 | 在开发前检查模式中重新扫描源码 | 只读已有知识文档，不重新分析 |
| 6 | 输出无 `file:line` 引用的笼统建议 | 每个结论标注具体源文件位置 |
| 7 | 对不存在的目录/文件静默跳过 | 标注 "⚠️ 路径不存在，已跳过" |

