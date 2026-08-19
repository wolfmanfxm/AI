# Scheduler v1.0

> 调度策略已迁移至机器可读配置。本文件保留为设计文档。
> **配置入口：** `runtime/config/scheduler.yaml`
> **编排协议：** `runtime/protocols/orchestration.md`（User-as-Dispatcher）
> **用户始终是 Dispatcher。不自动级联。**
> 历史 DAG 模式已废弃，见 [docs/archive/dag-scheduler.md](../../docs/archive/dag-scheduler.md)。

## 正式模型

```
Intent
  ↓
Skill Resolver（意图 → skill）
  ↓
Knowledge Resolver（skill + 任务 → 知识）
  ↓
Decision（基于知识决策）
  ↓
Workflow Recommendation（建议执行路径）
  ↓
Host / User Dispatch（用户决定，不自动级联）
```

## 续执行判定

| 状态 | 行为 |
|------|------|
| `partial` | 跳过 completed，执行 pending |
| `interrupted` | 同 partial，校验 `.tmp` 清理 |
| `in_progress` | 视为异常中断，同 partial |

## 调度建议（供 Host 参考，非强制）

1. **context.json 优先** — 下游 skill 先读 context，不存在才降级
2. **能力满足优先** — produces/consumes 满足的 skill 优先
3. **Confidence Gate** — 上游 confidence 不达标 → 🟠 GATE 或 🔴 BLOCK（Host 决定是否强制）
4. **用户意图优先** — 精确匹配触发词 > 上下文推断 > 链式推断

→ Confidence Gate 详细规则：[confidence-gate.md](confidence-gate.md)
