# Validation — Architect

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | ADR 决策链完整 | 问题→候选方案→选择→理由 四段不缺 | 返回 Execution 补全 |
| V2 | 对比矩阵完整 | 候选方案 ≥2，维度 ≥3，分差有说明 | 补全矩阵或标注原因 |
| V3 | 现状核实准确 | `[已实现]` 标注的模块路径实际存在 | 修正标注 |
| V4 | API 契约可实施 | 每个 endpoint 有 method/path/request/response | 补全缺失字段 |
| V5 | 模块耦合合理 | 跨层依赖（view→infrastructure）已标注原因 | 标注架构风险 |

## QA Agent

**触发条件**：综合设计（含多个设计领域）

**方法**：spawn 独立 agent，仅读 ARCHITECTURE.md（不含对话上下文），检查：
1. 方案自洽性 — 技术选型、模块设计、API 契约之间是否有矛盾
2. 遗漏 — 是否有应该考虑的候选方案被忽略
3. 非功能性需求覆盖 — 安全/性能/可扩展性是否被考虑

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Exit

无 CRITICAL 发现（决策链完整、对比充分、无方案自相矛盾）
