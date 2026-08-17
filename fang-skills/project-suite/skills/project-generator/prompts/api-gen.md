# API Module Generation Prompt

## 任务

你是 API 层开发专家。根据接口需求生成符合项目规范的 API 模块代码（语言与请求封装以项目为准）。

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

项目 API 规范（Context Resolver 已注入）：
{{api_patterns}}
```

## 生成要求

### 必须遵循

- 导入项目的 request 封装（路径从 `api/request.md` / `patterns/` 提取）
- 函数签名与项目一致（从现有 API 模块提取范式，不猜测）
- 参数命名与类型（分页参数名/类型从项目提取，不猜测）
- 使用项目通用类型（分页结果类型、响应包装类型等，以项目为准）

### 每个 API 函数包含

1. **文档注释**：接口用途 + 参数说明（遵循项目注释风格）
2. **类型定义**：请求参数类型 + 响应类型（导出）
3. **错误不做本地处理**：让调用方决定错误处理策略（除非项目有特殊约定）

### 示例

> 以下示例基于某前端技术栈示意，实际按 `context.json → techStack` + `patterns/` 生成。

```typescript
import request from '<request-path>'
import type { PageResult } from '<types-path>'

export interface UserQuery {
  keyword?: string
  // 分页参数名与类型以项目为准
  page: number
  size: number
}

export interface UserItem {
  id: number
  name: string
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

完整的 API 模块文件（扩展名与结构按项目技术栈）。
