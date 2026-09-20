---
name: project-analyzer
metadata: skill.yaml
description: >
  分析软件项目并生成可复用的项目知识库：Multi-Extractor 架构（10 个提取器 + Candidate→Verify→Accept + Evidence Score + INDEX.md）。
  触发词：分析项目、代码分析、项目审计、扫描项目、梳理组件、更新项目知识、刷新项目知识、
  项目规范、编码规范、analyze codebase、scan project、project refresh。
  不用于：已有知识覆盖且无明显漂移的普通开发任务。
---

# Analyzer

> 10 Extractor → Candidate → Evidence → 5-Verify → Knowledge Objects → graph.json + recommendations/（现状 vs 应然建议）
> 遵循 [workflow-protocol](../../workflow-protocol/SKILL.md) — Registry-driven + Evidence-based Knowledge Graph

## 核心原则

1. **每个 Extractor 只提取一种知识** — 不做全才，做专才
2. **先候选再验证** — 不直接写入（verification.mode: candidate-verify-accept）
3. **Evidence Score 溯源** — 每个 Claim 标注证据（路径+行号+次数）
4. **Rejected 保留** — 失败的知识也存档，供后续分析

## 何时触发（知识缺口入口）

> Analyzer 不是默认入口，是**知识缺口入口**：只在 `.project-knowledge/` 不存在 / 未覆盖当前领域 / `last_scan` 过期时才跑。已有知识库且覆盖当前任务 → 跳过 Analyzer，用 Knowledge Resolver → Reuse（见 [Complexity Gate ②b](../../shared/prompts/complexity-gate.md)）。

> **增量分析（Incremental Analysis）**：知识库存在、但只有某个领域缺失时，只跑该领域相关的 Extractor，局部更新 graph.json + 对应 .md——不重跑全部 10 个 Extractor。全量 10-Extractor 扫描只在「知识库不存在 / 结构漂移」时才做。

> **跳过时的 drift 抽查**：知识库新鲜、决定跳过全量分析时，仍需做一次**轻量 drift 抽查**——读 package.json / 配置文件 + 抽查 1-2 个代表源码，比对 KB 的关键结论（技术栈版本、构建脚本、命名约定）是否仍一致。发现漂移 → 只局部修正漂移的对应 .md，不重跑全量。这是「盲信复用」与「全量重扫」之间的中间路径。

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 项目源码 | 🔴 BLOCKED |
| 1 | Knowledge Vault 路径 | 🟡 DEGRADED |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @template: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @template: execution |

> 8-Phase 执行详见 [prompts/execution.md](prompts/execution.md)；10 个 Extractor 详见 [prompts/extractors/](prompts/extractors/)。

## 后续 Stage

| Stage | Prompt | 模板 |
|-------|--------|------|
| Validation | [prompts/validation.md](prompts/validation.md) | @template: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @template: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）

> 完成后：/project-planner 或 /project-architect。通用约束 → [workflow-protocol](../../workflow-protocol/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/mechanisms/command-guard.md)。
