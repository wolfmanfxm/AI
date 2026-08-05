# Verifier — Refactorer

> 独立验证 Candidate 重构。不参与重构执行。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 行为不变 | 重构前后测试结果一致 | ❌ Rejected → git revert |
| V2 | 指标改善 | 圈复杂度/行数/重复率 至少一项改善 >10% | 🟡 标注边际改善 |
| V3 | 范围受控 | 改动文件 ≤5，每个 commit 一个动作 | 🟡 拆分 |

## 判定

V1 失败 → ❌ Rejected(git revert)。全部通过 → Accepted。其余 🟡 Accepted。
