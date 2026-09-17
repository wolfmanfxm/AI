# ADR-005: Skill 准入标准 — 知识/模式何时值得成为独立可发现的入口

## Status
Accepted (2026-09-17)

## Context

外部参考（cangjie-skill 的 Capability Promotion）提出：给 `promotion-reviewer` 增加
`independent_intent` / `independent_boundary` / `independent_consumption` / `reuse_value` /
`verification_value` 五维评分，输出 `KEEP_AS_KNOWLEDGE` 或 `PROMOTE_TO_CAPABILITY`。

**它指出的问题是真实的**：本仓库「capability」一词指三个不同东西——

| 出处 | 实际含义 |
|------|---------|
| `runtime/registry/capabilities.yaml` 的 `capability_types` | **工件类型**（KnowledgeBase / Plan / Code…） |
| `runtime/registry/capability-routing.yaml` 的 `routing` | **用户意图路由 + provider skill**（ProjectAnalysis / Planning…） |
| `knowledge-index.json` 的 `capabilities.*` | **知识分桶**（rules / patterns / api…） |

**但建议的落点不成立**：

1. 本仓库已有**两层**晋升，语义各不相同——
   - `promotion-rules.md` R1–R5：**项目内** Candidate → Accepted
   - `promotion-reviewer.md`：**跨项目** personal_candidate → Knowledge Vault（四维评分：
     CrossProject 35% / Reusability 30% / FrameworkCoupling 20% / EvidenceStrength 15%）

   再加一层「capability 晋升」会造出**第二张互相竞争的评分表**，与「消除边界混淆」的目标正好相反。

2. `PROMOTE_TO_CAPABILITY` 在本架构里只能等于**新建一个 skill**。而 skill 集合是受硬约束的
   （见下方成本侧），这是**低频的作者级决策**（当前 10 个 skill），不是每个 candidate 都要跑的评分维度。

3. 「知识不被消费」这个真问题**不由新入口解决**：知识经 `Compiler → knowledge-index → context-package`
   注入下游，本来就不需要独立入口。「想让知识被用上」不构成准入理由。

## Decision

> **一句话边界**：知识停留在知识层是默认状态；成为独立可发现的 skill 是**例外**，必须逐条过准入，
> 且它是 ADR 级别的作者决策，不进 analyzer 的评分流程。

### 不做什么

- **不**给 `promotion-reviewer` 增加能力评分维度（两张竞争性评分表）。
- **不**新增 Capability Bundle / capability-card 体系 / 新的 registry 文件。
  本仓库的 `capabilities.yaml` / `capability-routing.yaml` / `artifact-types.yaml` /
  `context-package.schema.json` 已承担该职责（同 [ADR-004](ADR-004-four-layer-io-boundaries.md) 第 7 条
  对 Artifact Type 的处理）。

### 准入五问（全部为「是」才考虑新建 skill；任一为「否」→ 留在知识层）

| # | 判据 | 为「否」时说明 |
|---|------|--------------|
| A1 | **independent_intent** — 有用户会用一句话直接要求它，且这句话不落进任何现有 capability 的 intent 集 | 只是现有 capability 的一个子场景 → 扩展现有 skill |
| A2 | **independent_boundary** — 有明确的「不做」，且与现有 skill 的 `boundary.md` 不重叠 | 边界与现有 skill 重叠 → 合并而非新建 |
| A3 | **independent_consumption** — 存在独立的输入/输出边界，且有独立消费场景（下游 Skill **或用户直接消费**） | 只是别的 skill 产物的一个视图 → 加一个 stage/prompt |
| A4 | **entry_value** — 有稳定、可识别的独立用户意图，值得拥有独立可发现入口 | 措辞无法稳定映射到本能力 → 并入现有 intent 集 |
| A5 | **verification_value** — 能被独立验证（有可判定的 assertion） | 无法验证 → 进不了压力测试，只会变成装饰品（见 round8 结论） |

> **A3 的「或用户直接消费」不是放宽边界，是修正错误。** 实测：`Release` 与 `RefactoredCode`
> 在 `capability-routing.yaml` 的 `needs` 里**没有任何下游 skill 消费者**（`Release` 只被 meta 编排器
> `PipelineOrchestration` 声明 needs，而后者对全部 8 个能力都声明；`RefactoredCode` 出现 0 次）。
> 按「必须有下游 skill 消费」的字面标准，现役 10 个 skill 会被否决 2 个——标准本身错了。
> 终态交付型技能的 Consumer 就是用户。

