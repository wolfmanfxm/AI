# Stage Template: Discovery

> Engine 拥有。Skill 通过 `@engine: discovery` 引用，只需提供 Actions/Exit/Failure。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | 用户触发 {skill_name} 需求（匹配触发词） |
| Input  | 参见 skill.yaml `interface.inputs` — P0 缺失则 BLOCKED |
| Output | manifest.json (status=discover) + 阶段确认产物（如 analysis-config.json） |
| Recovery | 读 manifest.json → 若 status=discover 且产物已存在 → 跳过信息收集，直入 CHECKPOINT |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 本 Skill 在 Discovery 阶段的具体步骤（编号列表） |
| **Exit**    | 本阶段退出条件（可验证的断言，如 `framework identified, scope confirmed`） |
| **Failure** | 本阶段失败场景 + 处理策略（用 `→` 连接条件与动作） |

## CHECKPOINT

Discovery 完成后必须 CHECKPOINT → [checkpoint-pattern](../../../shared/conventions/checkpoint-pattern.md)

用户的确认是本阶段的 Gate：未确认 → 不可进入下一阶段。

## 示例：Analyzer 的 Discovery

```markdown
### Stage: Discovery
@engine: discovery

| Actions  | 1. 探测技术栈、目录结构、Vault 路径 2. AskUserQuestion 确认项目名/深度/范围 3. 写入 analysis-config.json + manifest.json |
| Exit     | framework identified, package manager identified, scope confirmed, config written |
| Failure  | 无 package.json → AskUserQuestion 手动指定框架; 权限不足 → 🔴 BLOCKED |
```
