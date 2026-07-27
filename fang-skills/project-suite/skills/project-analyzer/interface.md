# Interface: project-analyzer

> 对外契约。改变本文件只有在 skill 的本质 capability 变化时。

## Produces
- **KnowledgeBase** — `.project-knowledge/`（架构/组件/API/模式/观察 + graph/statistics/search-index）
- **Context** — `context.json`（技术栈/别名/约定/模块清单）

## Consumes
- 🟢 SourceCode（源码目录，缺失则 BLOCKED）

## Guarantees
- 知识库文件含 Evidence Header（`generatedBy` + `sources` + `confidence`）
- `manifest.json` 记录执行状态（dimensions + files + statistics）
- 增量模式产出含 `[NEW]/[CHANGED]/[CONFIRMED]` 标记

## Failure
| 条件 | 模式 | 行为 |
|------|------|------|
| 源码目录不可读 | BLOCKED | 终止，manifest.status = blocked |
| 维度 agent 执行失败 | DEGRADED | 该维度标记 failed，其余继续 |
| vaultPath 不可达 | DEGRADED | 跳过 Vault 同步，本地产出不受影响 |
| manifest 状态异常 | DEGRADED | 按 checkpoint 协议恢复，失败则全量重扫 |
