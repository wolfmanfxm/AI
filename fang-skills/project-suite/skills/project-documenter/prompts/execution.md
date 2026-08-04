# Execution — Documenter

> @engine: execution

## Actions

### 1. 读源码

Read 目标源文件，提取关键信息：

| 文档类型 | 提取内容 | Prompt |
|----------|---------|--------|
| API 文档 | 函数签名/参数/返回值/使用示例/鉴权要求 | [prompts/api-doc.md](api-doc.md) |
| 组件文档 | Props/Events/Slots/使用示例/依赖 | [prompts/component-doc.md](component-doc.md) |
| README | 项目名/简介/安装/使用/架构/贡献 | [prompts/readme-gen.md](readme-gen.md) |

### 2. 匹配风格

→ [references/doc-style-guide.md](../references/doc-style-guide.md)
- 套用 Discovery 阶段提取的标题层级/表格样式/代码块格式
- 保持与项目已有文档的一致性

### 3. 标注溯源

- 每个关键信息标注 `file:line`（如 `workspace/api/user.ts:42`）
- JSDoc 缺失 → 从类型定义推断 → 标注 `[推断]`
- 逻辑复杂无法简单描述 → 写概要 + 标注 `详见: file:line`

🔴 CHECKPOINT — 展示文档预览（前 20 行 + 目录结构），用户确认后写入

## Exit

- 文档草稿完成（所有关键信息已提取）
- 风格与已有文档一致
- 用户确认预览

## Failure

| Condition | Action |
|-----------|--------|
| JSDoc 注释缺失或不完整 | 从类型定义推断参数/返回值 → 标注 `[推断]` |
| 代码逻辑复杂 | 写概要 + 标注 `详见: file:line` → 不编造 |
| 目标文档已存在 | 对比差异 → 仅更新变更部分 → 保留人工章节 → 冲突标 `[CONFLICT]` |
