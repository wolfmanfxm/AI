# Trigger Words — Architect

## 中文触发词

### 技术选型
- 技术选型、选什么技术、技术方案、用什么框架
- 对比一下 XX 和 YY、哪个更好
- 推荐一个 XX 库、选型建议

### 模块设计
- 模块设计、怎么划分模块、模块怎么拆
- 系统设计、架构设计、服务拆分
- 目录结构怎么设计

### API 设计
- API 设计、接口怎么定义、RESTful 设计
- 数据模型设计、数据库设计
- 前后端接口约定

### 架构评审
- 架构评审、review 架构、看看这个设计
- 这样设计有什么问题

## English Triggers

- design architecture, system design, tech stack decision
- which framework/library to use, technology comparison
- module design, service split, API design
- database schema design, data model
- architecture review

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "设计这个系统" | architect vs planner | 关注"结构+技术选型"→ architect；"任务拆解"→ planner |
| "怎么实现这个" | architect vs generator | 关注"用什么技术/结构"→ architect；"写代码"→ generator |
| "数据库怎么设计" | architect（数据模型） vs DBA | 应用层数据模型 → architect |
