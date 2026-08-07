# Execution Driver v1.0

> Stage 执行循环 — Engine 驱动阶段推进，不依赖 Claude 自行判断。

## 核心循环

```
for each stage in skill.yaml interface.stages:
  ┌─────────────────────────────────────────┐
  │ 1. ENTRY — 检查进入条件                   │
  │    ├─ 前置 stage 的 exit 条件全部满足？     │
  │    ├─ 该 stage 的 input 全部可达？         │
  │    └─ 不满足 → BLOCK 或 DEGRADED         │
  ├─────────────────────────────────────────┤
  │ 2. LOAD — 加载模板 + 业务逻辑               │
  │    ├─ stage-templates/<name>.md          │
  │    ├─ prompts/<name>.md                  │
  │    └─ 合并 = 完整 Stage Contract          │
  ├─────────────────────────────────────────┤
  │ 3. EXECUTE — 执行 Actions                │
  │    ├─ 按 prompts/ 中的 Actions 执行        │
  │    ├─ 遇 Failure → 按 Failure 表处理       │
  │    └─ 写 manifest checkpoint             │
  ├─────────────────────────────────────────┤
  │ 4. EXIT — 验证退出条件                     │
  │    ├─ prompts/ 中的 Exit 条件全部满足？    │
  │    ├─ 满足 → 5. ADVANCE                  │
  │    ├─ 不满足 + retry > 0 → 回到 3         │
  │    └─ 不满足 + retry = 0 → FAIL          │
  ├─────────────────────────────────────────┤
  │ 5. ADVANCE — 推进到下一 stage              │
  │    ├─ 写 manifest.status = <stage>_done  │
  │    ├─ 更新 confidence                    │
  │    └─ 进入下一个 stage 的 1. ENTRY         │
  └─────────────────────────────────────────┘
```

## 阶段配置

skill.yaml 中可选 `stage_config`，Engine 据此调整行为：

```yaml
# skill.yaml interface 块中新增
stage_config:
  discovery:
    checkpoint: true       # 是否需要 CHECKPOINT
    retry: 0               # exit 未满足时的重试次数
  execution:
    retry: 1
    parallel: true         # 子任务可并行
  validation:
    retry: 0
    blocking: true         # exit 未满足 → BLOCK 后续 stage
  delivery:
    retry: 1
```

默认值（未声明时使用）：

| 字段 | 默认 | 说明 |
|------|------|------|
| `checkpoint` | true | discovery/execution 默认需要 CHECKPOINT |
| `retry` | 0 | exit 不满足时重试次数 |
| `parallel` | false | 该 stage 内部子任务是否可并行 |
| `blocking` | false | exit 不满足是否阻断 pipeline |
| `auto_advance` | false | exit 满足是否自动进入下一 stage（无需 CHECKPOINT） |

## Entry 条件检查

Engine 在进入每个 stage 前检查：

```
1. 读取前一个 stage 的 manifest 状态 = <prev_stage>_done
2. 读取 skill.yaml interface.inputs — 该 stage 需要的输入
3. 验证 file-backed fixture 存在（fixture: true 的文件）
4. 缺失：
   - required=true + fixture=true → 🔴 BLOCKED (缺失关键输入)
   - required=true + fixture=false → 🟡 DEGRADED (标注后继续)
   - required=false → 🟢 SKIP (可选输入)
```

## Exit 条件验证

Engine 在 stage 执行完成后验证：

```
1. 读取 prompts/<stage>.md 中的 Exit 章节
2. 逐条验证每个 exit condition
3. 全部满足 → ADVANCE
4. 有不满足：
   - stage_config.retry > 0 → 回到 EXECUTE，retry--
   - stage_config.retry = 0 且 stage_config.blocking = true → 🔴 BLOCK pipeline
   - stage_config.retry = 0 且 stage_config.blocking = false → 🟡 标注未满足项，继续
```

## 失败处理

执行期间 failure 按 `runtime/engine/error-recovery.md` 分级处理：

| 级别 | 行为 |
|------|------|
| WARNING | 自动修复 → 继续执行 |
| DEGRADED | 标注降级 → 继续当前 stage → exit 时标注 confidence 扣分 |
| BLOCKED | 写 checkpoint → AskUserQuestion → 等待恢复 |
| FATAL | 写 checkpoint → 终止 pipeline |

## Event Bus 集成

每个步骤触发对应事件，写入 `.project-runtime/events.jsonl`：

```
ENTRY    → (无事件，或 RecoveryStarted 若从 checkpoint 恢复)
EXECUTE  → StageStarted
           → ArtifactGenerated (每个产出文件写入后)
           → CheckpointReached (CHECKPOINT 等待时)
EXIT     → GateTriggered (confidence 检查)
           → StageCompleted (全部满足) 或 StageFailed (不满足+retry=0)
ADVANCE  → PipelineAdvanced + 写入 [session snapshot](../../runtime/engine/session-snapshot.md)
           → 若 skill=analyzer + stage=delivery → trigger [background pipeline](../../runtime/pipeline/background.yaml)
           → 跨 Session Resume: 下次启动 → 读 snapshot → 从中断 Phase 继续
```

→ [Event Bus](../../runtime/engine/event-bus.md) | [Event Schema](../../shared/schemas/event.schema.json)

## 与 Stage Template Injection 的关系

Execution Driver 是 Stage Template Injection 的上层：

```
Execution Driver (本文件)
  │  控制: 何时进入、何时退出、何时推进
  ▼
Stage Template Injection (SKILL.md)
  │  提供: 每个 stage 的 Entry/Input/Actions/Output/Exit/Failure/Recovery
  ▼
Stage Templates (stage-templates/)
  │  标准: Entry/Input/Output/Recovery 默认值
  ▼
Stage Prompts (prompts/<stage>.md)
     业务: Actions/Exit/Failure 自定义值
```
