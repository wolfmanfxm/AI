# Verifier — Reviewer

> 独立验证 Candidate findings。Fresh context，不参与审查过程。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | file:line 有效 | 每个 finding 的路径+行号对应文件存在 | 修正引用 |
| V2 | 分级合理 | BLOCKER 有明确阻断理由 | 调整分级 |
| V3 | 五轴覆盖 | 每轴至少 1 条记录 | 补全未覆盖轴 |
| V4 | AC 对照 | AC 表逐条 ✅/❌/⚠️ | 补全遗漏 |
| V5 | 修复可操作 | 每个 finding 的修复建议具体可执行 | 标注 `[VAGUE]` |
| V6 | Domain Terminology Drift | 代码中同一概念是否用了多个词（Customer/CustomerInfo/Client 混用），对照 vocabulary.yaml；**页面/API 命名是否偏离 artifacts 的 naming 前缀**（「退款记录」用了泛化 RefundRecord 而非 vocabulary 的 orderRefundRecord） | 报 `Domain Terminology Drift`，标注统一术语 |
| V7 | Placement Correctness | **Plan 的 target 决议（module/domain/placement）与实际修改/新建路径是否一致**——Planner 判断正确但 Generator 未遵循时，最终落错目录（如 Plan target 是 customerManage 但代码落在 baseData）。对照 PLAN.md 每个 Task 的「放置决议」字段 vs 实际 diff 文件路径 | 报 `Placement Mismatch`，标注 Plan target vs 实际路径，阻断（视为 BLOCKER，因为落错目录难回退） |

## 判定

全部通过 → Accepted。V1 失败 → Rejected。V6 发现 drift → 输出独立 "Domain Terminology Drift" 章节。V7 发现 placement mismatch → 输出独立 "Placement Mismatch" 章节（🔴 BLOCKER，落错目录不可静默放过）。其余 🟡 Accepted + adjusted confidence。
