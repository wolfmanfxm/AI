# Analyzer Output Example

执行一次 analyzer 后的产出示例。

---

## architecture/overview.md

```markdown
---
id: architecture-overview
generatedBy: analyzer
generatedAt: 2026-07-27T14:00:00Z
confidence: 95
sources:
  - package.json
  - src/router/
---

# Architecture Overview

## Tech Stack
| 维度 | 选型 | 版本 |
|------|------|------|
| 框架 | Vue 3 | 3.4.x |
| 语言 | TypeScript | 5.6.x |
| UI 库 | Element Plus | 2.13.x |
```

---

## components/catalog.md

```markdown
---
id: component-data-table
generatedBy: analyzer
generatedAt: 2026-07-27T14:00:00Z
confidence: 98
sources:
  - src/components/DataTable.vue
---

# Component Catalog

### DataTable
- **路径**：src/components/DataTable.vue
- **用途**：通用数据表格，支持分页、多选、排序
- **Props**：columns: ColumnConfig[], fetchData: (params) => Promise<PageResult>
- **引用次数**：18 次，复用度：高
```
