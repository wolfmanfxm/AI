# Interface: project-documenter

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **Documentation** — API/组件/Changelog 文档（`.md` + Evidence Header）

## Consumes
- 🔴 **Code**（源码文件，缺失则 BLOCKED）
- 🟡 **Review**（`REVIEW.md`，Changelog 生成时使用）
- 🟢 **KnowledgeBase**（`.project-knowledge/`，有则参考风格，无则默认）

## Guarantees
- 文档基于源码提取，标注 `file:line`
- 匹配已有文档风格（读 1-2 份现有文档）
- 不确定内容标 `[推断]` 或 `[待补充]`
- API/组件文档 → Vault 同步；Changelog → 保留本地

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 源文件不可读 | DEGRADED | 标注 `⚠️ 源文件不可读`，跳过 |
| 无已有文档风格参考 | DEGRADED | 使用默认风格 |
| 目标文档已存在 | DEGRADED | 仅更新差异，不覆盖人工章节 |
| content 冲突已有文档 | DEGRADED | 标记 `[CONFLICT]`，AskUserQuestion |
