# Output Format Specification

## 通用规则

1. **Markdown + YAML Frontmatter** — 每个文件以 `---` 包裹的 frontmatter 开头
2. **源文件引用** — `file:line` 格式，相对项目根目录
3. **实际代码** — 从源文件复制，不编造
4. **中文主体** — 描述用中文，代码原文

## Frontmatter

```yaml
---
date: YYYY-MM-DD
project: <项目名>
type: architecture | component-patterns | coding-guidelines | ui-style-guide | api-conventions | migration-notes
version: <YYYYMMDD.N>
---
```

## 各文件结构

- **Architecture.md**：Overview → Tech Stack → Modules → Folder Structure → State Management → Routing → Shared Layer → Risks → Recommendations
- **Component Patterns.md**：表格 + 详情，含 Name/Path/Purpose/Props/Emits/Slots/Used By/Example
- **Coding Guidelines.md**：按实际技术栈动态调整，每项 1 统计 + 1 示例
- **UI Style Guide.md**：Tables → Forms → Dialogs → Search → Upload → Layout，每种 1 模板 + 2 证据页面
- **API Conventions.md**：Directory → Functions → Config → Response → Pagination → Error → Encryption（如存在）
- **Migration Notes.md**：表格 Status/Category/Item/Previous/Current/Source，Status: 🆕🔄❌✅

## 代码示例格式

````markdown
**示例**（`src/pages/user/list.tsx:45-52`）：
```tsx
// 实际代码
```
````