> **A4 判断「入口价值」，不判断「调用频率」**——这是刻意改掉的：
> 1. **循环论证**：触发频率在 skill 存在之前无法测量，按频率执行则任何新能力永远「证据不足」。
> 2. **自相矛盾**：现役 10 个 skill 里 releaser / refactorer / documenter 本就不是高频能力。
> 3. **代理指标偏离目标**：低频 ≠ 入口价值低，用频率代理价值会催生「为了减少 skill 而减少 skill」。
>
> **「新 skill 稀释路由准确性」这个真实担忧由 A1 承担**——A1 要求措辞不落进任何现有 intent 集，
> 那正是路由区分度的判据。A4 不重复承担它。

> A5 是**硬项**：外部参考只提了前三问，但本仓库实测（round8：14/14 机制装饰品）说明——
> **无法验证的能力不该进 skill**，它既进不了压力测试，也无法在台账里留下结论。

### 成本侧（准入时必须记账）

新增一个 skill 不是加一个目录，而是要同步 **5 处**并重新生成 registry：

```
skills/<name>/{SKILL.md, skill.yaml, skill-ir.yaml, interface.md, prompts/, references/}
runtime/registry/compatibility.yaml       ← 版本号必须登记
runtime/config/scheduler.yaml             ← skill_order 必须有条目
runtime/config/skill-policy.yaml          ← 策略条目必须存在
runtime/registry/capabilities.yaml        ← 经 generate-registry.mjs 重新生成
```

`shared/scripts/check-consistency.sh` 的 L3 / L3.5 会对缺漏**硬失败**（非警告）。
即：准入决策的价格是明确且可核算的。

### 反向：留在知识层的正常路径

不满足准入**不是降级**。知识的正常消费路径是：

```
authored .md → knowledge-compiler → knowledge-index.json → knowledge-resolver → context-package.json → 下游 Skill
```

条目留在 `patterns/` / `api/` / `decisions/` 等目录，由 Compiler 索引、Resolver 按任务注入即可。

## Consequences

### 正向
- 「capability」一词的三义被公开记录，不必再靠新层去消解。
- 准入是 ADR 级决策，**低频且可追溯**；不污染 analyzer 的评分流程。
- 成本侧被写死，新建 skill 的代价可见（5 处 + 一致性校验硬失败）。

### 负向
- 五问是**人工判定**，没有机器可判定的信号 → 无法做成自动检查脚本（做成脚本即是又一次
  「假运行能力」，参照 `knowledge-decay.md` 的诚实标注）。
- 需要人记住「知识层是默认，skill 是例外」这条默认值。

## Alternatives Considered

- **给 `promotion-reviewer` 加五维评分**（外部建议原案）：混淆了「跨项目 Vault 晋升」与
  「是否新建路由入口」两个不同的轴，且会造出第二张竞争性评分表。被拒绝。
- **建 Capability Bundle / 引入完整 RIA 体系**：本仓库已有四处声明承担该职责；且本仓库已有三个
  「声明了但没有 Consumer」的孤儿产物先例（`knowledge-graph.yaml` 从未产出、`knowledge-list.json`
  被取代、`runtime/mechanisms/decay.md` 描述未实现的引擎而被删除）。被拒绝。
- **把准入做成自动检查脚本**：当前无机器可判定信号，做成脚本会变成假能力。**待有真实误建案例
  再评估**——那时才知道该检查什么。

## Related

- [ADR-004](ADR-004-four-layer-io-boundaries.md) — 第 7 条「Artifact Type 准入标准」（同构先例）
- [skill-atlas.md](../skill-atlas.md) — 全技能地图 + 准入清单入口
- [../shared/scripts/check-consistency.sh](../../shared/scripts/check-consistency.sh) — L3 / L3.5 硬约束
- [../../skills/project-analyzer/prompts/promotion-reviewer.md](../../skills/project-analyzer/prompts/promotion-reviewer.md) — 跨项目 Vault 晋升（另一条轴，不在本 ADR 范围）
