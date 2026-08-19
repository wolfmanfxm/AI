# DAG Scheduler（历史，已废弃）

> 状态：**已废弃**。这是 v0.4.0 的 DAG 调度模式，与「User-as-Dispatcher / Adaptive Pipeline / Convergence」的正式模型冲突。
> 从 scheduler.md 移出存档。正式模型见 [orchestration.md](../../runtime/protocols/orchestration.md)。

## 废弃原因

DAG Scheduler 描述「固定 SDLC 链」（analyzer → planner → architect → generator → tester → reviewer → releaser），这与 project-suite 的核心定位冲突：

- **User-as-Dispatcher**：用户决定执行哪个 skill，不自动级联
- **Adaptive Pipeline**：Pipeline 根据任务动态决定跑哪些 skill
- **Convergence**：证据足够就停，不按固定链走完

保留本文件仅为历史追溯，不再维护。

## DAG 调度（历史设计）

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

### 当时的 DAG

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

```
并行条件 = (B.consumes ∩ C.produces == ∅) && (C.consumes ∩ B.produces == ∅)
         && (B.consumes 全部覆盖) && (C.consumes 全部覆盖)
```
