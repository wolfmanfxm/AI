# ADR-003: Skill Contract 与 Orchestration 分层

## Status
Accepted (2026-08-14)

## Context

Skill 的元数据曾被分散在 4 处手工维护：`skills/*/skill.yaml`、`runtime/registry/skill-catalog.yaml`、`capabilities.yaml`、`capability-routing.yaml`。同一事实（如 `category`、`produces`、`description`）在多个文件重复定义，改一处漏一处就会漂移——`description` 甚至已在 catalog 和 capabilities 里漂移成两个不同值。

为消除漂移，最初尝试「完全单一源」：把**所有**字段都塞进 `skill.yaml`，其余文件全部由 `generate-registry.mjs` 派生。但这走向了另一个极端——把 `workflow_ref`、`requires_checkpoint`、`requires_tests`、`requires_review`、`artifact_output` 这些**编排字段**也塞进了 `skill.yaml`，而它们的权威本已存在于 `workflow-library.yaml`（`used_by`）和 `gates.yaml`（`checkpoint.require_approval` / `safety.require_tests` / `release.require_review`）。结果不是消除多头权威，而是**新增**了多头权威。

## Decision

治理目标是「**同一个事实只在一个地方被人工定义**」，而非「**所有配置文件只剩一个**」。

据此把字段分成两类权威源：

```
┌───────────────────────────┐     ┌──────────────────────────────┐
│  skill.yaml               │     │  workflow-library.yaml        │
│  = Skill Contract         │     │  gates.yaml                   │
│  （intrinsic）             │     │  profiles.yaml                │
│                           │     │  = Orchestration             │
│  identity description     │     │  （suite-level）               │
│  intent capabilities      │     │                              │
│  consumes produces        │     │  workflow_ref / used_by       │
│  triggers complexity      │     │  checkpoint/gate policy       │
│  cost confidence          │     │  pipeline position            │
│  stages quality_gate      │     │  profile 激活范围              │
│  context_contract         │     │                              │
└───────────────────────────┘     └──────────────────────────────┘
```

### 判别规则

问一句：**「这个字段脱离 project-suite，单独拿这个 Skill 仍然成立吗？」**

- **成立 → skill.yaml**（intrinsic）：description、intent、capabilities、consumes、produces、triggers、complexity、cost、confidence、stages、quality_gate、context_contract。
- **不成立 → Runtime / Workflow**（orchestration）：workflow_ref、stage_ref、pipeline position、routing priority、checkpoint policy、profile 激活范围。

### 权威映射

| 事实 | 唯一权威 | 说明 |
|------|---------|------|
| skill 是什么/能做什么/需要什么 | `skills/*/skill.yaml` | Skill Contract（intrinsic） |
| 依赖边（DAG） | `produces`/`consumes` 自动推导 | 不是 skill.yaml 的 `depends_on` |
| 并行关系 | 同 wave 内无依赖即并行（推导） | 不是 skill.yaml 的 `parallel_with` |
| 路由/调度顺序 | `scheduler.yaml` 的 `skill_order` | 不是 skill.yaml 的 `decision_order`/`priority` |
| 版本兼容约束 | `compatibility.yaml` 的 `matrix` | 不是 skill.yaml 的 `depends_on_skill` |
| 走哪条 workflow | `workflow-library.yaml`（`used_by`） | 不是 skill.yaml 的 `workflow_ref` |
| gate/checkpoint 阈值 | `gates.yaml` | 不是 skill.yaml 的 `requires_*` |
| 任务复杂度 → 激活哪些 skill | `profiles.yaml` | Profile 编排 |
| 派生产物 | `generate-registry.mjs` → skills.generated / catalog / capabilities / routing | 不手写 |

## Consequences

### 正向
- **消除多头权威**：每个事实只有一个手工权威，其余全由生成器派生。
- **skill 可移植**：skill.yaml 不含 suite 编排依赖，单独拿到别的 suite 仍然成立。
- **改动涟漪隔离**：workflow 库演进不改 skill 定义，skill 定义演进不破坏编排。
- **无循环依赖**：分层后 skill.yaml 不再引用 workflow-library（`workflow_ref` → `used_by` 的双向引用被打破）。

### 负向
- **两个源需协调版本**：改 workflow 时需同时确认 skill 的 stages 与 workflow 的 stages 一致（但这是「一致性检查」，不是「重复定义」）。
- **心智成本**：需记住判别规则，而非「一个文件装一切」的简单模型。

## Alternatives Considered

- **完全单一源（所有字段塞 skill.yaml）**：表面简单，实际把 orchestration 改动涟漪灌进 skill 定义，且产生 skill.yaml ↔ workflow-library 的双向引用环。被拒绝。
- **每个 skill 一个目录装全部**：物理聚合但逻辑仍混，且不便跨文件派生。被拒绝。
- **分层（本方案）**：Skill Contract 与 Orchestration 各一个权威，无字段重叠，符合「同一个事实只定义一次」。

## Related
- [generate-registry.mjs](../../shared/scripts/generate-registry.mjs) — 生成器，只从 skill.yaml 派生 intrinsic
- [skills.generated.yaml](../../runtime/registry/skills.generated.yaml) — 派生的 per-skill 单一源
- [workflow-library.yaml](../../runtime/registry/workflow-library.yaml) — workflow 编排权威
- [gates.yaml](../../runtime/config/gates.yaml) — gate/checkpoint 权威
- [profiles.yaml](../../runtime/config/profiles.yaml) — profile 编排权威
- [ADR-001](ADR-001-knowledge-first.md) — Knowledge First（produces/consumes 是 Capability 类型，不写路径）
