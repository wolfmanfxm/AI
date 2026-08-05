# Suite Architecture v2.0 — 蓝图

> Knowledge-driven Agent Framework 的目标架构。
> v1.0.0 已实现 ~80%，剩余 20% 为 v2.0 工作。

## 四层 Runtime

```
┌─────────────────────────────────────────────┐
│ Perception（感知）                            │
│ Intent · Domain · Tech · Need                │
│ 统一入口，所有 Skill 共享                      │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────┴──────────────────────────┐
│ Reasoning（推理）                             │
│ Context Resolver ─ 我需要哪些知识？             │
│ Tool Resolver    ─ 哪些工具最适合？             │
│ Workflow Resolver ─ 我应该执行哪个 Skill？      │
│ Promotion Resolver ─ 值得长期保存吗？           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────┴──────────────────────────┐
│ Execution（执行）                             │
│ 10 Skills + Workflow Engine                  │
│ 不思考，只执行                                 │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────┴──────────────────────────┐
│ Learning（学习）                              │
│ Extract → Verify → Promote → Decay          │
│ Task → Project → Organization → Personal    │
└─────────────────────────────────────────────┘
```

## v1.0.0 → v2.0.0 差距

| 能力 | v1.0 状态 | v2.0 目标 |
|------|----------|----------|
| **Perception** | 分散在各 Skill 的 Discovery | 统一 Perception 层 |
| **Context Resolver** | ✅ 已建 | — |
| **Tool Resolver** | adapter-registry 已定义 | 自动匹配 Skill Capability → Tool |
| **Workflow Resolver** | orchestrator 选 pipeline | 动态规划（Bug→Reviewer+Generator, Feature→Planner+Architect） |
| **Promotion Resolver** | ✅ 已建（Phase 8） | — |
| **Execution** | ✅ 10 Skills + workflow-engine | — |
| **Learning** | ✅ Extract→Verify→Promote→Decay | — |

## 决策链

```
感知（Perception）
  → 理解任务（Intent）
    → 查询知识（Context Resolver）
      → 选择工具（Tool Resolver）
        → 规划流程（Workflow Resolver）
          → 执行 Skill（Execution）
            → 抽取知识（Extractor）
              → 评估价值（Promotion Resolver）
                → 沉淀知识（Knowledge Vault）
```

## v2.0 目录（规划）

```
runtime/
├── perception/          ← v2.0 新建: 统一 Intent → Domain → Tech → Need
├── reasoning/           ← v2.0 重组: 现有 4 个 Resolver
│   ├── context-resolver/    ← 已有 (context-resolver.md)
│   ├── tool-resolver/       ← v2.0 新建
│   ├── workflow-resolver/   ← v2.0 升级 (orchestrator → dynamic)
│   └── promotion-resolver/  ← 已有 (promotion-reviewer.md)
├── execution/           ← 现有: skills/ + workflow-engine
├── learning/            ← 现有: extractor + verifier + promoter + decay
└── registry/            ← 现有: 8 files
```
