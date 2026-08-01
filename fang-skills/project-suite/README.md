# Project Suite

> 软件项目全生命周期 skill 套件 — 9 个 skill，从分析到发布，覆盖完整 SDLC。
> 每个 skill 可独立触发，也可编排为工作流链。每个 skill 只做本阶段的事，不越界。
>
> **Framework Spec**: [SUITE_SPEC.md](SUITE_SPEC.md) — 定义了成为一个合格 suite skill 的目录结构、文件契约、质量门禁。

## 当前版本：0.7.1

v0.5.0: 职责边界 + AskUserQuestion + 现状探查 + 知识库同步 + 反例黑名单 + Context Protocol
v0.6.0: Capability Registry + skill.yaml + DAG Scheduler + 自动路由
v0.7.0: Project Planning Engine — 9 模块 Contract（Goal→Scope→Context→Reuse→Decision→Tasks→Deps→Risk→Acceptance）+ Dispatcher Pattern + Knowledge Lifecycle + Unified I/O
v0.7.1: analyzer v1.3.1 — Finish 4-Phase 重构（强制刷新 JSON + .project-runtime 初始化 + CLAUDE.md 自动更新 + emergence detection + vault sync 验证）

## Skill 矩阵

| # | Skill | 职责 | 产出 | 知识库同步 |
|---|-------|------|------|----------|
| 1 | **project-analyzer** | 7 维度代码分析 | `.project-knowledge/` | ✅ 全量 |
| 2 | **project-planner** | Project Planning Engine — 模糊需求 → 9 模块执行契约 | `proposals/PLAN.md` | ❌ 任务产物 |
| 3 | **project-architect** | 技术选型 + 模块设计（现状核实先行） | `decisions/ARCHITECTURE.md` | ❌ 任务产物 |
| 4 | **project-generator** | 项目知识 → 生产级代码 + 完成报告 | 代码文件 | ❌ 源码 |
| 5 | **project-tester** | 测试生成 + 覆盖率报告 | 测试文件 + 报告 | ❌ 测试产物 |
| 6 | **project-reviewer** | 五轴审查 + BLOCKER→LOW 分级 | `reports/REVIEW.md` | ❌ 任务产物 |
| 7 | **project-refactorer** | 安全重构：9 种手法 + 4 层协议 | 代码文件 | ❌ 源码 |
| 8 | **project-documenter** | 代码 → API/组件/Changelog 文档 | `api/` `components/` `reports/` | ✅ API+组件文档 |
| 9 | **project-releaser** | 版本 bump + Changelog + 发布检查 | `CHANGELOG.md` | ❌ 发布产物 |

## 职责边界（硬性约束）

| 原则 | 说明 |
|------|------|
| **单一职责** | 每个 skill 只做本阶段的活。planner 不做代码，generator 不做设计 |
| **发现问题 → 记录，不修** | planner/architect/reviewer 发现代码问题 → 记录在产出文件中，不直接改代码 |
| **CHECKPOINT → AskUserQuestion** | 所有需要用户确认的步骤，使用 `AskUserQuestion` 给出选项 |
| **上游必读** | generator 启动时检查 PLAN.md/ARCHITECTURE.md 是否存在，存在则必须读取 |
| **现状探查先于产出** | planner（现状探查）和 architect（现状核实）在产出前先确认代码现状 |
| **每个 skill 有反例黑名单** | references/boundary.md 含 ≥3 条「不要做 X」的反例 |
| **Context Protocol** | analyzer 产出 `context.json` → 下游 skill 一次加载技术栈/别名/约定（[runtime/context/](runtime/context/context.md)） |

## 协议栈

```
runtime/
├── state/                      ← 项目持久化状态层
│   ├── state.md                     state.json + knowledge.json 规范
│   └── schemas/
│       └── knowledge-lifecycle.md   Artifact→Candidate→Accepted→Deprecated
├── artifacts/                  ← 统一 Artifact 类型注册
│   └── artifact-types.yaml         12 个类型（knowledge/planning/design/...）+ 生命周期
├── config/                     ← 机器可读 Runtime 配置
│   ├── scheduler.yaml              调度策略（并行/重试/断点续传）
│   └── gates.yaml                  质量门禁（置信度阈值/Skill 独立门禁）
├── contracts/                  ← 统一 I/O + Graph 查询契约
│   ├── skill-io.md                  Skill 输入输出标准格式
│   └── graph-query.md               Graph 查询协议（6 个标准查询）
├── context/                    ← 跨源知识优先级 + 冲突合并
│   ├── context.md                   context.json Schema
│   ├── context-priority.md          Source Priority（6层栈）+ Field Priority
│   ├── context-resolution.md        代码事实 > context.json > 默认值
│   └── merge.md                     override / append / ignore 合并策略
├── registry/                   ← 统一能力注册
│   └── capabilities.yaml           9 skill produces/consumes + DAG
├── engine/                     ← 单 skill 执行
│   ├── state-machine.md
│   ├── checkpoint.md
│   ├── scheduler.md                DAG 调度 + 并行检测
│   └── error-recovery.md
├── protocols/                  ← 多 skill 协作
│   ├── routing.md                  自动生成（从 skill.yaml）
│   ├── knowledge-resolver.md        Task→Graph→TopK→Generator（不自己搜索）
└── orchestration.md            User-as-Dispatcher + Stateless Skill
└── workflows/                  ← 参考模板（用户是 Dispatcher）
    ├── full-sdlc.yaml              全流程参考
    └── quick-change.yaml           轻量改动参考
```

