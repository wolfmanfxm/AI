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

1. 读 `architecture/overview.md` 了解技术栈，读 `components/catalog.md` 获取组件列表，读 `api/overview.md` 了解请求模式
2. 抽样 10-15 个页面/视图文件，统计以下模式出现次数，≥2 次纳入：
   - **CRUD**：搜索列表页面的 Table + SearchForm + Dialog 组合，提取标准流程（查询→选中→弹窗→提交→刷新）
   - **审批流**：状态流转、审批按钮、审批意见弹窗的组合模式
   - **导入导出**：下载模板→上传文件→进度提示→刷新列表 的完整链路
   - **搜索筛选**：SearchForm 组件的字段布局（列数、展开/收起）、触发方式（按钮/回车/change）
   - **对话框**：新增/编辑弹窗的打开方式、表单嵌套、提交回调模式
   - **上传**：Upload 组件的文件类型限制、大小校验、与表单的集成方式
   - **表格**：Table 组件的分页配置、操作列位置、工具栏按钮排列
3. 每个模式对照 `ui-pattern.md` 的发现交叉验证，避免重复
4. 对每个确认的模式，从实际代码中提取 10-20 行模板，标注至少 2 个使用该模式的文件路径

每个模式输出包含：触发条件、操作步骤、代码模板（10-20行）、至少2个使用页面的 file:line 引用

## Output
`patterns/` 下按需创建：`crud.md`、`search.md`、`dialog.md`、`upload.md`、`table.md`
