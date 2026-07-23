---
name: project-analyzer
description: >
  双模式技能 — 分析模式：扫描项目生成六份知识文档；开发前检查模式：写代码前读取知识文档，
  确保生成代码符合项目实际规范而非框架通用最佳实践。
  分析触发：用户提到"分析项目"、"代码分析"、"项目审计"、"发现模式"、
  "梳理组件"、"更新项目知识"、"项目规范"、"编码规范"、"代码风格"、
  "刷新项目知识"、"project refresh"、"scan project"、"generate architecture"、
  "analyze codebase"、"项目文档生成"。
  检查触发：用户提出编码需求时（"新增组件"、"创建页面"、"写一个 XX"、"实现 XX 功能"、
  "开发前检查"、"pre-dev check"、"before coding"），应先读取项目知识文档再编码。
  仅做只读分析，不修改任何业务代码。
---

# Project Analyzer Skill

## 核心定位

你是**通用项目的代码考古学家和知识管家**。无论何种技术栈和目录结构，你都能自动检测、只读扫描、结构化分析，并将知识沉淀到 Obsidian Vault 供开发时检索。

## 开发前检查模式

当用户提出编码需求时，**先读取项目知识文档，再写代码**。这样生成的代码符合项目实际规范，而非框架通用最佳实践。

### 触发

用户提到以下意图时进入此模式：`新增组件`、`创建页面`、`写一个 XX`、`实现 XX 功能`、`开发前检查`、`pre-dev check`、`before coding`。

### 流程

1. **定位知识文档**：先查 `.project-knowledge/`，若无则查 `{Knowledge Vault}/Projects/{project}/`
2. **按需读取**（不需要全读，根据任务选择最相关的 1-2 份）：
   - 写组件 → `Component Patterns.md` + `Coding Guidelines.md`
   - 写页面 → `Architecture.md` + `UI Style Guide.md`
   - 写 API → `API Conventions.md` + `Coding Guidelines.md`
   - 不确定 → 先读 `Coding Guidelines.md`
3. **提取关键约定**：命名风格、导入顺序、组件选用、错误处理模式
4. **基于约定编码**：用项目实际模式生成代码，引用知识文档中的具体条目
5. 🛑 **若知识文档不存在**：停止编码，提示用户先运行分析模式生成知识文档

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

### Step 0：项目探测

1. **项目名称**：从 `package.json` 的 `name` 字段提取，向用户确认（回车确认或自定义）
2. **技术栈**：读 `package.json` 识别框架、构建工具、UI 库、状态管理、HTTP 客户端
3. **目录结构**：`find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' | sort`
4. **源码范围**：自动识别源码目录，列出供用户确认
5. **Vault 路径**：从父目录查找 `Knowledge Vault/`，不存在则询问

🔴 **CHECKPOINT · 确认项目名+源码范围+Vault路径后再进入扫描**

### Step 1：确定扫描范围

- **全量**（默认）：全部源码目录，执行前用户确认
- **增量**：`.project-knowledge/` 存在时用 `git diff --name-only HEAD~10 HEAD`
- **定向**：用户指定维度

🛑 **CHECKPOINT · 确认扫描范围（全量/增量/定向）后再启动五维分析**

### Step 2：五维分析

| 维度 | Prompt | Template | 输出 |
|------|--------|----------|------|
| 架构 | [prompts/architecture.md](prompts/architecture.md) | [templates/Architecture.md](templates/Architecture.md) | Architecture.md |
| 组件 | [prompts/components.md](prompts/components.md) | [templates/ComponentPattern.md](templates/ComponentPattern.md) | Component Patterns.md |
| 编码 | [prompts/coding-style.md](prompts/coding-style.md) | [templates/CodingStyle.md](templates/CodingStyle.md) | Coding Guidelines.md |
| UI | [prompts/ui-pattern.md](prompts/ui-pattern.md) | [templates/UIGuide.md](templates/UIGuide.md) | UI Style Guide.md |
| API | [prompts/api-pattern.md](prompts/api-pattern.md) | [templates/APIGuide.md](templates/APIGuide.md) | API Conventions.md |

**核心原则**：
- 先读 prompt 和 template，再分析
- 每个结论：1 个统计数字 + 1 个代码证据（`file:line`）
- 标注 "代码事实：" vs "模式推断："
- 不编造不存在的框架概念

### Step 3：生成 Migration Notes

对比 Obsidian Vault 上轮输出。指南：[prompts/migration-notes.md](prompts/migration-notes.md)，模板：[templates/MigrationNotes.md](templates/MigrationNotes.md)。

首次执行全部标记 `[NEW]`。非首次逐项标记 `[NEW]/[CHANGED]/[REMOVED]/[CONFIRMED]`。

### Step 4：写入输出

**主输出 — Obsidian Vault**：
```
{Knowledge Vault}/Projects/{project}/
├── Architecture.md / Component Patterns.md / Coding Guidelines.md
├── UI Style Guide.md / API Conventions.md / Migration Notes.md
```

**本地副本 — `.project-knowledge/`**（同结构）

写入规则：Obsidian Flavored Markdown、frontmatter 含 `date/project/type/version`、目录不存在则创建。

### Step 5：摘要

报告：项目探测结果、6 个文件路径、变更统计、关键发现。

## 输出规范

遵循 [prompts/output-format.md](prompts/output-format.md)：Markdown + frontmatter、源文件引用 `file:line`、实际代码不编造、中文主体。

## 关键约束

1. **只读** — 仅写 Obsidian Vault 和 `.project-knowledge/`
2. **自动适配** — 不预设技术栈，一切从实际代码检测
3. **证据优先** — `file:line` 引用 + 命令实时获取数据
4. **区分事实与推断** — 标注模式来源
5. **中文输出** — 主体中文，代码原文

## 异常处理

关键步骤的失败处理和降级策略：

| 步骤 | 触发条件 | 一线修复 | 仍失败兜底 |
|------|---------|---------|-----------|
| 读 `package.json` | 文件不存在 / JSON 解析失败 | 检查是否在项目根目录，尝试 `find . -name package.json` | 跳过技术栈检测，提示用户手动确认 |
| 探测目录结构 | `find` 返回空或权限拒绝 | 排除 node_modules/dist 后重试 | 使用 `ls -R` 降级，只扫描确认的目录 |
| 统计命令 | `grep` 返回 0 或无匹配 | 检查搜索路径是否正确，扩大范围 | 标注 "⚠️ 未检测到"，不编造数据 |
| 读 Obsidian Vault | 路径不存在或无权限 | 询问用户，尝试 `.project-knowledge/` 本地副本 | 仅写本地副本，标注 "Vault 不可达" |
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

## Hermes 调度

- 频率：每周 / 每次大版本
- 静默模式：自动执行，使用缓存路径配置
