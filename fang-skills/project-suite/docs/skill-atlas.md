# Skill Atlas v0.8

> project-suite 全技能地图 — 每个 Skill 的 stage/template/capability/I/O 全景。
> 由 workflow-protocol 解释，供 Dispatcher 和自动化工具消费。

## Atlas

| # | Skill | Stages | Templates | Produces | Consumes | Dependencies |
|---|-------|--------|-----------|----------|----------|-------------|
| 1 | [analyzer](../skills/project-analyzer/SKILL.md) | discovery, execution, delivery, validation | discovery, execution, delivery, validation | KnowledgeBase, Context, Graph | — | — |
| 2 | [planner](../skills/project-planner/SKILL.md) | discovery, code-audit, execution, validation, delivery | discovery, code-audit, execution, validation, delivery | Plan | KnowledgeBase, Context, Graph | analyzer |
| 3 | [architect](../skills/project-architect/SKILL.md) | discovery, code-audit, graph-analysis, execution, validation, delivery | discovery, code-audit, graph-analysis, execution, validation, delivery | Architecture | KnowledgeBase, Plan, Context, Graph | planner |
| 4 | [generator](../skills/project-generator/SKILL.md) | discovery, execution, validation | discovery, execution, validation | Code | KnowledgeBase, Plan, Architecture, Context, Graph | architect |
| 5 | [tester](../skills/project-tester/SKILL.md) | discovery, execution, validation | discovery, execution, validation | Test | Code, Plan, KnowledgeBase, Context | generator |
| 6 | [reviewer](../skills/project-reviewer/SKILL.md) | discovery, execution, validation, delivery | discovery, execution, validation, delivery | Review | Code, Plan, KnowledgeBase, Architecture, Test | tester |
| 7 | [refactorer](../skills/project-refactorer/SKILL.md) | discovery, execution, validation, delivery | discovery, execution, validation, delivery | RefactoredCode | Code, KnowledgeBase, Test, Review | reviewer |
| 8 | [documenter](../skills/project-documenter/SKILL.md) | discovery, execution, validation, delivery | discovery, execution, validation, delivery | Documentation | Code, Review, KnowledgeBase | reviewer |
| 9 | [releaser](../skills/project-releaser/SKILL.md) | discovery, execution, validation, delivery | discovery, execution, validation, delivery | Release | Documentation, Review, Test | documenter |
| 10 | [orchestrator](../skills/pipeline-orchestrator/SKILL.md) | discovery, orchestrate, validation, delivery | discovery, execution, validation, delivery | PipelinePlan | KnowledgeBase, Plan, Architecture, Code, Test, Review, Documentation, Release | releaser |

## Stage × Skill Matrix

| Stage | analyzer | planner | architect | generator | tester | reviewer | refactorer | documenter | releaser |
|-------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **discovery** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **code-audit** | — | ✅ | ✅ | — | — | — | — | — | — |
| **graph-analysis** | — | — | ✅ | — | — | — | — | — | — |
| **execution** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **validation** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **delivery** | ✅ | ✅ | ✅ | — | — | ✅ | ✅ | ✅ | ✅ |

## Template Usage

| Template | Used By | Load Count |
|----------|---------|------------|
| **discovery** | All 10 skills | 10 |
| **execution** | 9 skills（orchestrator 用 orchestrate） | 9 |
| **validation** | All 10 skills | 10 |
| **delivery** | analyzer, planner, architect, reviewer, refactorer, documenter, releaser | 7 |
| **code-audit** | planner, architect | 2 |
| **graph-analysis** | architect | 1 |

## I/O Flow

```
ProjectRoot ──→ analyzer ──→ KnowledgeBase/Context/Graph
                                  │
                    ┌─────────────┘
                    ▼
                  planner ──→ Plan (9-module Contract)
                    │
                    ▼
User Input ──→ architect ──→ Architecture (ADR)
                    │
                    ▼
                generator ──→ Code
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
      tester ──→ Test        reviewer ──→ Review
        │                       │
        └───────────┬───────────┘
                    ▼
        ┌───────────┴───────────┐
        ▼                       ▼
    refactorer ──→ Code     documenter ──→ Docs
        │                       │
        └───────────┬───────────┘
                    ▼
                releaser ──→ Release
```

