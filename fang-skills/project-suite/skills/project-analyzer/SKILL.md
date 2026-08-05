---
name: project-analyzer
metadata: skill.yaml
description: >
  分析软件项目并生成可复用的项目知识库。v2.0 Multi-Extractor 架构：
  10 个专业化提取器 + Candidate→Verify→Accept + Evidence Score + INDEX.md。
  触发词：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、刷新项目知识、
  项目规范、编码规范、analyze codebase、scan project、project refresh。
  产出：.project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
---

# Analyzer v2.0

> 10 Extractor → Candidate → Evidence → 5-Verify → Knowledge Objects → knowledge-graph.yaml
> 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — Registry-driven + Evidence-based Knowledge Graph

## 核心原则

1. **每个 Extractor 只提取一种知识** — 不做全才，做专才
2. **Candidate → Verify → Accept** — 不直接写入，先候选再验证
3. **Evidence Score 溯源** — 每个 Claim 标注证据（路径+行号+次数）
4. **Rejected 保留** — 失败的知识也存档，供后续分析

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 项目源码 | 🔴 BLOCKED |
| 1 | Knowledge Vault 路径 | 🟡 DEGRADED |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |

### Execution 四阶段

```
Phase 1: Extractors → candidates/accepted/*.yaml
Phase 2: 5-Verify → Accepted/Adjusted/Rejected
Phase 3: Cross-Validator → contradictions + complements
Phase 4: Knowledge Builder → knowledge-graph.yaml + .md
Phase 5: INDEX Generator → INDEX.md
Phase 6: Classifier → promotion: none/project/personal
Phase 7: Instinct Extraction → Always/Prefer/Avoid/Never
Phase 8: Promotion Review → auto-score → Promote/Keep/Reject
Delivery: 双同步 — Project Sync + Promotion (auto_promote + manual confirm)
```

### Extractor 矩阵

| # | Extractor | 提取 |
|---|-----------|------|
| 1 | Directory | 目录结构与职责 |
| 2 | Framework | 技术栈与配置 |
| 3 | Architecture | 分层与模块边界 |
| 4 | Pattern | 设计模式与代码模式 |
| 5 | Convention | 命名/import/目录规范 |
| 6 | Glossary | 领域术语定义 |
| 7 | Decision | 架构决策（为什么） |
| 8 | Risk | 风险与技术债 |
| 9 | AntiPattern | 反模式与坏味道 |
| 10 | Principle | Always/Never/Prefer/Avoid |

→ 全部 Extractor prompts: [prompts/extractors/](prompts/extractors/)

## 后续 Stage

| Stage | Prompt | 模板 |
|-------|--------|------|
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)

## 反例黑名单

> 禁止: ① 修改源码（只写知识文件） ② 跳过CHECKPOINT确认 ③ agent提前返回不等待全部完成 | → [完整清单](references/boundary.md)

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Extractor Prompts | [prompts/extractors/](prompts/extractors/) |
| Verifier | [prompts/verifier.md](prompts/verifier.md) |
| Knowledge Builder | [prompts/knowledge-builder.md](prompts/knowledge-builder.md) |
| INDEX Generator | [prompts/index-generator.md](prompts/index-generator.md) |
| 职责边界+反例 | [references/boundary.md](references/boundary.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |

## 完成后下一步 → /project-planner 或 /project-architect
