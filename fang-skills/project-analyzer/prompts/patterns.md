# Pattern Analysis Prompt

从 `ui/` 和 `coding-style/` 的分析结果中提取可复用模式。

## 执行清单

1. 读取 `ui/` 和 `coding-style/` 的已有分析结果
2. 识别反复出现的组合模式（至少出现 2 次）
3. 按模板生成 `patterns/` 下的文件：
   - `crud.md` — 增删改查标准流程
   - `search.md` — 搜索筛选模式
   - `dialog.md` — 对话框使用模式
   - `upload.md` — 文件上传模式
   - `table.md` — 表格使用模式

## 每个模式包含
- 触发条件（什么时候用这个模式）
- 步骤（做什么）
- 代码模板（从实际代码提取 10-20 行）
- 相关组件（引用 `components/catalog.md` 中的组件名）

## 输出
按分析结果动态创建 patterns/ 目录下的文件。