## Quality Gates

| Gate | 10/10? | Note |
|------|------|------|
| G1: SKILL.md ≤120 lines | ✅ | 58-66 |
| G2: skill.yaml 完整 | ✅ | 含 interface + stages（Runtime Policy 在 skill-policy.yaml） |
| G3: boundary.md ≥3 反例 | ✅ | 内嵌在 SKILL.md 或 boundary.md |
| G4: CHECKPOINT ≥1 | ✅ | 每 stage prompts 含 CHECKPOINT |
| G5: 职责边界表 | ✅ | ✅/❌ 表在 boundary.md |
| G6: description 含触发词 | ✅ | 全部含触发词（产出见 skill.yaml produces） |
| G7: capabilities.yaml 注册 | ✅ | 10/10 已注册 |
| G8: 完成后 next-step | ✅ | 10/10 |
| G9: boundary.md 失败兜底 | ✅ | 10/10 |
| G10: Stage prompts | ✅ | 37 个文件 |
| G11: @template 声明 | ✅ | 每 stage prompt 含 @template |
| G12: skill-policy.yaml rollback | ✅ | 10/10 |

## Governed Readiness

| Requirement | Status |
|-------------|--------|
| owner | ✅ `project-suite` |
| review cadence | ✅ 90-day, last_reviewed 已写入 10/10 skill.yaml |
| input_files (file-backed fixture) | ✅ 10/10 skills `interface.inputs[].fixture` |
| output contract | ✅ skill.yaml interface.outputs |
| rollback boundary | ✅ skill-policy.yaml rollback (10/10) |
| trust report | ✅ `reports/trust-report.md` (90/100) |
| output_quality_scorecard | ✅ `reports/output-quality-scorecard.md` |
| telemetry | ✅ `shared/scripts/collect-metrics.sh` (local aggregation) |
| cross-run reliability | ✅ `docs/cross-run-reliability.md` + `check-reliability.sh` + 10/10 `skill-policy.yaml` reliability |
| drift detection | ⚠️ `missing evidence` |

## Skill 准入（这张表何时该变长）

> 本文档的 Atlas 表**默认不变**。新增一行 = 新建一个 skill，是 ADR 级别的作者决策，不是每次分析都要走的流程。
> 完整判据与成本见 [ADR-005](decisions/ADR-005-skill-admission.md)。

准入五问，**全部为「是」**才考虑新建（任一为「否」→ 留在知识层）：

| # | 判据 | 为「否」时 |
|---|------|-----------|
| A1 | 有用户会用一句话直接要求它，且不落进任何现有 capability 的 intent 集 | 扩展现有 skill |
| A2 | 有明确的「不做」，且与现有 `boundary.md` 不重叠 | 合并而非新建 |
| A3 | 存在独立的输入/输出边界，且有独立消费场景（下游 Skill **或用户直接消费**） | 加一个 stage/prompt |
| A4 | 有稳定、可识别的独立用户意图，值得拥有独立可发现入口（判**入口价值**，不判调用频率） | 并入现有 intent 集 |
| A5 | 能被独立验证（有可判定的 assertion） | 留在知识层——无法验证的能力进不了压力测试 |

> A3 / A4 的措辞是刻意这么写的：按「必须有下游 skill 消费」会否决现役的 releaser/refactorer
> （实测它们的产物在 `needs` 里无下游消费者）；按「必须高频」则会否决 releaser/refactorer/documenter，
> 且在 skill 存在前无法测量。详见 [ADR-005](decisions/ADR-005-skill-admission.md)。

**成本**：新增一行要同步 `skill.yaml` / `skill-ir.yaml` / `compatibility.yaml` / `scheduler.yaml` /
`skill-policy.yaml` + 重新生成 registry，并由 [check-consistency.sh](../shared/scripts/check-consistency.sh)
L3 / L3.5 硬校验（非警告）。