## Runtime v0.7.0 核心模式

### User-as-Dispatcher

```
用户（Dispatcher）
 │  读 .project-runtime/state.json（了解当前状态）
 │  读 Skill 的 suggested_next（参考建议）
 │
 ├──→ 决定：继续 / 重试 / 暂停
 │
 ▼
Skill → 读 State → 执行 → 写 State → 输出 result.md → 结束
```

用户始终是 Dispatcher。Skill 只读写 State 文件，互相不知道对方存在。

### Project State（持久化）

`.project-runtime/` 是 Skill 间的共享记忆。Skill 退出后信息不丢失。

```
.project-runtime/
├── state.json         # 项目状态 + 执行历史（每步 confidence + suggested_next）
├── knowledge.json      # 知识生命周期追踪
└── artifacts/          # 统一产出
```

### Knowledge Lifecycle v2.0

价值驱动。**90% 产出停留在 Artifact 层，永不进入知识库。**

```
Artifact → Candidate → Accepted → Deprecated
```

Generator **只读** `Accepted` — 不把猜测当事实。Candidate 需满足 ≥3/5 晋升规则才能成为 Accepted。

### Confidence 作为决策参考

所有 Skill 输出 confidence（0-100），用户参考决定下一步：

| Confidence | 用户参考 |
|-----------|---------|
| ≥ 90 | 正常推进 |
| 70-89 | 建议检查假设 |
| 40-69 | 建议补充信息 |
| < 40 | 不应直接用于下游 |

详见 [runtime/state/state.md](runtime/state/state.md)

## 知识库同步策略

| 类型 | 同步 Vault？ | 示例 |
|------|------------|------|
| 架构/组件/API/模式文档 | ✅ | `architecture/overview.md` `api/groupCustomer.md` |
| 任务计划 | ❌ | `proposals/PLAN-*.md` |
| 设计决策 | ❌ | `decisions/ARCHITECTURE-*.md` |
| 审查报告 | ❌ | `reports/REVIEW-*.md` |

## 典型工作流

### 全流程（DAG 调度，自动识别并行）

```
Wave 1: analyzer
         ↓
Wave 2: planner
         ↓
Wave 3: architect
         ↓
Wave 4: generator
         ↓
Wave 5: tester
         ↓
Wave 6: reviewer
         ↓
Wave 7: refactorer ┊ documenter   ← 并行
         ↓             ↓
Wave 8:          releaser
```

### 轻量改动: generator → reviewer
### 重构: reviewer → refactorer → tester → reviewer
### Bug修复: generator → tester → reviewer

> 完整 Workflow Catalog: [runtime/workflows/](runtime/workflows/) — feature / bugfix / refactor / greenfield

## 如何使用

每个 skill 用 `/project-<name>` 触发，完成后提示下一步操作。

### PLAN.md Contract（v0.7.0）

planner 产出 9 模块契约，下游各取所需：

| # | Section | 消费者 |
|---|---------|--------|
| 1 | `# Goal` | 全部 Skill |
| 2 | `# Scope` | Generator、Reviewer |
| 3 | `# Context` | Architect、Generator |
| 4 | `# Reuse Analysis` | Generator |
| 5 | `# Decision` | Architect |
| 6 | `# Task Breakdown` | Generator |
| 7 | `# Dependency Graph` | Generator、Runtime |
| 8 | `# Risk Assessment` | Reviewer、Tester |
| 9 | `# Acceptance Criteria` | Tester、Reviewer |

详见 `shared/conventions/checkpoint-pattern.md`。

## 参与

- [docs/architecture.md](docs/architecture.md) — suite 设计决策
- [docs/roadmap.md](docs/roadmap.md) — 版本路线
