# Trigger Words — Documenter

## 中文触发词

### API 文档
- API 文档、接口文档、生成接口说明
- 给 XX 模块写文档

### README
- README、项目说明、补全 README、更新 README
- 项目介绍、快速开始文档

### 组件文档
- 组件文档、给 XX 组件写文档
- 组件说明

### 通用
- 生成文档、写文档、补文档、补充文档
- 更新文档、文档过期了

## English Triggers

- generate docs, write documentation, update docs
- API docs, API documentation
- README, update README
- component documentation, document this component

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "写 changelog" | documenter vs releaser | changelog 关联版本发布 → releaser |
| "写 ADR" | documenter vs architect | ADR 需要架构决策内容 → architect 生成，documenter 格式化 |
| "文档化这个函数" | documenter | 直接路由 |
