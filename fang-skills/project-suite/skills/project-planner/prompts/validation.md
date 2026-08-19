# Validation — Planner

> @template: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 9 模块完整 | 每个 Section 非空，内容 ≥3 行 | 返回 Execution 补全该 Section |
| V2 | 依赖无循环 | Task Dependency Graph 中无 A→B→A | 🔴 BLOCK — 重新设计依赖 |
| V3 | AC 可验证 | 每条 AC 有明确的 pass/fail 条件（不含"体验好""性能好"等主观描述） | 降级 confidence -10 |
| V4 | Decision→Task 绑定 | 每个 Decision 已标注影响哪些 Task | 补充映射 |
| V5 | 估时合理 | 单任务 ≤8h，总估时 ≤ 可用工时 | 标注风险 |

## QA Agent

**触发条件**：全量规划（Scope >3 个模块）或 confidence < 70

**方法**：spawn 独立 agent，仅读 PLAN.md + context.json（不含对话上下文），检查：
1. 逻辑一致性 — 各 Section 间有无矛盾
2. 遗漏 — PLAN.md 声称要做的和 AC 描述的是否对应
3. 依赖完整性 — 是否遗漏了隐性依赖

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Output

`validation-report.md`（同格式）+ 若 confidence ≥ 40 → 写入完整 PLAN.md + `context-package.json`

## Exit

- 无 CRITICAL 发现，或所有 CRITICAL 已修复
- confidence ≥ 40（否则只输出 Goal+Scope+Gap List）
