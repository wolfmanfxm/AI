# Roadmap

> project-suite 演进路线图。

## 版本历史

| 版本 | 日期 | 关键变化 |
|------|------|---------|
| **v0.9.0** | 2026-08 | Analyzer v3.0 (7-Phase + Instinct Extraction), Candidate/Verify 架构 9/9, Knowledge Promotion (Task→Project→Personal→Instinct), Workflow DSL, Capability Registry, Pipeline Orchestrator, Event Bus, Memory Layer, Governed-ready (Trust 90/100) |
| v0.8.0 | 2026-08 | Stage Contract + Validation + QA Sub-Agent, Interface 统一, Workflow Engine (Template Injection + Execution Driver), darwin-skill dim8 实测 |
| v0.7.0 | 2026-07 | 9-module PLAN Contract, Dispatcher Pattern, Knowledge Lifecycle v2.0, Unified I/O, capabilities.yaml |
| v0.6.0 | 2026-07 | Capability Registry, skill.yaml, DAG Scheduler, 自动路由 |
| v0.5.0 | 2026-06 | 职责边界, AskUserQuestion, 现状探查, 反例黑名单, Context Protocol |

## 未来方向

- [ ] 其余 6 个 Skill dim8 full_test（当前 3/10，覆盖率 30%）
- [ ] Tool Adapter 深度集成（当前 adapter-registry 定义了 6 个域，Skill 未全面采用 `@adapter:` 语法）
- [ ] Cross-skill Pipeline 自动执行（当前 orchestrator 提示用户触发下游，未来可自动调度）
- [ ] Knowledge Promotion Reviewer Agent（当前 Reviewer 确认是人工，可升级为独立 agent 判断跨项目价值）
