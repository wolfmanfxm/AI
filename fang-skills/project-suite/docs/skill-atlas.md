# Skill Atlas v0.8

> project-suite 全技能地图 — 每个 Skill 的 stage/template/capability/I/O 全景。
> 由 workflow-engine 解释，供 Dispatcher 和自动化工具消费。

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
| 10 | [orchestrator](../skills/pipeline-orchestrator/SKILL.md) | discovery, orchestrate, validation, delivery | discovery, execution, validation, delivery | PipelineExecution | KnowledgeBase, Plan, Architecture, Code, Test, Review, Documentation, Release | releaser |

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
| G6: description 含触发词 | ✅ | 全部含触发词+产出 |
| G7: capabilities.yaml 注册 | ✅ | 10/10 已注册 |
| G8: 完成后 next-step | ✅ | 10/10 |
| G9: boundary.md 失败兜底 | ✅ | 10/10 |
| G10: Stage prompts | ✅ | 37 个文件 |
| G11: @engine 声明 | ✅ | 每 stage prompt 含 @engine |
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
