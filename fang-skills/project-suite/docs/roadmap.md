# Roadmap

> project-suite 演进路线图。v1.0.0 完成 Knowledge Engine；Runtime 是 Protocol 非 Engine（见下状态模型）。v2.0 从「功能清单」转「问题驱动」。

## 定位

> project-suite 是 **Agent SDLC Framework**，不是 Skills 集合（区别于 Superpowers 的 composable / Matt Pocock 的小 Skill 路线）。复杂度在 Framework 层（runtime/engine + registry + gates + profiles + shared/primitives），Skill 保持薄（~50 行）。**新增能力 → Framework 层，不散落进 SKILL.md。**

## 状态模型（避免「假完成」）

> `[x]` 只表示「设计/实现完成」，不代表「在真实环境强制生效」。四态标注：

| 状态 | 含义 | 当前实例 |
|------|------|---------|
| **Designed** | 有规范/设计文档 | Runtime（Protocol 非 Engine） |
| **Implemented** | 有脚本/代码，未强制 | Complexity Gate、Command Guard（有脚本，无真 hook） |
| **Enforced** | runtime 强制（不靠 agent 配合） | 暂无 |
| **Validated** | 经真实任务验证生效 | depth_profiles 深度、知识缺口（round4 实测） |

## 版本历史

| 版本 | 日期 | 关键变化 |
|------|------|---------|
| **v1.0.0** | 2026-08 | Knowledge Consumption 闭环: Knowledge Object → Query API → Context Resolver(10/10) → Skills → Promotion Reviewer → Knowledge Vault。Knowledge Engine + Unified Runtime + Reasoning Engine。Trust 90/100, darwin 84.2 |
| v0.9.0 | 2026-08 | Analyzer v3.0 (8-Phase), Candidate/Verify 9/9, Knowledge Promotion (Task→Project→Organization→Personal), Workflow DSL, Pipeline Orchestrator, Event Bus, Memory Layer, Governed-ready |
| v0.8.0 | 2026-08 | Stage Contract + Validation + QA Sub-Agent, Interface 统一, Workflow Engine (Template Injection + Execution Driver) |
| v0.7.0 | 2026-07 | 9-module PLAN Contract, Dispatcher Pattern, Knowledge Lifecycle v2.0, capabilities.yaml |
| v0.5-0.6 | 2026-06/07 | 职责边界, Capability Registry, DAG Scheduler, Context Protocol |

## v1.0.0 已完成

- [x] Knowledge Object — 统一 Schema v2.0，graph.json 为 Machine Source of Truth
- [x] Knowledge Query — API spec + CLI tool，结构化查询替代读 .md
- [x] Context Resolver — 10/10 Skill Discovery step 0，Task → Tags → Query → 注入
- [x] Knowledge Evaluation — Promotion Reviewer Phase 8，CrossProject/Reusability/FrameworkCoupling 评分
- [x] Knowledge Promotion — Classifier → Instinct Extraction → vault-sync 双同步
- [x] Background Pipeline — 事件驱动，Scan→Decay→Review 全自动
- [x] Candidate/Verify — 9/10 Skill 统一验证模式
- [x] Governed-ready — G1-G17, Drift 40/40, Trust 90/100

## v2.0 已完成（历史，TODO 已重组进下方「问题驱动」）

### 聚焦

**每个 Skill 都基于项目知识和历史经验做出更好的决策。**

### 做（已完成）

- [x] Knowledge Query 成为所有 Skill 的唯一数据入口（消除残留 .md 直接读取）
- [x] Domain Model → 全 Suite：Analyzer(candidate) → Planner(confirm) → Architect(validate) → Generator(follow) → Reviewer(detect drift)。已验 4.5/5 环（Analyzer 提取✅ / Architect V8✅ / Generator V7✅ / Reviewer V6✅ / Planner confirm🟡）。证据见外部 eval 仓库 project-suite-eval（独立存放）
- [x] Benchmark 套件：3 轮真实任务（round1 20 任务 + round2 8 新任务 + round3/4 优化验证）native vs project-suite 对比完成。结论：suite 收益=过程质量，非 token/复用。证据见外部 eval 仓库 project-suite-eval（独立存放）
- [x] 完整生成脚本：catalog/capabilities/routing 从 skill.yaml 派生（消除多头权威的剩余漂移风险）

### 不做

- [ ] ~~Tool Adapter 深度集成~~ — 当前抽象层足够（7 域, 27 refs, 9/10 Skill），不过度设计
- [ ] ~~Cross-skill Pipeline 自动执行~~ — 保持关键节点人工确认，后台任务自动化即可
- [ ] ~~Tool Selection 自动匹配~~ — Skill 声明 capability，Registry 映射，不需要 AI 推理

## v1.0.0 能力评估

| 状态 | 能力 | 说明 |
|------|------|------|
| 🟢 | Skill Contract, Workflow Engine, Knowledge Object, Knowledge Resolver, Knowledge Promotion, Evidence/Verification, Confidence Gate, Checkpoint, Adapter Registry, Artifact Contract | 稳定，不继续堆 |
| 🟡 | Adaptive Interview, Domain Model, Cross Artifact Analysis, Context Budget, Skill Routing, Pipeline Adaptivity, Suite Benchmark | 适度打磨 |

> Convergence 已从 🟡 升为 P1（见下「问题驱动」）。
| 🔴 | AI Tool Intent Resolver, 自动 Tool Selection, Multi-Agent Runtime, Skill Marketplace, 复杂 Plugin Ecosystem, 更多 Skill, 更复杂 Pipeline DSL | 不做，ROI 低 |

## v2.0 优先级（问题驱动，取代上面的功能清单）

> 从「功能清单」转「问题驱动」。round3/4 暴露的真问题是**流程税 + 执行未强制**，优先级高于 Knowledge Score/Instinct Registry。

### P0 — Execution Integrity（执行完整性）

- [ ] Complexity Gate **强制**路由（现在是 orchestrator 里的决策协议，靠 agent 配合，非 Runtime 强制）
- [ ] Command Guard **真 hook**（现在靠宿主分类器兜底，非自己拦截）
- [ ] Skill bypass 检测（agent 绕过 Gate/Guard 时能发现）

### P1 — Execution Efficiency（执行效率，核心是 **Convergence**）

- [x] Quick / Standard / Full 路径（Complexity Gate）
- [x] Skill 深度统一（depth_profiles：minimal/standard/full 三档，消掉 4 套 Quick/Light/Focused 词汇）
- [x] Analyzer 知识缺口入口（知识够 → 跳过）+ Reuse Fast Path
- [x] Skill prompt 瘦身（样板下沉，失败处理并入 boundary）
- [ ] **Convergence 作为一等能力**：Evidence sufficient? → STOP/EXECUTE（统一「少做事」原则，解决流程税）

### P2 — Knowledge Consumption

- [ ] Context Resolver 跨项目
- [ ] Knowledge Decay
- [ ] Knowledge Score

### P3 — Knowledge Automation

- [ ] Instinct Registry
