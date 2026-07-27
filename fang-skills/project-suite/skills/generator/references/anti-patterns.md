# Anti-Patterns — Generator

> 执行 generator 时的禁止操作。每条基于真实踩坑记录。

## 通用反例

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 不读 .project-knowledge/ 就开始写代码 | 先读对应的模式文档，理解项目怎么写 |
| 2 | 凭记忆使用 Element Plus / Vue 3 API | 查项目实际使用方式，不同项目封装不同 |
| 3 | 重新实现项目中已存在的组件 | 查 components/catalog.md，复用已有 |
| 4 | 引入项目中未使用的新依赖 | 用已有依赖实现，确实要加依赖标注 TODO |
| 5 | 生成只有 happy path 的代码 | 包含 loading / empty / error 三态 |
| 6 | import 路径按个人习惯（`../../` vs `@/`） | 必须与项目现有 import 风格一致 |
| 7 | 不定义 TypeScript 类型，到处 `any` | 为参数和返回值定义明确类型 |
| 8 | API 调用不用项目的 request 封装 | 读 api/request.md，用项目封装 |
| 9 | 生成代码后不做自检 | 过一遍自检清单 |

## 组件生成反例

| # | 反模式 | 正确做法 |
|---|--------|---------|
| 1 | Props 用 `defineProps(['name'])` 不写类型 | `defineProps<{ name: string }>()` |
| 2 | 组件内直接调 API | 通过 props 传入或 composable 封装 |
| 3 | 忘了 `v-loading` 和空状态 | 表格/列表必须有 loading + empty |
| 4 | 事件名用 camelCase | Vue 3 事件用 kebab-case |
| 5 | 复制项目代码但不理解就改 | 理解模式后再套用，不确定的标注注释 |

## API 模块反例

| # | 反模式 | 正确做法 |
|---|--------|---------|
| 1 | 分页参数用 `page` / `pageSize` | 用项目实际参数名（可能是 `pageindex` / `pagesize` 或字符串类型） |
| 2 | 不导出类型定义 | 所有请求/响应类型必须 `export` |
| 3 | 在 API 层做错误 toast | 让调用方决定错误处理，API 层只管请求 |

## 安全反例

| # | ❌ 不要做 | ✅ 正确做法 |
|---|----------|-----------|
| 1 | 在前端代码中硬编码 API Key / Secret | 使用环境变量 |
| 2 | 不做输入校验直接传后端 | 前端基础校验 + 后端深度校验 |
| 3 | v-html 直接渲染用户输入 | 使用 DOMPurify 或转义 |
