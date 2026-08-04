# Stage Template: Graph Analysis

> Engine 拥有。Graph 依赖分析 — Skill 通过 `@engine: graph-analysis` 引用。

## Standard Contract

| Field | Value |
|-------|-------|
| Entry  | 现状核实完成（如有），范围已最终确认 |
| Input  | graph.json（由 analyzer 生成） |
| Output | Graph 分析结果（耦合度/跨层依赖/影响范围/循环依赖） |
| Recovery | 读 manifest.json → 若已分析 → 跳过，直入 CHECKPOINT |

## Custom Fields (Skill Must Provide)

| Field | Description |
|-------|-------------|
| **Actions** | 具体查询：`findDependencies` / `findConsumers` / `findProducers` / 循环依赖检测 |
| **Exit**    | 用户确认分析结果，范围已根据分析调整 |
| **Failure** | graph.json 不可用 → grep import 手动分析 |

## Graph Query Protocol

→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)

标准查询：
- `findDependencies(<模块>)` — 模块耦合度
- `findConsumers(<API>)` — 修改影响范围
- `findProducers(<模块>)` — 已有上游
- 循环依赖检测 — `A→B 且 B→A` → 标注架构风险

## 示例：Architect 的 Graph 分析

```markdown
### Stage: Graph Analysis
@engine: graph-analysis

| Actions  | 1. `findDependencies(<目标模块>)` → 耦合度 2. 全图 edges 按 group 聚合 → 识别跨层依赖(view→infrastructure) 3. `findConsumers(<目标API>)` → 影响范围 4. 循环依赖检测 |
| Exit     | 用户确认分析结果，设计范围已调整 |
| Failure  | graph.json 不可用 → grep import 手动分析依赖链 |
```
