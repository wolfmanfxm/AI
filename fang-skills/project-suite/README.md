# Project Suite

> Agent Pipeline Framework — 10 个 Skill，覆盖分析→规划→设计→生成→测试→审查→重构→文档→发布→编排。
> Registry-driven + Evidence-based Knowledge Graph + Continuous Learning Loop。
>
> **Framework Spec**: [SUITE_SPEC.md](SUITE_SPEC.md) · **Architecture**: [docs/architecture.md](docs/architecture.md) · **Roadmap**: [docs/roadmap.md](docs/roadmap.md) · **Trust**: 90/100

## 阅读约定：示例 vs 规范

> 文档与 prompt 中出现的具体组件名（`FormWrapper` / `PageTable` / `MpTable` / `DialogWrapper` / `DocsSelect`）和路径别名（`@workspace` / `el-mp`）均来自**参考项目**，仅作**示例说明**，**不是**本框架的通用规范。
> 换到你的项目时，这些名字应替换成你项目自己的组件与别名。框架的通用部分是**机制**（Registry / Resolver / Evidence / Decision Record / Confidence Gate），而不是这些具体名字。

## 当前版本：1.0.0

```
Knowledge Engine     — Object + Context Resolver + Promotion Reviewer + Decay
Unified Runtime      — Tool Adapter(9/10) + Event Bus + Background Pipeline
Reasoning Engine     — Query API + Orchestrator v2.0 (Decision-Boundary Checkpoint, auto-advance 仅 background)
Governed-ready       — Conformance G1-G17, Drift 40/40, Trust 90/100
Organization Layer   — Task→Project→Organization→Personal 四层
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
| 1 | **analyzer** | 10 Extractor → 8-Phase → Evidence-based Knowledge Graph | Candidate→Verify→Instinct |
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
Phase 4: Knowledge Builder → graph.json + .md (双轨输出)
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

## 验证状态（2026-08-14 快照）

> 三目标实际完成度，基于真实 benchmark + 验证实验。

| 目标 | 完成度 | 证据 |
|------|--------|------|
| Spec = Registry = Runtime | ~50% | Registry 派生 ✅（generate-registry.mjs）；Runtime 独立是 ADR-003 设计使然，本不该「=」 |
| Domain Model = SDLC 共同语言 | ~90% | 5 环里 4.5 环验证：Analyzer 提取 ✅ / Architect V8 ✅ / Generator V7 ✅ / Reviewer V6 ✅ / Planner confirm 🟡 |
| Benchmark 证明收益 | ~100% | 20 任务 native vs suite，收益=**过程质量**，非 token/复用 |

### 关键结论

- **suite 的收益是过程质量**：Decision Record 可追溯、边界纪律（反 gold-plate）、证据密度、长任务护栏（L2 事故）——**不是** token 省（平均 +12.8%）或复用率（两者都靠 grep）。
- **domain drift 检测可靠**：F1 0.966，零误报。三步闭环：存在 → 可纠正 → 可靠。
- **消除多头权威**：skill.yaml = Skill Contract（intrinsic），workflow/gates/profiles = Orchestration，无字段重叠（ADR-003）。

详见 [project-suite-eval/benchmark/analysis.md](../project-suite-eval/benchmark/analysis.md)（评估证据已独立存放）。

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
