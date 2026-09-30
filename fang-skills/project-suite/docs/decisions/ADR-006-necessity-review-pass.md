# ADR-006: 必要性检查以「审前 pass」吸收，而非把五轴扩成六轴

## Status

Accepted (2026-09-30)

## Context

「review 增加一个复杂度/必要性维度」：审"新增 abstraction 有第二消费者吗？新增 config 真需要变吗？新增 dependency 有 stdlib/原生替代吗？新增 file/layer 有真实 Producer+Consumer 闭环吗？"。

最初建议（=「放进现有 reviewer 五轴里扩成一轴」）方向正确，但落地时暴露一个结构约束：套件把 reviewer 的**轴数当 frozen 结构契约**——`skills/project-reviewer/skill.yaml`/`skill-ir.yaml`、`runtime/registry/skills.generated.yaml`、`capability-routing.yaml`、`capabilities.yaml`、`docs/benchmarks.md`（`sections: [正确性, 安全性, 可读性, 架构, 性能]`）、`workflow-protocol/qa-pattern.md`/`validation.md`（"五轴全覆盖"）等 ~20 处硬编码 5 轴，且 `skill-ir`/`skills.generated` 是生成产物。

若把"五轴"硬改为"六轴"，需连带重构 ~20 个文件 + 重新生成两个 registry + 改 benchmarks 契约和 validation 矩阵（"findings_per_axis: 1"、"五轴全覆盖"）——而套件自身原则正是"新增 config/依赖/抽象必须先证明必要"（[Reuse Check Create Gate](ADR-007-prerequisite)）。硬推六轴 = 用违背最小化的方式去吸收"反过度设计"，自相矛盾。

## Decision

**五轴保持 frozen。必要性检查作为独立于五轴的「审前 pass」加入 reviewer——Question existence FIRST，先于五轴扫描执行。**

- `skills/project-reviewer/prompts/execution.md`：新增 `### 1. 必要性检查（Existential Gate，先于五轴）`，含 5 个必要性钩子；原五轴顺移为 `### 2`，后续小节序号整体顺移。
- `skills/project-reviewer/prompts/main.md`：审查流程加一步"必要性检查"。
- `shared/primitives/reuse-check.md`（v2.1）：CREATE 唯一通路加 Create Gate（stuib 语言 stdlib → 平台原生 → 已有依赖 → 最小实现），并显式前置「先理解真实调用流，再判」。
- `README.md`：确立 `Fewest Necessary Changes` 显式原则。
- `docs/architecture.md`：立硬边界——Suite 永不通过 SessionStart/UserPromptSubmit 常驻注入行为（Runtime = Protocol）。

### 为什么是"pass"而非"第 6 轴"

| 维度 | 轴 | 审前 pass |
|------|-----|-----------|
| 时序 | 与正确性/性能平行 | **先于**五轴，Question existence first |
| 关注 | 审"做对了吗" | 审"这层/这改动**该不该存在**" |
| 结构契约（轴数/SSOT） | 需要改 ~20 文件 + 重生成 registry | **零改动**，不破坏 frozen 契约 |
| 落入 severity 体系 | 混入五轴分级 | 独立，命中即标 🟡/🟠/🔴 |

## Consequences

### 正向
- **SSOT 零漂移**：不动轴数、不动 benchmarks 契约、不重生成 registry。`generate-skill-ir.sh --check` 通过。
- **更贴 Ponytail 本意**："先理解问题再做最小化"，审前 pass 正是"先追问存在性再审实现"的顺序。
- **天然与 SSOT/drift 检查同向**：necessity 钩子里第 3/4 条（依赖替代、ProsConsumer 闭环）正是现有 drift 体系的前置哨兵。
- **可逆**：若未来确有理由升级为第 6 轴，pass 的 5 个钩子可直接平移。

### 负向
- **轴数与"五轴全覆盖"validation 不反映 necessity**：necessity 命中不进入 benchmarks 的每轴计数，结构契约层面看不到它。
- **两处落点需记住**：necessity 钩子定义在 execution.md，而其判据源头在 reuse-check.md 的 Create Gate——需理解两者是同一判据的前/后扩展。

## Alternatives Considered

- **硬改"五轴→六轴"**：需回关 ~20 文件 + 重生成 registry + 改 benchmarks/validation。被拒绝——违背套件最小化与 SSOT 原则。
- **新建复杂度 review skill**：新增 layer/artifact，违反"不再加一层"。被拒绝。
- **照搬 Ponytail debt 目录 / shortcuts-ledger**：已有 waiver-policy `expires` 覆盖 upgrade trigger，重复。被拒绝。
- **审前 pass（本方案）**：零结构契约改动，收获必要性审前顺序。当选。

## Related
- [execution.md · Existential Gate](../../skills/project-reviewer/prompts/execution.md) — 必要性钩子实现
- [reuse-check.md · Create Gate](../../shared/primitives/reuse-check.md) — 判据源头（stdlib/原生/依赖→最小实现）
- [benchmarks.md](ADR-006-necessity) → [benchmarks.md](../benchmarks.md) — 冻结的五轴契约，本 ADR 不改动
- [architecture.md · 硬边界](../../docs/architecture.md) — Suite 永不常驻注入行为
- [ADR-003](ADR-003-skill-contract-vs-orchestration.md) — 同一事实单一权威的前例