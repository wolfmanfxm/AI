# ADR-004: 四层 I/O 视图 — Capability / Artifact / Interface / Knowledge 边界

## Status
Accepted (2026-09-03)

## Context
I/O 事实曾分散在四处：`skill.yaml` 顶层 `produces/consumes`（Capability）、`artifact-types.yaml` `mapping`（Artifact Type）、`skill.yaml` `interface.inputs/outputs`（执行契约），加上 `knowledge-index → context-package` 的知识注入链。多轮「对齐」试图让前几层字面一致，反而制造语义错误——releaser 版本推荐被标成 `planning`、tester TEST-REPORT 被标成 `review`、`knowledge-index` 被硬当 Capability、`knowledge` 的 consumers 误指向下游。

## Decision
四层各司其职，**不强制字面相等**。它们回答四个不同问题：

| 层 | 载体 | 词汇 | 语义 | 消费方 |
|----|------|------|------|--------|
| **Capability** | `skill.yaml` 顶层 `produces/consumes` | KnowledgeBase / Plan / Architecture / Code / Test / Review / RefactoredCode / Documentation / Release | 能力依赖 | DAG 推导（generate-registry） |
| **Artifact** | `artifact-types.yaml` `types` + `mapping` | knowledge / context / graph / planning / design / implementation / test / review / refactored-code / documentation / release / state / request | 数据流 | Runtime 路由 |
| **Interface** | `skill.yaml` `interface.inputs/outputs` | 引用 Artifact 类型 或 Knowledge 契约标记 | 执行契约 | Host 前置检查 + LLM |
| **Knowledge** | `knowledge-index.json` → `context-package.json` | （内部运行时数据结构） | 知识注入 | Knowledge Resolver |

### 具体边界（冻结）

1. **knowledge**（Artifact 层保留）= 项目长期知识的持久化产物，`producer: project-analyzer`，`consumers: []`。下游经 Compiler→Resolver→context-package 注入，**不直接消费** knowledge。
2. **knowledge-index.json** = Knowledge Compiler 的内部索引，**不是** Artifact Type，不进路由。
3. **context-package.json** = Knowledge 注入契约（`runtime/contracts/context-package.schema.json`），`interface.inputs` 里 `type` 用专用标记 `context-package`，**不是** Artifact 层的 `context` 类型。
4. **context.json / graph.json** = Analyzer 产出的结构上下文，仍是普通 Artifact Type（`context` / `graph`）；但下游经 Resolver 注入，不作为 raw artifact 直接消费。
5. tester 输出 = `test`（含 `TEST-REPORT.md`，不新增 `test-report`）。
6. releaser 版本推荐 = `release`（非 `planning`）。
7. **Artifact Type 准入标准**：只有具备独立 Producer→Consumer 生命周期、需要 Runtime 路由/验证的东西才进入 `artifact-types.yaml`。PLAN 的 placement/target 是任务元数据（折进 `planning`）、`knowledge-index` 是编译器内部索引（不进），二者都不满足准入。

## Consequences

### 正向
- 四层各改各的，不再互相牵制；语义错误（错标 type、硬当 Capability、consumers 误指向）被单独消除。
- `knowledge-index` / `context-package` 的运行时内部性被冻结，不会被误路由成普通 Artifact。
- 「四层不强制相等」释放了之前「强制对齐」造成的额外心智负担。

### 负向
- 要记住四套词汇（Capability 名 ≠ Artifact type 名 ≠ Interface type 值），且 context-package 是 Interface 层专用标记、不属于 Artifact 层。
- 需要一致性校验时，不能再简单比对字面，而要做「类型映射」校验（Capability ↔ Artifact type 的映射表）。

## Alternatives Considered
- **强制多层字面一致**：表面简单，但把四个不同语义强行等同，导致 Knowledge 层的运行时中间产物被塞进 Artifact 路由。被拒绝。
- **只留一层（全塞 interface.inputs）**：丢失 DAG（Capability）和路由（Artifact）两个独立视角。被拒绝。

## Related
- [ADR-001](ADR-001-knowledge-first.md) — Knowledge First
- [ADR-003](ADR-003-skill-contract-vs-orchestration.md) — Skill Contract vs Orchestration 分层
- [context-package.schema.json](../../runtime/contracts/context-package.schema.json) — Knowledge 注入契约
- [artifact-types.yaml](../../runtime/artifacts/artifact-types.yaml) — Artifact Type 权威
