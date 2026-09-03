# Discovery — Reviewer

> @template: discovery

## Actions

0. **Context Resolver** → [Context Resolver](../../../runtime/contracts/context-resolver.md)：读 context-package.json 的 rules[]（blocking 约束）+ guidance[]（experience 里的风险/反模式）→ 对照审查重点
1. 加载 `PLAN.md > # Acceptance Criteria` + `# Risk Assessment` + `# Scope`
   - 若存在 `ARCHITECTURE.md`（design）→ 一并加载架构决策，作为「架构轴」对照基准
   - 若存在 `TEST-REPORT.md`（test）→ 一并加载测试结果，作为「回归风险」对照依据
2. 对照已知约束 + 风险/反模式（不读 .md）：
   - context-package.json 的 rules[]（blocking）→ 逐条对照，违反即 BLOCKER
   - context-package.json 的 guidance[]（experience）→ 重点关注
2. **上游 Confidence 检查**：读 `state.json` history → 检查 generator/tester 的 confidence → <70 → 审查强度自动升至 HIGH → [confidence-gate](../../../runtime/mechanisms/confidence-gate.md)
3. **Graph 影响分析** → [Graph Query Protocol](../../../runtime/contracts/graph-query.md)：
   - `findImpacted([变更文件列表])` → 本次修改影响哪些节点
   - `findConsumers(<受影响 API>)` → 修改 API 时了解下游影响
   - 影响节点 >5 → 审查强度自动升级为 HIGH
4. 按 Risk Assessment 确定审查强度：HIGH → Full audit / MEDIUM → Spot check / LOW → Standard
5. CHECKPOINT — 展示审查范围 + 影响节点 + 审查强度

## Exit

- 用户确认审查范围（全量/核心/指定文件）
- 审查强度已确定（HIGH/MEDIUM/LOW）

## Failure

| Condition | Action |
|-----------|--------|
| 变更文件 >20 | 只审核心文件（按变更量+风险排序），其余标注 `⚠️ 未审查` → AskUserQuestion：全审/核心/指定 |
| Graph 不可用（graph.json 缺失） | grep import 手动分析依赖链 → 标注 `⚠️ 无 Graph` |

## CHECKPOINT

🔴 CHECKPOINT — 确认审查范围+影响节点+审查强度
