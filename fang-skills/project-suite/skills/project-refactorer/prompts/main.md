# Main Prompt — Refactorer

> 入口 prompt。根据重构意图路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| 提取函数/组件/Composable | [extract-method.md](extract-method.md) |
| 简化条件/循环/重复逻辑 | [simplify-logic.md](simplify-logic.md) |
| 重命名/移除死代码/拆分模块 | 在 main 中直接处理 |
| 综合重构 | extract-method → simplify-logic（按需组合）|

## 前置要求

1. 读被测代码 + 已有测试
2. 无测试 → 先加表征测试（见 [safety-protocol](../references/safety-protocol.md)）
3. 🔴 CHECKPOINT：确认重构范围

## 要求

遵循 SKILL.md 中的安全重构协议。每次一个动作，可独立回滚。
