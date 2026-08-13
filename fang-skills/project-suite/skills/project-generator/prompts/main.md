# Main Prompt — Generator

> 入口 prompt。根据用户要生成的代码类型，路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| 写组件/封装组件 | [component-gen.md](component-gen.md) |
| 写 API/接口层 | [api-gen.md](api-gen.md) |
| 写页面/视图 | [page-gen.md](page-gen.md) |
| 写工具函数/类型 | 直接生成，参考 patterns/typescript.md（若存在） |

## 前置要求

启动前必须：
1. `@adapter:knowledge.query --type pattern,component,convention --scope project` 定位相关模式
2. 按 SKILL.md 中的读取策略加载对应知识（不读 .md，走 Query API）
3. 搜索项目中类似功能代码作为风格参考

## 要求

遵循 SKILL.md 中的完整工作流和自检清单。
