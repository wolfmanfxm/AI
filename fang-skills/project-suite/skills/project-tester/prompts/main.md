# Main Prompt — Tester

> 入口 prompt。根据测试类型路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| 为函数/方法写单元测试 | [unit-test.md](unit-test.md) |
| 为 Vue 组件写测试 | [component-test.md](component-test.md) |
| 为整个模块规划测试 | [test-strategy.md](test-strategy.md) |
| API/集成测试 | 在 main 中直接处理 |

## 前置要求

1. 检测测试框架（读 package.json）
2. 读 1-2 个现有测试文件了解风格
3. Mock 策略参考 [mock-strategy](../references/mock-strategy.md)

## 要求

遵循 SKILL.md 中的完整工作流：检测环境 → 分析代码 → 生成测试 → 运行 → 报告。
