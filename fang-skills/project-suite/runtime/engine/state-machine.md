# State Machine v0.7.0

> 两个独立的状态模型，不要混淆：

## Skill 执行状态（本文件）

所有 Skill 共享的执行生命周期。**本文件描述的是 Skill 的执行状态，不是产物的生命周期。**

## Artifact 生命周期（独立于 Skill 状态）

产出物的价值演化属于另一个模型：**Artifact → Candidate → Accepted → Deprecated**。

→ `runtime/state/schemas/knowledge-lifecycle.md`

## 历史（v0.4.0 执行状态，保留兼容）

```
idle ─→ discover ─→ confirmed ─→ in_progress ─→ completed
                       │              ↓              ↑
                       │           partial ──────────┘
                       │              ↓
                       └─────── interrupted ────────┘
```

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| `idle` | 未启动，等待触发 | 用户首次触发 skill |
| `discover` | 收集信息中（确认配置、询问用户） | skill 被触发且缺少必要配置 |
| `confirmed` | 配置完成，等待执行 | discover 阶段全部确认完成 |
| `in_progress` | 至少一个子任务已启动 | 执行阶段开始 |
| `partial` | 部分子任务完成，有未完成项 | Token 耗尽 / 超时 / 子任务部分完成 |
| `interrupted` | 外部中断（用户取消 / session 丢失） | 用户主动取消或异常断开 |
| `completed` | 全部子任务完成 | 所有子任务状态为 completed |

## 状态转换规则

### 首次执行
```
idle → discover → confirmed → in_progress → completed
```

### 中断恢复
```
partial     → in_progress → completed   (从第一个 pending 子任务恢复)
interrupted → in_progress → completed   (跳过已完成，重试未完成)
```

### 重新执行（用户确认后）
```
completed → discover → confirmed → in_progress → completed   (全量刷新)
completed → in_progress → completed                            (增量更新)
```

## 子任务状态

每个 skill 的 manifest 中维护子任务列表，各子任务独立状态：

| 子状态 | 含义 |
|--------|------|
| `pending` | 未启动 |
| `in_progress` | 执行中 |
| `completed` | 已完成 |
| `failed` | 执行失败，不阻塞其他子任务 |

## 使用约定

1. skill 在 `confirmed` 状态时写入 manifest.json，此后只更新状态字段
2. 恢复执行时，只执行 `pending` 和 `in_progress`（后者视为需重试）的子任务
3. `completed` 子任务的文件内容不会被覆盖，除非 manifest 要求全量刷新
4. 状态变更必须原子化——先写文件再执行，执行完再更新

## 与 analyzer 原有协议的关系

本文件替代 `project-analyzer/protocol/phase-1-discovery.md`、`phase-2-execution.md`、`phase-2-finish.md` 和 `runtime-protocol.md` 中的状态机部分。所有 skill 统一使用本状态机。
