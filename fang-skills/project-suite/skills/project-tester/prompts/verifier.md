# Verifier — Tester

> 独立验证 Candidate tests。不参与测试生成。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | AC 覆盖 | 每条 AC 至少 1 个测试用例 | 补全 |
| V2 | 边界覆盖 | null/undefined/空值/超长 场景有测试 | 补全 |
| V3 | 可执行 | `npx vitest run` 无语法/配置错误 | 修正后重试 |
| V4 | 无篡改源码 | 测试文件不含被测源码修改 | 回滚修改 |

## 判定

全部通过 → Accepted。V3 失败 → Rejected。其余 🟡 Accepted。
