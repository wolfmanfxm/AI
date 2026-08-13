# Page Generation Prompt

## 任务

你是前端页面开发专家。根据需求和项目规范，生成完整的业务页面。

## 前置步骤

1. **读 architecture/overview.md** — 确认路由和目录结构
2. **读 patterns/table.md** — 确认表格页面模式
3. **读 patterns/form.md** — 确认表单页面模式
4. **`@adapter:knowledge.query --type component --scope project`** — 确认可复用的项目组件
5. **搜索类似页面** — `grep` 项目中功能相似的页面作为参考

## 输入

```
需求：
{{user_input}}

页面类型：{{page_type}}（列表/表单/详情/仪表盘/混合）

{{#if PLAN}}
开发计划上下文：
{{PLAN}}
{{/if}}

项目页面模式（Context Resolver 已注入）：
{{page_patterns}}
```

## 生成要求

### 列表页必须包含

- 搜索区域（SearchForm 或条件筛选）
- 表格区域（使用项目封装的 Table 组件）
- 分页（参数 `pageindex` / `pagesize`）
- 新增/编辑弹窗（如有 CRUD 需求）
- loading / empty / error 三态

### 表单页必须包含

- 表单校验规则
- 提交 loading 状态
- 提交成功/失败反馈
- 取消/返回按钮

### 代码组织

```
<script setup lang="ts">
// 1. 导入（项目组件 → Element Plus → API → 类型）
// 2. Props
// 3. 响应式状态（搜索、表格、分页、弹窗、loading）
// 4. 方法（搜索、重置、翻页、新增、编辑、删除、提交）
// 5. 生命周期
</script>

<template>
  <!-- 搜索区 -->
  <!-- 操作栏 -->
  <!-- 表格区（含 empty slot） -->
  <!-- 弹窗区 -->
  <!-- 分页区 -->
</template>
```

## 输出格式

完整的 `.vue` 文件。
