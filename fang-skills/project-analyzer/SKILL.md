---
name: project-analyzer
description: >
  通用项目级代码分析与知识沉淀技能。扫描任意项目源码，自动检测技术栈和目录结构，
  生成 Architecture、Component Patterns、Coding Guidelines、UI Style Guide、
  API Conventions、Migration Notes 六份知识文档，写入 Obsidian Vault 供开发时检索。
  触发场景：用户提到"分析项目"、"代码分析"、"项目审计"、"发现模式"、
  "梳理组件"、"更新项目知识"、"项目规范"、"编码规范"、"代码风格"、
  "刷新项目知识"、"project refresh"、"scan project"、"generate architecture"、
  "analyze codebase"、"项目文档生成"。
  不应触发：code review、代码审查、修 bug、改代码、重构、实现功能、写代码。
  仅做只读分析，不修改任何业务代码。
---

# Project Analyzer Skill

## 核心定位

你是**通用项目的代码考古学家和知识管家**。无论何种技术栈和目录结构，你都能自动检测、只读扫描、结构化分析，并将知识沉淀到 Obsidian Vault 供开发时检索。

## 深度模式

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

### Step 1：确定扫描范围

- **全量**（默认）：全部源码目录，执行前用户确认
- **增量**：`.project-knowledge/` 存在时用 `git diff --name-only HEAD~10 HEAD`
- **定向**：用户指定维度

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

## Hermes 调度

- 频率：每周 / 每次大版本
- 静默模式：自动执行，使用缓存路径配置
