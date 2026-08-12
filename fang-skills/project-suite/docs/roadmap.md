# Roadmap

> project-suite 演进路线图。v1.0.0 完成 Knowledge Engine + Unified Runtime，v2.0 聚焦 Knowledge Consumption。

## 版本历史

| 版本 | 日期 | 关键变化 |
|------|------|---------|
| **v1.0.0** | 2026-08 | Knowledge Consumption 闭环: Knowledge Object → Query API → Context Resolver(10/10) → Skills → Promotion Reviewer → Knowledge Vault。Knowledge Engine + Unified Runtime + Reasoning Engine。Trust 90/100, darwin 84.2 |
| v0.9.0 | 2026-08 | Analyzer v3.0 (8-Phase), Candidate/Verify 9/9, Knowledge Promotion (Task→Project→Organization→Personal), Workflow DSL, Pipeline Orchestrator, Event Bus, Memory Layer, Governed-ready |
| v0.8.0 | 2026-08 | Stage Contract + Validation + QA Sub-Agent, Interface 统一, Workflow Engine (Template Injection + Execution Driver) |
| v0.7.0 | 2026-07 | 9-module PLAN Contract, Dispatcher Pattern, Knowledge Lifecycle v2.0, capabilities.yaml |
| v0.5-0.6 | 2026-06/07 | 职责边界, Capability Registry, DAG Scheduler, Context Protocol |

## v1.0.0 已完成

- [x] Knowledge Object — 统一 Schema v2.0，knowledge-graph.yaml 为 Machine Source of Truth
- [x] Knowledge Query — API spec + CLI tool，结构化查询替代读 .md
- [x] Context Resolver — 10/10 Skill Discovery step 0，Task → Tags → Query → 注入
- [x] Knowledge Evaluation — Promotion Reviewer Phase 8，CrossProject/Reusability/FrameworkCoupling 评分
- [x] Knowledge Promotion — Classifier → Instinct Extraction → vault-sync 双同步
- [x] Background Pipeline — 事件驱动，Scan→Decay→Review 全自动
- [x] Candidate/Verify — 9/10 Skill 统一验证模式
- [x] Governed-ready — G1-G17, Drift 40/40, Trust 90/100

## v2.0 方向：深化 Knowledge Consumption

### 聚焦

**每个 Skill 都基于项目知识和历史经验做出更好的决策。**

### 做

- [ ] Knowledge Query 成为所有 Skill 的唯一数据入口（消除残留 .md 直接读取）
- [ ] Context Resolver 支持跨项目知识注入（不只是当前项目）
- [ ] Knowledge Decay 自动化（check-decay.sh → 定期执行 → 自动标记 STALE/DEPRECATED）
- [ ] Knowledge Score 复合指标（quality × coverage × reuse × freshness → 排序权重）
- [ ] Instinct Registry 自动更新（Promotion Reviewer auto_promote → 写入 instincts.yaml）

### 不做

- [ ] ~~Tool Adapter 深度集成~~ — 当前抽象层足够（7 域, 18 refs, 9/10 Skill），不过度设计
- [ ] ~~Cross-skill Pipeline 自动执行~~ — 保持关键节点人工确认，后台任务自动化即可
- [ ] ~~Tool Selection 自动匹配~~ — Skill 声明 capability，Registry 映射，不需要 AI 推理

### v1.0.0 能力评估

| 状态 | 能力 | 说明 |
|------|------|------|
| 🟢 | Skill Contract, Workflow Engine, Knowledge Object, Knowledge Resolver, Knowledge Promotion, Evidence/Verification, Confidence Gate, Checkpoint, Adapter Registry, Artifact Contract | 稳定，不继续堆 |
| 🟡 | Adaptive Interview, Domain Model, Cross Artifact Analysis, Context Budget, Skill Routing, Pipeline Adaptivity, Suite Benchmark, Convergence | 适度打磨 |
| 🔴 | AI Tool Intent Resolver, 自动 Tool Selection, Multi-Agent Runtime, Skill Marketplace, 复杂 Plugin Ecosystem, 更多 Skill, 更复杂 Pipeline DSL | 不做，ROI 低 |
