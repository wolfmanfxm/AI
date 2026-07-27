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

## 核心原则

1. **基于代码事实** — 从源文件提取，不编造
2. **匹配已有风格** — 读 1-2 份已有文档，模仿结构
3. **可溯源** — 每个关键信息标注 `file:line`
4. **完整不冗余** — 覆盖关键信息

## 职责边界

→ [references/boundary.md](references/boundary.md)

## 文档类型

| 类型 | 产出 | Vault | 指南 |
|------|------|-------|------|
| API 文档 | `api/<module>.md` | ✅ | [prompts/api-doc.md](prompts/api-doc.md) |
| 组件文档 | `components/<name>.md` | ✅ | [prompts/component-doc.md](prompts/component-doc.md) |
| README | `README.md` | ❌ | [prompts/readme-gen.md](prompts/readme-gen.md) |
| Changelog | `CHANGELOG.md` | ❌ | 参考 releaser |

## 工作流

### Discover

1. 确认文档类型+范围，读 1-2 份已有文档提取风格
2. 🔴 CHECKPOINT → [checkpoint 模式](../../shared/conventions/checkpoint-pattern.md)

### Execute

风格匹配 → [references/doc-style-guide.md](references/doc-style-guide.md)

🔴 CHECKPOINT → 展示文档预览，确认后写入。

### 知识库同步

→ [vault-sync](../../shared/conventions/vault-sync.md) — API/组件文档 ✅，README/Changelog ❌

### 文档新鲜度

建议 analyzer 增量后执行：读 manifest → 变更文件 → 交叉命中文档 `sources` → `[OUTDATED][MATCH][NEW]`

失败处理 → [references/failure-handling.md](references/failure-handling.md)

## 完成后下一步

```
documenter 完成 → /project-releaser 或 ✅
```
