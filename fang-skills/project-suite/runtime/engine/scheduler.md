# Scheduler

> 跨 skill 任务调度协议。定义 skill 执行的优先级、并发控制、续执行策略。

## 调度模式

### 单 skill 调度（skill 内部）

```
触发 skill → discover（如需）→ 生成子任务列表 → 按依赖分波 → 波内并行 → 完成后报告
```

**并发控制**：同波内子任务上限受限于 agent 并发能力（建议 ≤ 8），超出则分批执行。

### 多 skill 编排（跨 skill 工作流）

由 `runtime/protocols/orchestration.md` 定义编排链。调度器不自动触发下游 skill，只做状态传递：

```
上游 skill completed → 写入 manifest（含产出路径）
                   → 通知用户："下一步建议：[下游 skill]"
                   → 用户决定是否继续
```

## 续执行判定

### Resume 触发条件

manifest 状态为以下之一时，skill 进入恢复模式：

| 状态 | 行为 |
|------|------|
| `partial` | 跳过 completed，执行 pending |
| `interrupted` | 同 partial，额外校验 `.tmp` 文件清理 |
| `in_progress` | 视为异常中断，同 partial |

### 超时与 token 管理

```
token 剩余 > 50%  → 正常执行，不限制子任务数
token 剩余 20-50% → 完成当前子任务后，只执行有依赖的最小子任务集
token 剩余 < 20%  → 完成当前子任务后写 checkpoint，设置 status = "partial"
```

## 优先级

当多个 skill 可被触发时（用户意图模糊），路由优先级：

1. **精确匹配** — 触发词命中特定 skill → 直接触发
2. **上下文推断** — 当前有 manifest 且 status != completed → 续执行
3. **链式推断** — 上一个 skill 的 `nextSuggestion` 推荐 → 询问用户
4. **兜底** — 用户意图对应多个 skill → `AskUserQuestion` 确认

## 调度日志

每个 skill 执行完成后，在 manifest 中追加执行记录：

```json
{
  "executionLog": [
    {
      "startedAt": "2026-07-27T10:00:00Z",
      "finishedAt": "2026-07-27T10:12:00Z",
      "status": "completed",
      "subtasksCompleted": 7,
      "subtasksTotal": 8,
      "tokensUsed": 45000
    }
  ]
}
```
