# Stage Template: Execution

> Suite 拥有（Protocol）。Skill 通过 `@template: execution` 引用，只需提供 Actions/Exit/Failure。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | 前置阶段全部完成（CHECKPOINT 已确认），所有 Input 已就绪 |
| Input  | 参见 skill.yaml `interface.inputs` + 前置阶段的 Output |
| Output | 本 Skill 的核心产出（参见 skill.yaml `interface.outputs`），manifest.subtasks 全部 completed/failed |
| Recovery | 读 manifest.json → 跳过 completed/failed subtasks → 只执行 pending/in_progress → [checkpoint protocol](../../../runtime/mechanisms/checkpoint.md) |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 本 Skill 在 Execution 阶段的具体步骤（可含并行/子 agent/维度表） |
| **Exit**    | 本阶段退出条件（所有产出已验证存在，confidence 已计算） |
| **Failure** | 本阶段失败场景 + 处理策略（引用 error-recovery 等级：DEGRADED/BLOCKED） |

## Sub-task 模式

若 Execution 含多个独立子任务：
- 无依赖子任务 → 并行执行
- 有依赖子任务 → 分 Wave 执行
- 每 Wave 完成后写 checkpoint
- 详见 [checkpoint protocol](../../../runtime/mechanisms/checkpoint.md)

## 示例：Analyzer 的 Execution

```markdown
### Stage: Execution
@template: execution

| Actions  | 按 scope、mode 并行 spawn 7 维度 agent + 变更分析。Agent 协调规则：禁止提前返回 → 全部完成后一次性写入 → 写入后 ls -la 验证 ≥100 bytes |
| Exit     | 所有维度 completed 或 gracefully failed，文件已验证存在 |
| Failure  | agent 超时 → retry once，仍失败标注 ❌ FAILED，主流程补写 |
```
