# API Module Generation Prompt

## 任务

你是 API 层开发专家。根据接口需求生成符合项目规范的 API 模块代码。

## 前置步骤

1. **读 api/overview.md** — 确认 request 封装路径和用法
2. **读 api/request.md** — 确认请求格式（参数命名、响应结构）
3. **读 api/modules.md**（若存在）— 确认模块组织方式

## 输入

```
需求：
{{user_input}}

接口列表（若有后端文档/设计）：
{{#if api_spec}}
{{api_spec}}
{{/if}}

项目 API 规范（从 .project-knowledge/api/ 提取）：
{{api_patterns}}
```

## 生成要求

### 必须遵循

- 导入项目的 request 封装（如 `import request from '@/api/request'`）
- 函数签名：`(query: X, params?: Y) => Promise<Z>`（与项目一致）
- 参数命名：`pageindex` / `pagesize`（字符串类型？与项目一致）
- 使用项目通用类型：`PageResult<T>` / `ApiResponse<T>` 等

### 每个 API 函数包含

1. **JSDoc 注释**：接口用途 + 参数说明
2. **类型定义**：请求参数类型 + 响应类型（导出）
3. **错误不做本地处理**：让调用方决定错误处理策略（除非项目有特殊约定）

### 示例

```typescript
import request from '@/api/request'
import type { PageResult } from '@/types/api'

export interface UserQuery {
  keyword?: string
  pageindex: number
  pagesize: number
}

export interface UserItem {
  id: number
  name: string
  email: string
  role: string
}

/** 查询用户列表 */
export function queryUserList(
  query: UserQuery,
  params?: { deptId: number }
): Promise<PageResult<UserItem>> {
  return request({
    url: '/api/user/list',
    method: 'post',
    data: { ...query, ...params },
  })
}
```

## 输出格式

完整的 `.ts` 文件，包含导入、类型定义、API 函数。
