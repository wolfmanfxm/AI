# Orchestrate — Pipeline Orchestrator v2.0

> @template: execution
> v2.0: Decision-Boundary Checkpoint。是否自动推进（auto-advance）是 Host capability，非 Suite 能力；profile 声明「希望哪些点是决策边界」，Host 决定实际是否自动推进。

## Actions

按 pipeline 定义的路径，逐 Skill 建议推进，在 Decision Boundary 暂停确认：

```
for each skill in pipeline:
  1. ENTRY: 验证上游产出就绪
     - 上游 Skill 的 required_outputs 全部存在 → ✅ 自动进入
     - 缺失 → ⚠️ 标注缺失，AskUserQuestion：跳过/重试上游/终止

  2. DISPATCH: 建议下一步 Skill（由 Host/用户决定是否执行）
     - 提示: "建议下一步: /project-<skill> — <description>"

  3. CHECKPOINT: 仅在 Decision Boundary 暂停（非每 skill）
     - 展示 Summary: <skill> 完成 | confidence: XX% | 产出: <files>
     - AskUserQuestion: "✅ 继续 / 🔧 调整 / ❌ 终止"

  4. ADVANCE: 用户确认 → 进入下一个 Skill
     - 写 pipeline-state.json checkpoint
     - 验证产出文件存在

  5. RESUME: 中断后恢复
     - 读 pipeline-state.json → 从第一个 status=pending 的 Skill 继续
```

### Decision-Boundary Gate（profile 决定哪些点是决策边界）

> 不是每个 skill 都 checkpoint。默认决策边界：planner（Goal/Scope）、architect（选型）、reviewer（是否修复）、releaser（发布确认）。其余默认「建议自动推进」（auto_advance_preference），Host 决定是否真的自动推进，除非 profile/workflow 显式标记。

| Skill | 若为决策边界，展示什么 |
|-------|----------------------|
| analyzer | graph.json + context.json 就绪 |
| planner | PLAN.md 摘要（9模块+估时+风险） |
| architect | ARCHITECTURE.md 摘要（决策数+模块图） |
| generator | 生成文件清单 + Verify 结果 |
| tester | TEST-REPORT.md 摘要（覆盖率+失败分析） |
| reviewer | REVIEW.md 摘要（BLOCKER/HIGH/MEDIUM/LOW） |
| refactorer | REFACTOR.md 摘要（Before→After 指标） |
| documenter | 文档文件清单 |
| releaser | 版本号 + Changelog 摘要 |

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
