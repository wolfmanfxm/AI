# Validation — Tester

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | AC 逐条覆盖 | 每条 AC 至少 1 个测试用例 | 补全缺失用例 |
| V2 | 边界条件覆盖 | null/undefined/空值/超长 场景有测试 | 补全边界用例 |
| V3 | 测试可执行 | `npx vitest run` 无语法/配置错误 | 修正后重试（最多 2 次） |
| V4 | 无篡改源码 | 测试文件不含被测源码的修改 | 回滚修改 |
| V5 | 覆盖率可度量 | 有明确的覆盖率基线或对比 | 标注"⚠️ 无基线" |

## QA Agent

**触发条件**：关键模块测试（AC >10 或 Risk=HIGH）

**方法**：spawn 独立 agent，仅读测试文件 + AC（不含对话上下文），验证 AC 覆盖完整性

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Output

- `*.test.ts` / `*.spec.ts`（测试代码）
- `.project-knowledge/reports/TEST-REPORT.md`（覆盖率摘要 + AC 对照表 + QA findings + 失败分析）

## Exit

无 CRITICAL 发现（所有 AC 已覆盖，测试可执行，未篡改源码）
