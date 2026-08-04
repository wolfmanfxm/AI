# Event Bus v1.0

> Stage 生命周期事件系统。监控、日志、扩展的标准化接口。
> 事件写入 `.project-runtime/events.jsonl`（JSONL 格式，追加写入）。

## 事件类型

| Event | 触发时机 | Payload |
|-------|---------|---------|
| `StageStarted` | Stage 进入 EXECUTE 步骤 | skill, stage, timestamp, manifest_snapshot |
| `StageCompleted` | Stage EXIT 全部满足 | skill, stage, timestamp, confidence, duration_ms |
| `StageFailed` | Stage EXIT 不满足 + retry=0 | skill, stage, timestamp, failed_exits[], error |
| `ArtifactGenerated` | 产出文件写入 | skill, stage, file_path, file_size, timestamp |
| `PipelineAdvanced` | 从当前 stage 推进到下一 stage | skill, from_stage, to_stage, timestamp |
| `GateTriggered` | Confidence Gate 触发 | skill, stage, gate_level(PASS/REVIEW/GATE/BLOCK), confidence, timestamp |
| `CheckpointReached` | CHECKPOINT 等待用户确认 | skill, stage, timestamp, question_summary |
| `RecoveryStarted` | 从 checkpoint 恢复执行 | skill, stage, timestamp, resume_from |

## 日志格式（JSONL）

每行一个 JSON 事件，追加写入 `.project-runtime/events.jsonl`：

```json
{"event":"StageStarted","skill":"project-analyzer","stage":"discovery","timestamp":"2026-08-04T15:30:00Z","manifest":{"status":"discover"}}
{"event":"CheckpointReached","skill":"project-analyzer","stage":"discovery","timestamp":"2026-08-04T15:30:05Z","question":"确认分析范围"}
{"event":"PipelineAdvanced","skill":"project-analyzer","from_stage":"discovery","to_stage":"execution","timestamp":"2026-08-04T15:30:10Z"}
{"event":"StageStarted","skill":"project-analyzer","stage":"execution","timestamp":"2026-08-04T15:30:10Z"}
{"event":"ArtifactGenerated","skill":"project-analyzer","stage":"execution","file":"architecture/overview.md","file_size":1234,"timestamp":"2026-08-04T15:31:00Z"}
{"event":"StageCompleted","skill":"project-analyzer","stage":"execution","timestamp":"2026-08-04T15:32:00Z","confidence":85,"duration_ms":110000}
```

## JSON Schema

[shared/schemas/event.schema.json](../../shared/schemas/event.schema.json) — 每个 event type 的结构定义。

## 集成点

1. **Execution Driver** — 在每个 ENTRY/EXECUTE/EXIT/ADVANCE 步骤写入事件
2. **Stage Templates** — ArtifactGenerated 在文件写入后触发
3. **Confidence Gate** — GateTriggered 在置信度检查时触发
4. **Checkpoint Protocol** — CheckpointReached/RecoveryStarted 在暂停/恢复时触发

## 可视化

`shared/scripts/show-events.sh` — 读取 events.jsonl，展示事件时间线和统计。

```
Event Timeline (project-analyzer):
  15:30:00  StageStarted       discovery
  15:30:05  CheckpointReached  discovery
  15:30:10  PipelineAdvanced   discovery → execution
  15:30:10  StageStarted       execution
  15:31:00  ArtifactGenerated  architecture/overview.md (1.2KB)
  15:31:30  ArtifactGenerated  components/catalog.md (15KB)
  15:32:00  StageCompleted     execution (85%, 110s)
  ...
```

## 扩展

Event Bus 为未来扩展提供 hook 点：
- **监控**: 外部工具 tail events.jsonl，实时展示执行进度
- **告警**: GateTriggered(level=BLOCK) → 通知用户
- **分析**: 聚合 events.jsonl → 计算平均 stage 耗时、失败率
- **审计**: 完整事件链 → 合规审查
