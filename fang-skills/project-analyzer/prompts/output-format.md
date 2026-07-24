# Output Format Specification

## 通用规则

1. **Markdown + YAML Frontmatter** — 每个文件以 `---` 包裹的 frontmatter 开头
2. **源文件引用** — `file:line` 格式，相对项目根目录
3. **实际代码** — 从源文件复制，不编造
4. **中文主体** — 描述用中文，代码原文

## 输出目录结构

```
.project-knowledge/
├── manifest.json                  ← 工具可读元数据
├── index.md                       ← 快速导航
├── architecture/
│   └── overview.md                ← 从 templates/documents/Architecture.md
├── components/
│   └── catalog.md                 ← 从 templates/documents/ComponentPattern.md
├── patterns/
│   ├── coding.md                  ← 从 templates/documents/CodingStyle.md
│   ├── ui.md                      ← 从 templates/documents/UIGuide.md
│   └── api.md                     ← 从 templates/documents/APIGuide.md
├── reports/
│   ├── migration.md               ← 从 templates/documents/MigrationNotes.md
│   └── analysis-YYYY-MM-DD.md     ← 完整分析报告
└── search-index.json              ← 关键词索引
```

前端文件 frontmatter：
```yaml
---
date: YYYY-MM-DD
project: <项目名>
version: <YYYYMMDD.N>
---
```

## 各文件结构

- **architecture/overview.md**：Overview → Tech Stack → Modules → Folder Structure → State Management → Routing → Shared Layer → Risks → Recommendations
- **components/catalog.md**：表格 + 详情，含 Name/Path/Purpose/Props/Emits/Slots/Used By/Example
- **patterns/coding.md**：按实际技术栈动态调整，每项 1 统计 + 1 示例
- **patterns/ui.md**：Tables → Forms → Dialogs → Search → Upload → Layout，每种 1 模板 + 2 证据页面
- **patterns/api.md**：Directory → Functions → Config → Response → Pagination → Error → Encryption（如存在）
- **reports/migration.md**：表格 Status/Category/Item/Previous/Current/Source，Status: 🆕🔄❌✅
- **reports/analysis-YYYY-MM-DD.md**：完整分析报告（含摘要+五维详情）

## 代码示例格式

````markdown
**示例**（`src/pages/user/list.tsx:45-52`）：
```tsx
// 实际代码
```
````
