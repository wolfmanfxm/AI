# UI Pattern Analysis

## Goal
识别项目中反复出现的 UI 组合模式，提取可复用的交互范式。

## Context
UI 模式依赖项目使用的 UI 库（从 package.json 确定组件标签前缀）。先读 components/catalog.md 了解可用组件。

## Evidence
- 项目 UI 库的组件标签
- 页面/视图目录下的模板代码

## Analysis
按以下维度扫描，每种模式至少出现 2 次才认定为"模式"：
1. **表格**：分页方式、列配置、操作列、工具栏
2. **表单**：布局偏好、校验方式、提交 loading
3. **搜索/筛选**：布局列数、展开/收起、触发方式
4. **对话框**：新增/编辑/详情/确认四种模式
5. **上传**：组件选择、状态管理、与表单集成
6. **布局**：页面标准结构
7. **抽屉/侧边栏**：从侧边滑入的表单/详情面板。检测条件：`BaseDrawer` 或 `el-drawer` 引用 > 20 处
8. **权限控制**：`v-role` 指令或 `useRole()` composable 的使用模式。检测条件：`directives/` 或 `composables/` 中存在 role 相关文件

## Output
`patterns/` 下按需创建：`layout.md`、`table.md`、`form.md`、`dialog.md`、`upload.md`
每种模式：1个代码模板（10-20行）+ 至少2个使用页面作为证据
仅记录实际存在的模式
