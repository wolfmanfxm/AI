# Scheduler v0.7.0

> 调度策略已迁移至机器可读配置。本文件保留为设计文档。
> **配置入口：** `runtime/config/scheduler.yaml`
> **编排协议：** `runtime/protocols/orchestration.md`（User-as-Dispatcher）
> **用户始终是 Dispatcher。不自动级联。**

## 历史（v0.4.0 DAG 模式，已废弃）

### DAG 调度

Scheduler 读取 `runtime/registry/capabilities.yaml`，按 produces/consumes 构建依赖图：

```
加载 capabilities.yaml
  → 构建 DAG（consumes 任一类型 ∈ 上游 produces → 添加边）
  → 读取 skill.yaml（parallel_with 标注并行分支）
  → 拓扑排序（Kahn's algorithm）
  → 分批执行（wave）
```

### 拓扑排序规则

```
Wave 0: 无 consumes 的 skill → 直接执行
Wave N: 所有 consumes 已在 Wave 0..N-1 中满足 → 执行
Wave N+1: 同一 Wave 内无依赖的 skill → 并行执行
```

### 当前 DAG（从 capabilities.yaml 推导）

```
Wave 1: analyzer
Wave 2: planner ────────── (依赖 analyzer)
Wave 3: architect ──────── (依赖 planner)
Wave 4: generator ──────── (依赖 architect)
Wave 5: tester ─────────── (依赖 generator)
Wave 6: reviewer ───────── (依赖 tester)
Wave 7: refactorer ┊ documenter  ← 并行（无互依赖，都依赖 reviewer）
Wave 8: releaser ───────── (依赖 documenter)
```

### 并行检测

Scheduler 自动检测：若 skill_B 和 skill_C 的所有 consumes 均已被前序 Wave 满足，且 B 不依赖 C、C 不依赖 B，则放入同一 Wave。

```
并行条件 = (B.depends_on 不含 C) && (C.depends_on 不含 B)
         && (B.consumes 全部覆盖) && (C.consumes 全部覆盖)
```

### 单 skill 调度（skill 内部）

```
触发 skill → discover（如需）→ 生成子任务列表 → 按依赖分波 → 波内并行 → 完成后报告
```

## 续执行判定

| 状态 | 行为 |
|------|------|
| `partial` | 跳过 completed，执行 pending |
| `interrupted` | 同 partial，校验 `.tmp` 清理 |
| `in_progress` | 视为异常中断，同 partial |

## 优先级

1. **context.json 优先** — 下游 skill 先读 context，不存在才降级
2. **依赖满足优先** — 所有 consumes 已就绪的 skill 优先调度
3. **并行优先** — 同 Wave 内无依赖 skill 并行 execute
4. **用户意图优先** — 精确匹配触发词 > 上下文推断 > 链式推断

## 调度日志

```json
{
  "executionLog": [{
    "startedAt": "ISO-8601",
    "finishedAt": "ISO-8601",
    "status": "completed",
    "wave": 5,
    "parallel": ["project-reviewer", "project-documenter"]
  }]
}
```
