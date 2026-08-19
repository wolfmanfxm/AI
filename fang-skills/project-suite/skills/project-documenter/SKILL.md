---
name: project-documenter
metadata: skill.yaml
description: >
  生成和维护项目文档：API 文档（从代码注释提取）、README、ADR、Changelog、组件文档。
  自动匹配项目已有文档风格，所有内容基于代码事实不编造。
  触发词：生成文档、写文档、补文档、API 文档、README、更新文档、补全文档、
  generate docs、write documentation、update README、api docs、组件文档。
  产出：文档文件（.md），含 Evidence Header。API/组件文档同步到 Knowledge Vault。
---

# Documenter

> 代码 + 上下文 → 结构化、可溯源、风格一致的技术文档
> Execute → Verify | 遵循 [workflow-protocol](../../workflow-protocol/SKILL.md) — stages 声明 + prompts 业务逻辑

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
| Discovery | [prompts/discovery.md](prompts/discovery.md) | @template: discovery |
| Execution | [prompts/execution.md](prompts/execution.md) | @template: execution |
| Verify | [prompts/verifier.md](prompts/verifier.md) | @template: validation |
| Validation | [prompts/validation.md](prompts/validation.md) | @template: validation |
| Delivery | [prompts/delivery.md](prompts/delivery.md) | @template: delivery |

## 职责边界

→ [references/boundary.md](references/boundary.md)（反例黑名单 + 失败兜底 + 常见借口）

> 完成后：/project-releaser。通用约束 → [workflow-protocol](../../workflow-protocol/SKILL.md)；git/命令护栏 → [command-guard](../../runtime/mechanisms/command-guard.md)。
