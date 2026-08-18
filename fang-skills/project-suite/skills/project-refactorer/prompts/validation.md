# Validation — Refactorer

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 行为不变 | 重构前后测试结果一致（全绿→全绿） | 🔴 BLOCK — Edit 回滚 |
| V2 | 指标改善 | 圈复杂度/行数/重复率 至少一项改善 >10% | 标注"⚠️ 边际改善" |
| V3 | 范围受控 | 改动文件 ≤5，每个 commit 一个动作 | 拆分过大的重构 |
| V4 | 测试保护 | 每次重构前测试全绿，重构后仍全绿 | 停止重构，先修测试 |
| V5 | Commit 原子性 | 每个 commit 只做一件事，message 描述具体动作 | 拆分混合 commit |

## QA Agent

**触发条件**：改动文件 >3

**方法**：spawn 独立 agent，仅读重构后代码 + 测试结果（不含对话上下文），验证：
1. 外部行为是否真的没变（对比 API 签名、返回值类型）
2. 是否有意外的副作用（import 变更、全局状态修改）

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Exit

无 CRITICAL 发现（行为不变、指标改善、范围受控）
