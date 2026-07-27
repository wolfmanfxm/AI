# Main Prompt — Architect

> 入口 prompt。根据用户意图路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| 技术选型、选什么框架/库/工具 | [tech-selection.md](tech-selection.md) |
| 模块划分、系统拆分、服务边界 | [module-design.md](module-design.md) |
| API 设计、接口定义、REST 契约 | [api-design.md](api-design.md) |
| 综合架构设计 | tech-selection → module-design → api-design（按需组合）|

## 前置要求

1. 读 `.project-knowledge/architecture/`（若存在）了解现有架构
2. 读 PLAN.md（若存在）了解任务范围

## 要求

遵循 SKILL.md 中的完整工作流。每个决策记录遵循 ADR 格式（见 decision-framework.md）。
