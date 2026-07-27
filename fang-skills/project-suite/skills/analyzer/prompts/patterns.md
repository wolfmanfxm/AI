# Pattern Synthesis

## Goal
从 UI 和编码分析结果中提取跨模块的可复用执行模式。

## Context
依赖 `architecture/`、`components/`、`api/` 的已有分析结果，基于这些进行模式合成。

## Evidence
- `architecture/` 目录的已有分析
- `components/catalog.md` 的组件列表
- `api/` 目录的已有分析

## Analysis
识别反复出现的组合模式（至少出现 2 次），提取为可直接执行的步骤化模板：
1. **CRUD**：增删改查标准流程
2. **搜索**：搜索筛选模式
3. **对话框**：弹窗使用模式
4. **上传**：文件上传模式
5. **表格**：数据表格模式

每个模式包含：触发条件、操作步骤、代码模板（10-20行）、关联组件引用

## Output
`patterns/` 下按需创建：`crud.md`、`search.md`、`dialog.md`、`upload.md`、`table.md`
