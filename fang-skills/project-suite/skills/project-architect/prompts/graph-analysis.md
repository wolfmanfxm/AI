# Graph Analysis — Architect

> @template: graph-analysis

## Actions

→ [Graph Query Protocol](../../../runtime/contracts/graph-query.md)

1. `findDependencies(<目标模块>)` → 了解当前模块耦合度
2. 全图 edges 按 `group` 聚合 → 识别跨层依赖（view→infrastructure 标注为架构异常）
3. `findConsumers(<目标 API>)` → 修改 API 契约时了解影响范围
4. 循环依赖检测：A→B 且 B→A → 标注为架构风险，建议重构
5. CHECKPOINT — 展示 Graph 分析结果

## Exit

- 耦合度已评估
- 跨层依赖已标注
- 影响范围已了解
- 用户确认分析结果，设计范围已根据分析调整

## Failure

| Condition | Action |
|-----------|--------|
| graph.json 不可用（缺失或解析失败） | grep import 手动分析依赖链 → 标注 `⚠️ 无 Graph` |
