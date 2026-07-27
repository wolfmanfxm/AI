# Orchestration

> 跨 skill 工作流编排。DAG 从 `runtime/registry/capabilities.yaml` 自动推导，Scheduler 执行调度。

## DAG 构建

Scheduler 读取 `capabilities.yaml` → 按 produces/consumes 自动构建依赖图：

```
若 skill_B.consumes 包含 skill_A.produces 的任一类型 → A → B
```

## 当前 DAG（v0.6.0）

```
Wave 1: analyzer ───────────────────── (无依赖)
         │ produces: KnowledgeBase, Context
         ↓
Wave 2: planner ────────────────────── (consumes: KnowledgeBase, Context)
         │ produces: Plan
         ↓
Wave 3: architect ──────────────────── (consumes: KnowledgeBase, Plan)
         │ produces: Architecture
         ↓
Wave 4: generator ──────────────────── (consumes: KnowledgeBase, Plan, Architecture)
         │ produces: Code
         ↓
Wave 5: tester ─────────────────────── (consumes: Code)
         │ produces: Test
         ↓
Wave 6: reviewer ───────────────────── (consumes: Code, Test)
         │ produces: Review
         ↓
Wave 7: refactorer ┊ documenter ────── 并行（无互依赖，独立 consumes）
         │             │
         │ produces:   │ produces:
         │ RefCode      │ Documentation
         ↓             ↓
Wave 8:          releaser ──────────── (consumes: Documentation, Review, Test)
```

## 并行检测

```
同 Wave 条件:
  skill_B 的所有 consumes 已被前序 Wave 满足
  && skill_B 不依赖 skill_C
  && skill_C 不依赖 skill_B
  → B ∥ C 同 Wave 并行
```

## 编排原则

1. **不自动级联** — 上游完成后建议用户，不自动触发下游
2. **数据文件传递** — skill 间通过 context.json + 产出文件通信
3. **可跳过** — 用户可跳过任意环节
4. **并行优先** — 同 Wave 无依赖的 skill 并行 execute

## 轻量/重构/发布流程

```
轻量: generator → reviewer
重构: analyzer → refactorer → tester → reviewer
发布: reviewer → documenter → releaser
```

## 编排信号

上游 skill 写入 manifest `nextSuggestion` → 用户看到下一步建议。不自动级联。
