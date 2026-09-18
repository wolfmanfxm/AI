# Validation — Refactorer

> @template: validation

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

→ [qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Verification（独立验证子流程，**非 Stage**）

本阶段在 Exit 前加载 [verifier.md](verifier.md)，以 fresh context 执行独立验证（不参与本阶段产出）。

> 依据 `skill.yaml` 的 `verification: { mode: direct-verify }` → 见
> [workflow-protocol · Verification Contract](../../../workflow-protocol/SKILL.md)。
> ⚠️ 上方 `## Checks` 表与本 skill 的 `verifier.md` 检查项**当前内容高度重叠**——两份必须同步改，
> 尚未收敛为单一来源（见 roadmap 已知缺口）。

## Exit

无 CRITICAL 发现（行为不变、指标改善、范围受控）
