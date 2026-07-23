# Example Output

以下是执行一次 project-analyzer 后的产出示例（以某 Vue 3 + Element Plus 项目为例，实际输出取决于项目实际技术栈）。

---

## Architecture.md（示例片段）

```markdown
---
date: 2026-07-23
project: my-web-app
type: architecture
version: 20260723.1
---

# Architecture

## Overview

本项目是某企业后台管理系统，采用 Vue 3 + TypeScript + Vite 5 技术栈。
整体为 src/（框架层）+ packages/（业务模块）双层架构。

## Tech Stack

| 维度 | 选型 | 版本 |
|------|------|------|
| 框架 | Vue 3 | 3.5.x |
| 语言 | TypeScript | 5.6.x |
| 构建工具 | Vite | 5.4.x |
| UI 库 | Element Plus | 2.9.x |
| 状态管理 | Pinia | 2.2.x |
| HTTP 客户端 | Axios | 1.7.x |

## Modules

| 模块 | 路径 | 规模 | 职责 |
|------|------|------|------|
| user | packages/user/ | ~4200行 | 用户管理、权限分配 |
| order | packages/order/ | ~3800行 | 订单管理、流程追踪 |
...
```

---

## Component Patterns.md（示例片段）

```markdown
---
date: 2026-07-23
project: my-web-app
type: component-patterns
version: 20260723.1
---

# Component Patterns

## 1. 全局通用组件

### DataTable
- **路径**：`src/components/DataTable.vue`
- **用途**：通用数据表格，支持分页、多选、排序、列配置
- **Props**：`columns: ColumnConfig[]`, `fetchData: (params) => Promise<PageResult>`
- **Emits**：`@selection-change(rows: Row[])`
- **Slots**：`toolbar` — 自定义工具栏, `actions` — 自定义操作列
- **引用次数**：18 次
- **复用度**：高
- **示例**（`packages/user/pages/list.vue:23`）：
  ```vue
  <DataTable :columns="userColumns" :fetch-data="fetchUsers" @selection-change="handleSelect">
    <template #toolbar>
      <el-button type="primary" @click="openCreate">新增用户</el-button>
    </template>
  </DataTable>
  ```
```

---

## Migration Notes.md（示例片段）

```markdown
---
date: 2026-07-23
project: my-web-app
type: migration-notes
version: 20260723.1
---

# Migration Notes

对比基线：20260716.1 → 20260723.1

## Summary

| Category    | 🆕 NEW | 🔄 CHANGED | ❌ REMOVED | ✅ CONFIRMED |
|-------------|--------|------------|------------|-------------|
| Components  | 2      | 1          | 0          | 21          |
| Coding      | 1      | 1          | 0          | 7           |
| UI          | 0      | 1          | 0          | 5           |
| API         | 1      | 0          | 0          | 4           |
| Architecture| 0      | 0          | 0          | 6           |
| **Total**   | **4**  | **3**      | **0**      | **43**      |

## Component Changes

### 🆕 NEW
| 组件 | 路径 | 用途 | 复用度 |
|------|------|------|--------|
| FileUploader | src/components/FileUploader.vue | 通用文件上传+预览 | 高 |
| StatusBadge | src/components/StatusBadge.vue | 状态标签渲染 | 中 |

### 🔄 CHANGED
| 组件 | 变更 | 来源 |
|------|------|------|
| DataTable | Props 新增 `rowKey`；Emits 新增 `@sort-change` | src/components/DataTable.vue:35 |

### ✅ CONFIRMED
21 个已有组件未变化。
```
