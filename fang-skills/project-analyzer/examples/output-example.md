# Example Output

执行一次 project-analyzer 后的产出示例。

---

## architecture/overview.md

```markdown
---
id: architecture-overview
generatedBy: project-analyzer
generatedAt: 2026-07-24T14:00:00Z
confidence: 95
sources:
  - package.json
  - src/router/
  - src/stores/
---

# Architecture Overview

## 概述
本项目是企业后台管理系统，采用 Vue 3 + TypeScript + Vite 5 技术栈。
src/（框架层）+ packages/（业务模块）双层架构。

## Tech Stack
| 维度 | 选型 | 版本 |
|------|------|------|
| 框架 | Vue 3 | 3.5.x |
| 语言 | TypeScript | 5.6.x |
| UI 库 | Element Plus | 2.9.x |
| 状态管理 | Pinia | 2.2.x |
```

---

## components/catalog.md

```markdown
---
id: component-data-table
generatedBy: project-analyzer
generatedAt: 2026-07-24T14:00:00Z
confidence: 98
sources:
  - src/components/DataTable.vue
  - packages/user/pages/list.vue
---

# Component Catalog

### DataTable
- **路径**：src/components/DataTable.vue
- **用途**：通用数据表格，支持分页、多选、排序
- **Props**：columns: ColumnConfig[], fetchData: (params) => Promise<PageResult>
- **引用次数**：18 次，复用度：高
```

---

## reports/migration.md

```markdown
---
id: migration-notes
generatedBy: project-analyzer
generatedAt: 2026-07-24T14:00:00Z
confidence: 90
sources: []
---

# Migration Notes

对比基线：20260716 → 20260724

| Category    | 🆕 | 🔄 | ❌ | ✅ |
|-------------|----|----|----|----|
| Components  | 2  | 1  | 0  | 21 |
| Patterns    | 1  | 1  | 0  | 7  |
| API         | 1  | 0  | 0  | 4  |

### 🆕 NEW
| FileUploader | src/components/FileUploader.vue | 通用文件上传 | 高 |

### 🔄 CHANGED
| DataTable | Props 新增 rowKey | src/components/DataTable.vue:35 |
```
