---
name: project-documenter
metadata: skill.yaml
description: >
  生成和维护项目文档：API 文档（从 JSDoc/代码提取）、README、ADR、Changelog、组件文档。
  自动匹配项目已有文档风格，所有内容基于代码事实不编造。
  触发词：生成文档、写文档、补文档、API 文档、README、更新文档、补全文档、
  generate docs、write documentation、update README、api docs、组件文档。
  产出：文档文件（.md），含 Evidence Header。API/组件文档同步到 Knowledge Vault。
---

# Documenter

> 代码 + 上下文 → 结构化、可溯源、风格一致的技术文档
> Candidate → Verify → Accept | 遵循 [workflow-engine](../../workflow-engine/SKILL.md) — stages 声明 + prompts 业务逻辑

## 核心原则

1. **基于代码事实** — 从源文件提取，不编造
2. **匹配已有风格** — 读 1-2 份已有文档，模仿结构
3. **可溯源** — 每个关键信息标注 `file:line`
4. **自动同步** — API/组件文档同步到 Knowledge Vault

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | 源码文件 | 🔴 BLOCKED |
| 1 | 已有文档（风格参考） | 🟡 DEGRADED — 默认模板 |
| 2 | `.project-knowledge/` | 🟢 SKIP |

## 工作流

| Stage | Prompt | 模板 |
|-------|--------|------|
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @engine: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @engine: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @engine: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @engine: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @engine: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)

## 反例黑名单

> 禁止: ① 不读源码直接从类型定义编造 ② 覆盖已有文档人工章节 ③ 不标注file:line溯源 | → [完整清单](references/boundary.md)

## Common Rationalizations

> "类型定义已经很清楚了，不需要读源码" → 仍然 Read 源码
> "风格差不多就行，不用完全匹配" → 必须匹配已有文档风格
> "这个参数含义很明显，不用标注 file:line" → 每个关键信息必须溯源

## 失败处理

> 一线修复 → 兜底模式: [failure-handling.md](references/failure-handling.md) | 每stage详见 [prompts/](prompts/) | 恢复: manifest.json → [checkpoint](../../runtime/engine/checkpoint.md)

## 引用索引

| 资源 | 路径 |
|------|------|
| workflow-engine | [../../workflow-engine/SKILL.md](../../workflow-engine/SKILL.md) |
| Stage Discovery | [prompts/discovery.md](prompts/discovery.md) |
| Stage Execution | [prompts/execution.md](prompts/execution.md) |
| Stage Validation | [prompts/validation.md](prompts/validation.md) |
| Stage Delivery | [prompts/delivery.md](prompts/delivery.md) |
| API 文档 Prompt | [prompts/api-doc.md](prompts/api-doc.md) |
| 组件文档 Prompt | [prompts/component-doc.md](prompts/component-doc.md) |
| README Prompt | [prompts/readme-gen.md](prompts/readme-gen.md) |
| 文档风格指南 | [references/doc-style-guide.md](references/doc-style-guide.md) |

## 完成后下一步 → /project-releaser 或 ✅
