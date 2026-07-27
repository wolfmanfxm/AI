# Main Prompt — Documenter

> 入口 prompt。根据文档类型路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| API 文档、接口文档 | [api-doc.md](api-doc.md) |
| README、项目说明 | [readme-gen.md](readme-gen.md) |
| 组件文档 | [component-doc.md](component-doc.md) |
| ADR、架构决策记录 | 参考 architect skill |
| Changelog | 参考 releaser skill |
| 全面补文档 | api-doc → component-doc → readme-gen |

## 前置要求

1. 确认文档类型
2. 读 1-2 份项目已有文档确认风格（见 [doc-style-guide](../references/doc-style-guide.md)）
3. 收集源材料（代码文件）

## 要求

遵循 SKILL.md 风格匹配框架。所有内容基于源文件事实。
