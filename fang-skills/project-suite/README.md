# Project Suite

> Agent Pipeline Framework — 10 个 Skill，覆盖分析→规划→设计→生成→测试→审查→重构→文档→发布→编排。
> Registry-driven + Evidence-based Knowledge Graph + Continuous Learning Loop。
>
> **Framework Spec**: [SUITE_SPEC.md](SUITE_SPEC.md) · **Skill Atlas**: [docs/skill-atlas.md](docs/skill-atlas.md) · **Trust**: 90/100

## 当前版本：1.0.0

```
analyzer v3.0   (Multi-Extractor + 7-Phase + Evidence-based Knowledge Graph)
workflow-engine (Stage Injection + Execution Driver + DSL)
pipeline-orchestrator (跨 Skill 编排)
Governed-ready  (Conformance G1-G17, Drift 40/40, Trust 90/100)
Knowledge Decay (STALE→DECAYING→DEPRECATED 自动衰减)
Organization Layer (Task→Project→Organization→Personal 四层)
```

## 架构三层

```
┌─────────────────────────────────────────┐
│ Workflow Engine                          │
│ Stage Injection · Execution Driver · DSL │
│ Event Bus · Memory Layer                │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│ Runtime Engine                           │
│ State Machine · Checkpoint · Error       │
│ Confidence Gate · Scheduler              │
│ Registry (Capability · Stage · Routing)  │
│ Tool Adapters · Knowledge Scan           │
└──────────────┬──────────────────────────┘
               │
┌──────────────┴──────────────────────────┐
│ 10 Business Skills                       │
│ analyzer · planner · architect           │
│ generator · tester · reviewer            │
│ refactorer · documenter · releaser       │
│ pipeline-orchestrator                    │
└─────────────────────────────────────────┘
```

## Skill 矩阵

| # | Skill | 职责 | 关键能力 |
|---|-------|------|---------|
| 1 | **analyzer** | 10 Extractor → 7-Phase → Evidence-based Knowledge Graph | Candidate→Verify→Instinct |
| 2 | **planner** | 模糊需求 → 9 模块执行契约 | 现状探查 + Context Package |
| 3 | **architect** | 技术选型 + 模块设计 + API 契约 | ADR + 对比矩阵 + Graph 分析 |
| 4 | **generator** | 项目知识 → 生产级代码 | Pattern 复用 + Graph 查询 |
| 5 | **tester** | AC 驱动测试生成 + 执行 | Framework auto-detect |
| 6 | **reviewer** | 五轴审查（正确性/安全/可读/架构/性能） | BLOCKER→PRAISE 分级 |
| 7 | **refactorer** | 安全重构（行为不变） | 小步循环 + 指标量化 |
| 8 | **documenter** | API/组件/README 文档 | 源码溯源 + Vault 同步 |
| 9 | **releaser** | 版本 bump + Changelog + 发布检查 | 全链路 Confidence Gate |
| 10 | **orchestrator** | 跨 Skill Pipeline 编排 | Registry-driven 自动调度 |

## Analyzer v3.0 — 核心 Skill

```
Phase 1: 10 Extractors (Registry-driven) → candidates/accepted/*.yaml
Phase 2: 5-Verify → Accepted/Adjusted/Rejected
Phase 3: Cross-Validator → contradictions + complements
Phase 4: Knowledge Builder → knowledge-graph.yaml + .md (双轨输出)
Phase 5: INDEX Generator → Zettelkasten Knowledge Graph
Phase 6: Classifier → promotion: none/project/personal
Phase 7: Instinct Extraction → Always/Prefer/Avoid/Never

Delivery: 双同步 — Project Sync + Knowledge Promotion
```

## 知识演化闭环

```
Task (一次任务) → Project Knowledge (项目长期) → Review → Instinct (跨项目) → Knowledge Vault (个人资产) → 下次复用
```

| 层级 | Promotion | 同步目标 |
|------|-----------|---------|
| Task Artifact | `none` | 仅 `.project-knowledge/` |
| Project Knowledge | `project` | + `Vault/Projects/<project>/` |
| Personal Candidate | `personal` | Reviewer 确认 → `Vault/Knowledge/` |
| Instinct | `personal` | Always/Prefer/Avoid/Never → Playbook |

## Pipeline 模式

| Pipeline | Skills | 场景 |
|----------|--------|------|
| `full-sdlc` | 8 skills | 全生命周期 |
| `analyze-plan-build` | 5 skills | 新功能开发 |
| `quick-change` | 2 skills | 轻量改动 |
| `refactor-cycle` | 4 skills | 重构循环 |
| `knowledge-refresh` | 2 skills | 知识刷新 |

## 质量门禁

| 门禁 | 状态 |
|------|------|
| Conformance (G1-G17) | 0 errors, 0 warnings |
| Drift Detection | 40/40 pass |
| Trigger Eval | clean, no overlaps |
| Runtime Neutrality | 0 red flags |
| Trust Score | 90/100 |
| SKILL.md 平均行数 | 71 行 |

## Governed 就绪

| 要求 | 状态 |
|------|------|
| owner + review cadence | ✅ 10/10 |
| input_files fixture | ✅ 21 labeled |
| rollback boundary | ✅ 10/10 |
| trust report | ✅ 90/100 |
| quality scorecard | ✅ |
| cross-run reliability | ✅ 10/10 |
| Skill Atlas | ✅ |
| Skill IR | ✅ 10/10 auto-generated |

## 目录

```
project-suite/
├── workflow-engine/       ← Stage Injection + Execution Driver + DSL
├── runtime/
│   ├── engine/            ← State · Checkpoint · Error · Gate · Event · Approval
│   ├── registry/          ← Capability · Stage · Workflow · Routing · Extractor
│   ├── memory/            ← Session · Project · Suite · Decision
│   ├── tool-adapters/     ← Filesystem · Browser · Git · Network · Design
│   ├── context/           ← Context Protocol (context.json + priority)
│   ├── state/             ← State Management (state.json + knowledge lifecycle)
│   ├── contracts/         ← Skill I/O + Graph Query + Context Package
│   ├── protocols/         ← Routing + Orchestration
│   ├── config/            ← Scheduler + Gates (YAML)
│   ├── metrics/           ← Timeline + Knowledge Health
│   └── artifacts/         ← Artifact Types Registry
├── skills/                ← 10 Skills
├── shared/                ← Schemas(8) · Scripts(9) · Conventions · Examples · Templates
├── docs/                  ← Skill Atlas · Benchmarks · Review Cadence · Review Studio · Waiver · Prompt Quality · Cross-Run Reliability · Roadmap · Architecture
├── reports/               ← Trust(90) · Quality Scorecard · Trigger Eval
└── suite-manifest.yaml    ← 单文件治理
```
