# Orchestrate — Pipeline Orchestrator

> @engine: execution

## Actions

按 pipeline 定义的 DAG 顺序，逐个 Skill 调度：

```
for each skill in pipeline:
  1. 检查上游产出是否就绪
     - analyzer → context.json + graph.json ✓
     - planner → PLAN.md (需要 context.json)
     - ... 
  2. 若上游产出缺失 → DEGRADED: 标注缺失，AskUserQuestion
  3. 提示用户执行该 Skill：
     "下一步: /project-<skill> — <该 Skill 做什么>"
  4. 等待用户确认该 Skill 执行完成
  5. 验证该 Skill 的产出文件存在
  6. 写 pipeline-state.json checkpoint
  7. 进入下一个 Skill
```

### 上下文传递

Pipeline 中下游 Skill 自动消费上游产出：
- `analyzer` → context.json → `planner` 读 context.json
- `planner` → PLAN.md → `architect` 读 PLAN.md
- `architect` → ARCHITECTURE.md → `generator` 读 ARCHITECTURE.md
- ...

Engine 验证每个下游的 `interface.inputs` 是否被上游满足。

### 失败处理

| 场景 | 处理 |
|------|------|
| 上游产出缺失 | 标注 DEGRADED → AskUserQuestion：跳过/重试上游/终止 |
| 中间 Skill 执行失败 | 记录 confidence → AskUserQuestion：重试/跳过/终止 |
| 用户中途暂停 | 写 pipeline-state.json → 下次 resume 从当前 Skill 继续 |

## Exit

- Pipeline 中所有 Skill 执行完成（或已记录跳过的）
- pipeline-state.json 已更新
- 所有产出文件已验证存在

## Failure

| Condition | Action |
|-----------|--------|
| 上游产出缺失 | DEGRADED → 标注 + 询问 |
| Skill 执行失败 | DEGRADED → 记录 confidence + 询问 |
| 用户终止 | 写 pipeline-state.json → 标记 status=interrupted |

## CHECKPOINT

每个 Skill 执行完成后 CHECKPOINT — 展示进度 + 下一步 Skill
