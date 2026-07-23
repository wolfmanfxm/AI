# UI Pattern Analysis Prompt

使用模板：[templates/UIGuide.md](../templates/UIGuide.md)

## 前置

从项目 UI 库确定组件标签前缀（如 Element Plus 的 `el-`、Ant Design 的 `a-`、MUI 的 `Mui`）。

## 执行清单

### 1. 表格
```bash
# 搜索表格使用
grep -r "<${prefix}-table\|<${prefix}table" <src_dir> --include='*.vue' --include='*.tsx' | wc -l
```
抽样 3-5 个，提取：分页方式、列配置、操作列、多选模式。输出 1 个标准模板。

### 2. 表单
```bash
grep -r "<${prefix}-form\|<${prefix}form" <src_dir> --include='*.vue' --include='*.tsx' | wc -l
```
提取：布局偏好、校验方式、提交 loading 模式。

### 3. 搜索/筛选
搜索 `searchForm\|filterForm\|queryParams`，提取布局模式（列数、展开/收起）。

### 4. 对话框
搜索 `Dialog\|Modal\|dialog\|modal`，区分新增/编辑/详情/确认四种模式。

### 5. 上传
搜索 `upload\|Upload`，提取组件使用和状态管理模式。

### 6. 布局
提取页面标准结构：面包屑→标题→筛选→表格/内容→分页。

## 输出规则
- 每种模式 1 个标准代码模板（10-20 行，用实际组件标签名）
- 标注至少 2 个使用页面作为证据
- 标注推荐复用方式（复制模板 / 使用全局组件 / hook 封装）
- **仅记录实际存在的模式，不存在的跳过**
