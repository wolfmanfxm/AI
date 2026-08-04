# Code Audit — Architect

> @engine: code-audit

## Actions

对设计范围内的每个模块标注：
- `[已实现]` — 模块存在且功能完整 → 不重新设计
- `[部分实现]` — 模块存在但需扩展 → 在现有架构上扩展
- `[未实现]` — 全新模块 → 出完整设计方案

→ 详细方法：[references/code-audit.md](../references/code-audit.md)

## Exit

- 所有涉及模块已标注实现状态
- 设计范围已根据标注修正

## Failure

| Condition | Action |
|-----------|--------|
| 源码不可读（无权限/路径错误） | 标注 `⚠️ 未核实`，按未实现出方案（不基于猜测做架构决策） |
