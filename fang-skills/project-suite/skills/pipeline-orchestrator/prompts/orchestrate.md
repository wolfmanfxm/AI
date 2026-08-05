# Orchestrate — Pipeline Orchestrator v2.0

> @engine: execution
> v2.0: Auto-advance + per-skill Checkpoint gate。Runtime 自动调度，每步等用户确认。

## Actions

按 pipeline 定义的 DAG 顺序，自动推进 + 每步 Checkpoint：

```
for each skill in pipeline:
  1. ENTRY: 验证上游产出就绪
     - 上游 Skill 的 required_outputs 全部存在 → ✅ 自动进入
     - 缺失 → ⚠️ 标注缺失，AskUserQuestion：跳过/重试上游/终止

  2. EXECUTE: 触发 Skill
     - 提示: "下一步: /project-<skill> — <description>"
     - ⚡ Auto-advance: 若该 Skill 标记 auto_advance=true，跳过等待，直接进入执行

  3. CHECKPOINT: 每 Skill 完成后暂停
     - 展示 Summary: <skill> 完成 | confidence: XX% | 产出: <files>
     - AskUserQuestion: "✅ 继续 / 🔧 调整 / ❌ 终止"

  4. ADVANCE: 用户确认 → 进入下一个 Skill
     - 写 pipeline-state.json checkpoint
     - 验证产出文件存在

  5. RESUME: 中断后恢复
     - 读 pipeline-state.json → 从第一个 status=pending 的 Skill 继续
```

### Per-Skill Gate

| Skill | Auto-advance? | Checkpoint 展示 |
|-------|--------------|----------------|
| analyzer | No | knowledge-graph.yaml + context.json 就绪 |
| planner | No | PLAN.md 摘要（9模块+估时+风险） |
| architect | No | ARCHITECTURE.md 摘要（决策数+模块图） |
| generator | No | 生成文件清单 + Verify 结果 |
| tester | No | TEST-REPORT.md 摘要（覆盖率+失败分析） |
| reviewer | No | REVIEW.md 摘要（BLOCKER/HIGH/MEDIUM/LOW） |
| refactorer | No | REFACTOR.md 摘要（Before→After 指标） |
| documenter | No | 文档文件清单 |
| releaser | No | 版本号 + Changelog 摘要 |

### Background Tasks（自动，无 Checkpoint）

Pipeline 结束后自动触发 → [background pipeline](../../../runtime/pipeline/background.yaml)：

```
Knowledge Scan → Decay Check → Graph Refresh → Index Refresh → Promotion Review
```

### Exit

- Pipeline 中所有 Skill 执行完成
- pipeline-state.json status = completed
- Background pipeline 已触发

### Failure

| Condition | Action |
|-----------|--------|
| 上游产出缺失 | DEGRADED → 标注 + AskUserQuestion |
| Skill 执行失败 | DEGRADED → 记录 confidence + AskUserQuestion: 重试/跳过/终止 |
| 用户终止 | pipeline-state.json status = interrupted → 下次 resume |
