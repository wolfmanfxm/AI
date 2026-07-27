# Examples — Generator

> 真实输入 → 代码示例。

---

## 示例 1：生成表格组件

### 输入

> "写一个用户列表组件，支持搜索、分页、多选。项目用 MpTable 封装。"

### 提取的模式（从 .project-knowledge/）

- 表格封装：`import MpTable from '@/components/MpTable/index.vue'`
- 分页参数：`pageindex: string`, `pagesize: string`
- API 调用：`queryUserList(query)` 返回 `PageResult<UserItem>`

### 输出代码

```vue
<script setup lang="ts">
import { ref, reactive } from 'vue'
import MpTable from '@/components/MpTable/index.vue'
import { queryUserList } from '@/api/user'
import type { UserItem, UserQuery } from '@/api/user'

const loading = ref(false)
const tableData = ref<UserItem[]>([])
const selectedRows = ref<UserItem[]>([])

const query = reactive<UserQuery>({
  keyword: '',
  pageindex: '1',
  pagesize: '10',
})
const total = ref(0)

async function fetchData() {
  loading.value = true
  try {
    const res = await queryUserList(query)
    tableData.value = res.data ?? []
    total.value = Number(res.total)
  } catch {
    ElMessage.error('加载失败')
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  query.pageindex = '1'
  fetchData()
}

function handlePageChange(page: number) {
  query.pageindex = String(page)
  fetchData()
}

fetchData()
</script>
```

---

## 示例 2：生成 API 模块

### 输入

> "给订单模块加一个导出接口，POST 请求，参数是 orderIds: number[] 和 format: 'csv' | 'xlsx'"

### 输出代码

```typescript
import request from '@/api/request'

export interface ExportOrderQuery {
  orderIds: number[]
  format: 'csv' | 'xlsx'
}

/** 导出订单数据 */
export function exportOrders(
  query: ExportOrderQuery
): Promise<Blob> {
  return request({
    url: '/api/order/export',
    method: 'post',
    data: query,
    responseType: 'blob',
  })
}
```
