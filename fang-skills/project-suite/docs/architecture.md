# Suite Architecture v1.0.0

> project-suite 架构设计决策记录。
> Knowledge-driven Agent Framework：知道什么时候用哪个 Skill，执行这个 Skill 需要什么知识。

## 全链路架构

```
                          User Intent
                               │
                               ▼
                     ┌─────────────────────┐
                     │   Skill Resolver    │
                     │   "谁来做？"          │
                     │   skill-catalog.yaml │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │  Knowledge Resolver │
                     │  "需要知道什么？"     │
                     │  context-resolver   │
                     │  + knowledge-graph   │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │  Decision Engine    │
                     │  "应该怎么做？"       │
                     │  completeness-check │
                     │  + project-principles │
                     └──────────┬──────────┘
                                │
                     ┌──────────┴──────────┐
                     │                     │
               confidence≥0.9        confidence<0.9
                     │                     │
                     ▼                     ▼
                Direct Plan      Adaptive Interview
                     │              (≤5 questions)
                     │              budget用完→Assumption
                     │                     │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │    Execution        │
                     │    + Checkpoint     │
                     │    10 Skills        │
                     │    + Verify(9/10)   │
                     │    + session-snapshot│
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │  Review / Converge  │
                     │  cross-artifact     │
                     │  + Decision Record  │
                     └──────────┬──────────┘
                                │
                                ▼
                     ┌─────────────────────┐
                     │   Reflection        │
                     │   + Promotion       │
                     │   candidate→verify  │
                     │   →accepted→vault   │
                     │   + Decay Engine    │
                     └─────────────────────┘
```

## 七层职责

| 层 | 组件 | 回答 | 实现 |
|----|------|------|------|
| **Skill Resolver** | skill-catalog.yaml + capability-routing.yaml | 谁来做？ | 10 skills, 6 categories, intent→capability 映射 |
| **Knowledge Resolver** | context-resolver.md + graph.json | 需要知道什么？ | Task→tags→Query→Top-K injection |
| **Decision Engine** | completeness-check + project-principles + Adaptive Interview | 应该怎么做？ | 多维评分→confidence→0/2/5 questions→Assumption |
| **Execution** | 10 Skills + workflow-engine + Verify(9/10) + session-snapshot | 怎么执行？ | Stage Injection + Candidate→Verify + 跨session resume |
| **Review** | cross-artifact analyzer + Decision Record | 做对了吗？ | spec↔plan↔architecture↔tasks 语义一致性 |
| **Reflection** | promotion-reviewer + instinct-extractor + decay-engine | 值得保留吗？ | CrossProject/Reusability评分→auto_promote/manual confirm |
| **Governance** | conformance(G1-G17) + drift(40/40) + trust(90/100) | 持续可信吗？ | 10/10 governed boundary |

## Skill Ecosystem 三件套

借鉴 awesome-claude-skills：Skill 必须可发现、可描述、可分类、可验证、可评估、可复用。

| 能力 | 实现 |
|------|------|
| **可发现** | Skill Catalog（skill-catalog.yaml: 10 skills, 6 categories, complexity, use_cases） |
| **可描述** | Skill IR（skill-ir.yaml: id/version/produces/consumes/stages/verification/evidence/exit/failure） |
| **可分类** | Categories（analysis/planning/creation/verification/evolution/orchestration） |
| **可验证** | Skill Validator（G1-G17 conformance + drift + trigger-eval + artifact-consistency） |
| **可评估** | darwin-skill 9-dim rubric（avg 84.2）+ dim8 full_test（3/10） |
| **可复用** | Pipeline Orchestrator（5 pipeline modes + per-skill checkpoint；auto-advance 仅 background profile） |

## 关键数据

```
Skills: 10 | Gates: 0/0 | Drift: 40/40 | Trust: 90/100
Verify: 9/10 | @adapter: 27 refs | Skill IR: 10/10
Context Resolver: 10/10 | Rationalizations: 10/10
Decision Record: 3/3 | Completeness Check: ✅
Session Snapshot: 3/3 (analyzer/planner/generator)
Background Pipeline: ✅ | Decay Engine: ✅
```

## v2.0 方向

v1.0 的 Runtime 本质是 Workflow Runtime（流程执行器）。v2.0 目标：Knowledge Runtime（知识驱动决策）。

| 能力 | v1.0 状态 | v2.0 目标 |
|------|----------|----------|
| **Perception** | 分散在各 Skill Discovery | 探索方向：统一 Perception 层（Intent → Domain → Tech → Need） |
| **Context Resolver** | ✅ 10/10 | — |
| **Tool Resolver** | ✅ adapter-registry 已定义，Skill 声明 `@adapter:` | — 不继续做。adapter 声明式映射足够，不需要 AI 推理 |
| **Workflow Resolver** | orchestrator 选 pipeline（5 模式）+ profiles.yaml | 动态规划（Bug→Reviewer, Feature→Planner+Architect） |
| **Promotion Resolver** | ✅ Phase 8 | — |
| **Execution** | ✅ 10 Skills + workflow-engine | — |
| **Learning** | ✅ Extract→Verify→Promote→Decay | — |

### 决策链（v2.0 目标形态）

```
感知 → 理解任务 → 查询知识 → 选择工具 → 规划流程 → 执行 Skill → 抽取知识 → 评估价值 → 沉淀知识
```
