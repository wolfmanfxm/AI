# Runtime 协议导航

> 所有运行时协议的入口索引。理解 Skill 如何被调度、如何通信、如何恢复。

## 协议总览

### `protocols/` — 编排与路由

| 文件 | 说明 |
|------|------|
| [orchestration.md](protocols/orchestration.md) | 跨 Skill 工作流编排，定义 User-as-Dispatcher 核心模式 |
| [routing.md](protocols/routing.md) | 用户意图到 Skill 的路由规则（精确触发词 / 上下文 / 语义） |

### `engine/` — 执行引擎

| 文件 | 说明 |
|------|------|
| [state-machine.md](engine/state-machine.md) | Skill 执行生命周期状态机（idle → discover → confirmed → in_progress → completed） |
| [checkpoint.md](engine/checkpoint.md) | 断点续传协议，确保 Skill 中断后可从 manifest 恢复 |
| [error-recovery.md](engine/error-recovery.md) | 异常分级（WARNING/DEGRADED/BLOCKED/FATAL）与恢复策略 |
| [scheduler.md](engine/scheduler.md) | 调度器设计文档，DAG 构建与 Wave 批次执行（配置已迁至 YAML） |
| [confidence-gate.md](engine/confidence-gate.md) | 📖 Confidence 消费端行为（PASS/REVIEW/GATE/BLOCK） |
| [confidence.yaml](engine/confidence.yaml) | ⚙️ **可执行**：每个 Skill 的加减分规则 + Gate 阈值 |

### `context/` — 上下文协议

| 文件 | 说明 |
|------|------|
| [context.md](context/context.md) | context.json Schema 定义，Skill 间传递项目知识的标准协议 |
| [context-priority.yaml](context/context-priority.yaml) | ⚙️ **可执行**：优先级栈 + 字段校验 + Gate 决策树 |
| [context-priority.md](context/context-priority.md) | 📖 **人类读**：优先级设计理由 |
| [context-resolution.md](context/context-resolution.md) | context.json 与当前代码不一致时的裁决规则（代码事实 > context.json） |
| [merge.md](context/merge.md) | 📖 跨源冲突的合并策略（为什么 override/append/ignore） |
| [merge.yaml](context/merge.yaml) | ⚙️ **可执行**：逐源策略 + 冲突裁决优先级 + 统一加载流程 |

### `contracts/` — 接口契约

| 文件 | 说明 |
|------|------|
| [skill-io.md](contracts/skill-io.md) | Skill 统一输入输出格式（4 入口：context/state/task/knowledge） |
| [context-package.schema.json](contracts/context-package.schema.json) | ⚙️ **可执行**：Generator 直接消费的预消化知识包 |
| [graph-query.md](contracts/graph-query.md) | Knowledge Graph 的 7 个标准查询协议（零依赖，grep/jq 直查） |

### `state/` — 状态与知识生命周期

| 文件 | 说明 |
|------|------|
| [state.md](state/state.md) | `.project-runtime/` 持久化状态层，Skill 间的共享记忆 |
| [schemas/knowledge-lifecycle.md](state/schemas/knowledge-lifecycle.md) | 知识生命周期：Artifact → Candidate → Accepted → Deprecated |
| [schemas/knowledge-scoring.md](state/schemas/knowledge-scoring.md) | Generator 使用知识后的反向评分机制 |
| [schemas/promotion-rules.md](state/schemas/promotion-rules.md) | Candidate 晋升 Accepted 的 5 条规则（需满足 ≥3/5） |

### `registry/` — 能力注册

| 文件 | 说明 |
|------|------|
| [capabilities.yaml](registry/capabilities.yaml) | 统一能力注册中心，声明每个 Skill 的 produces/consumes |

### `config/` — 运行配置

| 文件 | 说明 |
|------|------|
| [scheduler.yaml](config/scheduler.yaml) | 调度器机器可读配置（并行策略/断点续传/checkpoint 模式） |
| [gates.yaml](config/gates.yaml) | Confidence 驱动的质量门禁（阈值/阻断/自动接受规则） |

### `artifacts/` — 产出物类型

| 文件 | 说明 |
|------|------|
| [artifact-types.yaml](artifacts/artifact-types.yaml) | 产出物类型注册表，定义 knowledge/context/planning 等类型的 schema 和生命周期 |

### `workflows/` — 工作流模板

| 文件 | 说明 |
|------|------|
| [full-sdlc.yaml](workflows/full-sdlc.yaml) | 全流程参考：分析 → 规划 → 架构 → 生成 → 测试 → 审查 → 发布 |
| [quick-change.yaml](workflows/quick-change.yaml) | 轻量改动参考：规划 → 生成 → 审查 |
| [feature.md](workflows/feature.md) | (已废弃) 新功能开发工作流，保留为历史参考 |
| [bugfix.md](workflows/bugfix.md) | (已废弃) Bug 修复工作流，保留为历史参考 |
| [refactor.md](workflows/refactor.md) | (已废弃) 代码重构工作流，保留为历史参考 |
| [greenfield.md](workflows/greenfield.md) | (已废弃) 全新项目工作流，保留为历史参考 |

### 根目录

| 文件 | 说明 |
|------|------|
| [knowledge-resolver.md](knowledge-resolver.md) | Task → Graph → Top K 知识检索，Generator 的唯一知识入口 |

---

## 依赖关系图

