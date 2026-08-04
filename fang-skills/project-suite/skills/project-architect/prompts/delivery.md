# Delivery — Architect

> @engine: delivery

## Actions

写入 `.project-knowledge/decisions/ARCHITECTURE-<topic>.md`：
- ADR 决策记录（问题→候选→选择→理由）
- 模块图（mermaid 或文本）
- API 契约（endpoint 列表）
- Graph 分析摘要

## Exit

- `ARCHITECTURE-<topic>.md` 写入成功
- state.json 更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
