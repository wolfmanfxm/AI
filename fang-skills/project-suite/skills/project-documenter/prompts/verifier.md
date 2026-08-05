# Verifier — Documenter

> 独立验证 Candidate 文档。Fresh context，不参与文档生成。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 溯源准确 | 每个 file:line 引用指向正确代码 | 修正引用 |
| V2 | 风格一致 | 标题/表格/代码块与已有文档一致 | 修正风格 |
| V3 | 无编造 | 所有断言在源码中有对应 | 标注 `[推断]` 或删除 |
| V4 | 链接可达 | 所有内部链接目标文件存在 | 修正链接 |

## 判定

全部通过 → Accepted。V1/V3 失败 → Rejected。其余 🟡 Accepted。