```
capabilities.yaml ──→ scheduler.md ──→ routing.md
        │                   │
        ▼                   ▼
artifact-types.yaml    scheduler.yaml
                           │
                           ▼
                       gates.yaml


state-machine.md ──→ checkpoint.md ──→ error-recovery.md
        │
        ▼
    state.md ──→ knowledge-lifecycle.md ──→ knowledge-scoring.md
        │                                        │
        │                                        ▼
        │                                  promotion-rules.md
        │
        ▼
skill-io.md ──→ context.md ──→ context-priority.md ──→ context-resolution.md
                    │                                        │
                    │                                        ▼
                    └──────────────────────────────────── merge.md


orchestration.md ──→ routing.md
        │               │
        ▼               ▼
    state.md      capabilities.yaml


knowledge-resolver.md ──→ graph-query.md
                              │
                              ▼
                         state.md (graph.json)
```

---

## 推荐阅读顺序

### Level 1 — 核心概念
> 理解 Suite 的运行哲学：用户调度、状态通信、上下文传递

1. [orchestration.md](protocols/orchestration.md) — User-as-Dispatcher 模式
2. [state.md](state/state.md) — Skill 间共享记忆
3. [context.md](context/context.md) — 项目知识传递

### Level 2 — 执行引擎
> 理解 Skill 如何运行、暂停、恢复

4. [state-machine.md](engine/state-machine.md) — 执行状态流转
5. [checkpoint.md](engine/checkpoint.md) — 断点续传
6. [error-recovery.md](engine/error-recovery.md) — 异常恢复
7. [scheduler.md](engine/scheduler.md) — DAG 调度

### Level 3 — 能力注册与契约
> 理解 Skill 如何被发现、如何交互

8. [capabilities.yaml](registry/capabilities.yaml) — 能力声明
9. [routing.md](protocols/routing.md) — 意图路由
10. [skill-io.md](contracts/skill-io.md) — 输入输出契约
11. [graph-query.md](contracts/graph-query.md) — 知识图谱查询

### Level 4 — 配置、知识与产出物
> 理解运行时的可调参数和知识演化机制

12. [scheduler.yaml](config/scheduler.yaml) — 调度配置
13. [gates.yaml](config/gates.yaml) — 质量门禁
14. [knowledge-lifecycle.md](state/schemas/knowledge-lifecycle.md) — 知识生命周期
15. [artifact-types.yaml](artifacts/artifact-types.yaml) — 产出物类型
16. [context-priority.md](context/context-priority.md) — 上下文优先级

---

## 按角色阅读

### Skill 开发者
> 开发新 Skill 或修改现有 Skill 时必读

1. [skill-io.md](contracts/skill-io.md) — 输入输出格式要求
2. [context.md](context/context.md) — 如何读取项目上下文
3. [state-machine.md](engine/state-machine.md) — 执行状态如何流转
4. [error-recovery.md](engine/error-recovery.md) — 异常处理规范
5. [checkpoint.md](engine/checkpoint.md) — 断点续传实现

### Suite 维护者
> 维护 Suite 整体架构和调度逻辑时必读

1. [capabilities.yaml](registry/capabilities.yaml) — 能力注册与 DAG 构建
2. [scheduler.md](engine/scheduler.md) — 调度策略设计
3. [gates.yaml](config/gates.yaml) — 质量门禁配置
4. [artifact-types.yaml](artifacts/artifact-types.yaml) — 产出物类型管理
5. [orchestration.md](protocols/orchestration.md) — 编排模式

### 新手入门
> 第一次接触 Suite 时的最短路径

1. [orchestration.md](protocols/orchestration.md) — 理解核心模式
2. [state.md](state/state.md) — 理解状态层
3. [workflows/](workflows/) — 浏览工作流模板了解实际用法

---

## Capability Map（"我要改 X" → 读什么）

> 20+ 个协议文件，不需要全记住。按你的目标查这张地图。

| 我想做什么 | 先读 | 再读 | 可能需要 |
|-----------|------|------|---------|
| **新增一个 Skill** | [capabilities.yaml](registry/capabilities.yaml) | [skill-io.md](contracts/skill-io.md) | [state-machine.md](engine/state-machine.md) |
| **修改 Knowledge 生命周期** | [state.md](state/state.md) | [promotion-rules.md](state/schemas/promotion-rules.md) | [knowledge-scoring.md](state/schemas/knowledge-scoring.md) |
| **调整上下文优先级** | [context-priority.md](context/context-priority.md) | [context-resolution.md](context/context-resolution.md) | [merge.md](context/merge.md) |
| **改调度/DAG 依赖** | [scheduler.yaml](config/scheduler.yaml) | [capabilities.yaml](registry/capabilities.yaml) | [scheduler.md](engine/scheduler.md) |
| **改质量门禁** | [gates.yaml](config/gates.yaml) | [confidence-gate.md](engine/confidence-gate.md) | [state-machine.md](engine/state-machine.md) |
| **改产出物类型** | [artifact-types.yaml](artifacts/artifact-types.yaml) | [skill-io.md](contracts/skill-io.md) | SUITE_SPEC.md |
| **改断点续传** | [checkpoint.md](engine/checkpoint.md) | [manifest.schema.json](../shared/schemas/manifest.schema.json) | [state.md](state/state.md) |
| **改知识图谱查询** | [graph-query.md](contracts/graph-query.md) | [graph.schema.json](../shared/schemas/graph.schema.json) | [knowledge-resolver.md](knowledge-resolver.md) |
| **改错误恢复策略** | [error-recovery.md](engine/error-recovery.md) | [state-machine.md](engine/state-machine.md) | [checkpoint.md](engine/checkpoint.md) |
| **排查 Skill 间通信问题** | [state.md](state/state.md) | [context.md](context/context.md) | [skill-io.md](contracts/skill-io.md) |
| **查 Skill 性能/成功率** | [timeline.md](metrics/timeline.md) | [timeline.schema.json](metrics/timeline.schema.json) | [confidence-gate.md](engine/confidence-gate.md) |
| **理解整体架构** | [orchestration.md](protocols/orchestration.md) | [scheduler.md](engine/scheduler.md) | [state.md](state/state.md) |
