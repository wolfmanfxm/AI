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

## 判定

全部通过 → Accepted。V1 失败 → Rejected。V6 发现 drift → 输出独立 "Domain Terminology Drift" 章节。其余 🟡 Accepted + adjusted confidence。
