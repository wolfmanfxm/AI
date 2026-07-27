---
name: generator
description: >
  根据需求和项目规范生成生产级代码：Vue 3 组件、页面、API 模块、工具函数、类型定义。
  必须遵循项目现有模式，从 .project-knowledge/ 提取规范而非凭记忆。
  触发词：写一个、实现、创建组件、新增页面、开发这个功能、生成代码、帮我写、implement、
  create component、build feature、generate code、write a、开发、编写、添加。
  产出：代码文件（.vue / .ts / .js 等）+ 少量注释说明。
---

# Generator

> 需求 + 项目知识 → 生产级代码

## 核心原则

1. **遵循项目模式，不做发明** — 从 `.project-knowledge/` 提取已有写法，不凭记忆猜
2. **使用项目组件** — 查 `components/catalog.md`，复用已有组件
3. **完整性** — 生成的代码包含 loading、empty、error 状态，不只是 happy path
4. **一致性** — 缩进、引号、命名、import 顺序与项目完全一致

## 前置条件

启动时按以下顺序检查：

| 优先级 | 资源 | 作用 | 缺失时 |
|--------|------|------|--------|
| 1 | `.project-knowledge/index.md` | 项目规范 + 模式 + 组件目录 | 提示用户运行 analyzer，降级为通用模式 |
| 2 | `PLAN.md` | 当前任务上下文 | 不阻塞，标注"⚠️ 无规划上下文" |
| 3 | `ARCHITECTURE.md` | 技术选型约束 | 不阻塞，使用 analyzer 推断的技术栈 |

## 项目知识读取策略

对不同类型的代码生成，按需读取对应文档：

| 生成类型 | 必读文档 | 按需读取 |
|---------|---------|---------|
| **组件** | `components/catalog.md` + `patterns/vue.md` | `patterns/table.md` `patterns/form.md` `patterns/dialog.md` |
| **页面** | `architecture/overview.md` + `patterns/table.md` | `patterns/form.md` `patterns/crud.md` |
| **API 模块** | `api/overview.md` + `api/request.md` | `api/modules.md` `api/auth.md` |
| **工具函数** | `patterns/typescript.md` | `patterns/naming.md` |
| **类型定义** | `patterns/typescript.md` + `api/overview.md` | `architecture/tech-stack.md` |

**关键**：读完后在脑海中确认 3 件事再开始写代码：
1. 这个项目 import 用什么风格？（`@/` 别名？相对路径？）
2. 这个项目组件怎么写？（`<script setup>` vs Options API？Props 类型怎么定义？）
3. 这个项目 API 怎么调？（request 封装叫什么？参数格式？错误怎么处理？）

## 工作流

### Discover

1. 读取项目知识库（按上表策略）
2. 查找类似功能的已有实现（搜索 `src/` 中相似文件名/函数名）
3. 确认技术栈版本（Vue 3.x / Element Plus 版本 / TypeScript 版本）
4. 🔴 **CHECKPOINT** — 确认实现范围 + 技术约束

### Execute

#### 生成流程

```
读知识库 → 找参考实现 → 提取模式 → 套用模式生成代码 → 自检
```

#### 自检清单（生成后必须过一遍）

- [ ] import 路径使用项目约定的别名（`@/` / `@workspace/` 等）
- [ ] 组件名 PascalCase，文件名 kebab-case（或项目约定）
- [ ] Props 使用 `defineProps<{...}>()` 泛型（Vue 3 项目）
- [ ] 响应式数据用 `ref()` / `reactive()` 而非 `data()`
- [ ] API 调用使用项目的 request 封装而不是裸 `fetch`/`axios`
- [ ] 错误处理：try-catch + 用户提示（ElMessage / ElNotification）
- [ ] loading 状态：异步操作有 loading 变量
- [ ] 空状态：列表为空时有 `el-empty` 或提示
- [ ] TypeScript 类型：无 `any`（除非确实需要），导出类型定义

#### 不同类型生成规范

##### Vue 3 组件（Composition API）

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
// 项目组件导入
import MpTable from '@/components/MpTable/index.vue'
// API 导入
import { fetchList } from '@/api/moduleName'

// Props — 泛型定义
interface Props {
  id: number
  type?: 'A' | 'B'
}
const props = withDefaults(defineProps<Props>(), {
  type: 'A',
})

// Emits
const emit = defineEmits<{
  (e: 'update', value: string): void
  (e: 'close'): void
}>()

// 响应式状态
const loading = ref(false)
const list = ref<Item[]>([])

// 方法
async function loadData() {
  loading.value = true
  try {
    const res = await fetchList({ id: props.id })
    list.value = res.data ?? []
  } catch {
    // 项目约定错误处理
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => loadData())
</script>

<template>
  <div v-loading="loading">
    <el-empty v-if="!loading && !list.length" description="暂无数据" />
    <!-- 主内容 -->
  </div>
</template>
```

##### API 模块

```typescript
import request from '@/api/request'          // 项目 request 封装
import type { PageResult } from '@/types/api' // 项目通用类型

// 函数签名遵循项目模式：(query, params?) => Promise<ResponseType>
export function fetchList(
  query: { keyword?: string; pageindex: number; pagesize: number },
  params?: { id: number }
): Promise<PageResult<ListItem>> {
  return request({
    url: '/api/resource/list',
    method: 'post',
    data: { ...query, ...params },
  })
}
```

### 边界情况处理

| 场景 | 做法 |
|------|------|
| 知识库不存在 | 降级为通用 Vue3+TS 模式，标注 `// ⚠️ 未找到项目知识库，使用通用模式` |
| 需要使用的组件不在目录中 | 搜索 `src/components/` 是否存在，找不到则用 Element Plus 原生组件 |
| PLAN.md 与代码实现冲突 | 以代码现实为准，在注释标注 `// ⚠️ 与 PLAN.md 有偏差，原因：xx` |
| 生成的代码需要新增依赖 | 标注 `// TODO: 安装依赖 npm i xxx`，不自动修改 package.json |

## Runtime 协议

| 协议 | 路径 |
|------|------|
| 状态机 | [../../runtime/engine/state-machine.md](../../runtime/engine/state-machine.md) |
| 断点续传 | [../../runtime/engine/checkpoint.md](../../runtime/engine/checkpoint.md) |
| 异常恢复 | [../../runtime/engine/error-recovery.md](../../runtime/engine/error-recovery.md) |

## References

| 资源 | 路径 |
|------|------|
| 组件生成 Prompt | [prompts/component-gen.md](prompts/component-gen.md) |
| API 生成 Prompt | [prompts/api-gen.md](prompts/api-gen.md) |
| 页面生成 Prompt | [prompts/page-gen.md](prompts/page-gen.md) |
| 触发词 | [references/trigger-words.md](references/trigger-words.md) |
| 能力边界 | [references/capability-matrix.md](references/capability-matrix.md) |
| 反例清单 | [references/anti-patterns.md](references/anti-patterns.md) |
| 输入输出示例 | [references/examples.md](references/examples.md) |
