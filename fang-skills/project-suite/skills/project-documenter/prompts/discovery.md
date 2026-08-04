# Discovery — Documenter

> @engine: discovery

## Actions

1. 确认文档类型：API 文档 / 组件文档 / README / Changelog
2. 读 1-2 份已有文档，提取风格特征：
   - 标题层级（#/##/###）
   - 表格样式（对齐方式、表头格式）
   - 代码块语言标注（```typescript / ```vue）
   - Evidence Header 格式
3. CHECKPOINT — 展示文档类型 + 风格参考 + 范围

## Exit

- 文档类型已确认
- 风格参考已提取
- 用户确认文档范围

## Failure

| Condition | Action |
|-----------|--------|
| 无已有文档可提取风格 | 使用默认模板：API→方法+路径+参数+响应，组件→Props+Events+Slots+示例 |
| 源文件不可读 | 🔴 BLOCKED — 所有源文件不可读则拒绝执行 |

## CHECKPOINT

🔴 CHECKPOINT
