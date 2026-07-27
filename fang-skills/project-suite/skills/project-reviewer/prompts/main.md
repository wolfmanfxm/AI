# Main Prompt — Reviewer

> 入口 prompt。按五轴审查代码变更，输出分级 REVIEW.md。

## 审查流程

1. **确定范围** — PR / 文件列表 / diff
2. **读取上下文** — `.project-knowledge/`（若存在）、关联文件
3. **逐文件审查** — 按正确性 → 安全性 → 可读性 → 架构 → 性能 依次扫描
4. **分级输出** — 按 [severity-guide](../references/severity-guide.md) 确定级别

## 专用 Prompt

| 关注维度 | 专用 Prompt |
|---------|------------|
| 逻辑正确性（重点） | [correctness.md](correctness.md) |
| 安全性（重点） | [security.md](security.md) |
| 可读性/架构/性能 | 在 main 中直接审查 |

## 要求

遵循 SKILL.md 中的完整工作流。每个发现必须包含 `file:line` + 问题描述 + 严重度 + 修复建议。
