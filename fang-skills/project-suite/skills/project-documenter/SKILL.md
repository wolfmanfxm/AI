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

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **不读源码直接从类型定义编造文档** | 类型定义不反映实际行为（中间件/拦截器/运行时逻辑），文档与行为不符 | 先 Read 源文件理解逻辑，再结合类型定义撰写，不确定的标 `[推断]` |
| 2 | **忽略项目已有文档风格另起炉灶** | 同一项目出现两种文档格式，后来者困惑哪个是"正确格式" | Discover 阶段必读 1-2 份已有文档，提取标题层级/表格样式/代码块语言标注 |
| 3 | **覆盖已有文档的人工撰写章节** | 人工补充的业务背景/注意事项/已知坑点被覆盖后丢失 | 对比差异，仅更新变更部分，保留人工撰写的章节，冲突处标注 `[CONFLICT]` |
| 4 | **API 文档不标注 file:line 溯源** | 源码更新后文档无人敢改——不知道哪段对应哪行代码 | 每个关键信息（方法/参数/返回值）标注 `file:line` 指向源文件 |
| 5 | **文档发布后不同步 Knowledge Vault** | API/组件文档只在本地 .md，其他项目无法复用 | 检查 document 类型标识，API/组件文档 → Vault 同步 |

## 前置条件

| 优先级 | 资源 | 缺失时 |
|--------|------|--------|
| 0 | **源码文件** | 🔴 BLOCKED |
| 1 | 已有文档（风格参考） | 🟡 DEGRADED — 默认模板 |
| 2 | `.project-knowledge/` | 🟢 SKIP — 无则默认风格 |

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

1. **读源码** — Read 目标源文件，提取关键信息（函数签名/参数/返回值/使用示例）
2. **匹配风格** → [references/doc-style-guide.md](references/doc-style-guide.md) — 套用 Discover 阶段提取的标题/表格/代码块格式
3. **标注溯源** — 每个关键信息标注 `file:line`（如 `workspace/api/user.ts:42`）
4. 🔴 CHECKPOINT → 展示文档预览，确认后写入。

### Output

**写入文件**：按文档类型路由到对应路径（`api/<module>.md` / `components/<name>.md` / `README.md`）

**Vault 同步** → [vault-sync](../../shared/conventions/vault-sync.md)：API/组件文档 ✅ 同步，README/Changelog ❌ 不同步

**文档新鲜度**（推荐在 analyzer 增量后执行）：读 manifest → 变更文件 → 交叉命中文档 `sources` → 标注 `[OUTDATED][MATCH][NEW]`

## 失败处理

| 触发条件 | 一线修复 | 仍失败兜底 |
|---------|---------|-----------|
| 源文件不可读/不存在 | 标注 `⚠️ 源文件不可读: {path}`，跳过该文件 | 若所有源文件不可读 → BLOCKED |
| 无已有文档可提取风格 | 使用默认模板（API: 方法+路径+参数+响应 / 组件: Props+Events+Slots+示例） | 标注"⚠️ 默认风格，建议人工审核后调整" |
| 目标文档已存在（非首次） | 对比差异，仅更新变更部分，保留人工撰写的章节 | 标注 `[CONFLICT]` 的章节 AskUserQuestion |
| JSDoc/JSDoc 注释缺失或不完整 | 从类型定义推断参数/返回值 | 标注 `[推断]`，不确定的标 `[待补充]` |
| 代码逻辑复杂无法简单描述 | 写概要 + 标注 `详见: file:line` | 不编造不完整的逻辑描述 |

## 引用索引

| 资源 | 路径 |
|------|------|
| 入口 Prompt | [prompts/main.md](prompts/main.md) |
| API 文档 | [prompts/api-doc.md](prompts/api-doc.md) |
| 组件文档 | [prompts/component-doc.md](prompts/component-doc.md) |
| README 生成 | [prompts/readme-gen.md](prompts/readme-gen.md) |
| 职责边界 | [references/boundary.md](references/boundary.md) |
| 文档风格 | [references/doc-style-guide.md](references/doc-style-guide.md) |
| 失败处理 | [references/failure-handling.md](references/failure-handling.md) |

## 完成后下一步

```
documenter 完成 → /project-releaser 或 ✅
```
