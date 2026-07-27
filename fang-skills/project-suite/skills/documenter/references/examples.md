# Examples — Documenter

> 真实文档生成示例。

---

## 示例 1：API 文档

### 输入

> "给 `src/api/user.ts` 生成 API 文档"

### 源文件

```typescript
/** 查询用户列表，支持按部门过滤 */
export function queryUserList(
  query: { keyword?: string; pageindex: number; pagesize: number },
  params?: { deptId: number }
): Promise<PageResult<UserItem>> {
  return request({ url: '/api/user/list', method: 'post', data: { ...query, ...params } })
}
```

### 输出 (`api/user.md`)

```markdown
### `queryUserList` — 查询用户列表

> 查询用户列表，支持按部门过滤

| 项目 | 值 |
|------|-----|
| **方法** | POST |
| **路径** | `/api/user/list` |
| **鉴权** | 需要登录 |

**请求参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| keyword | string | 否 | - | 搜索关键词 |
| pageindex | number | 是 | - | 页码 |
| pagesize | number | 是 | - | 每页条数 |
| deptId | number | 否 | - | 部门 ID（params 传入）|

**响应**

```typescript
{ data: UserItem[], total: number }
```

**源文件**: `src/api/user.ts:12-20`
```

---

## 示例 2：组件文档

### 输入

> "给 `StatusBadge.vue` 写组件文档"

### 输出 (`components/status-badge.md`)

```markdown
### `<StatusBadge>`

> 状态标签，根据 status 显示不同颜色和文字

**路径**: `src/components/StatusBadge.vue`

**Props**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| status | 'pending' \| 'done' \| 'cancelled' | 是 | - | 状态值 |
| size | 'small' \| 'default' | 否 | 'default' | 尺寸 |

**使用示例**

```vue
<StatusBadge status="done" />
<StatusBadge status="pending" size="small" />
```

**源文件**: `src/components/StatusBadge.vue`
```
