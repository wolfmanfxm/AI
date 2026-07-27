# Main Prompt — Planner

> 入口 prompt。根据用户输入类型，路由到对应的专用 prompt。

## 路由规则

| 用户意图 | 路由到 |
|---------|--------|
| 任务拆解、功能分解 | [task-breakdown.md](task-breakdown.md) |
| 工作量评估、排期 | [estimation.md](estimation.md) |
| 两者都需要 | 先 task-breakdown → 再 estimation |

## 要求

1. 读取用户输入，判断意图类型
2. 加载对应专用 prompt
3. 遵循 SKILL.md 中的完整工作流（Discover → Execute → Output）
4. 产出 PLAN.md，格式见 SKILL.md
