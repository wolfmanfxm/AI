# Verifier — Reviewer

> 独立验证 Candidate findings。Fresh context，不参与审查过程。
>
> ⚠️ **独立性是可观测的，不是声明**：必须用 `Agent` / `Task` 工具派生独立执行者。
> 在同一上下文里「按盲扫→对照顺序」模拟 verifier **不算** Independent QA；
> 若 Host 不支持派生，产出 `[QA NOT INDEPENDENT: 同上下文替代]`，不得写成已完成。
> 证据：eval ledger · `reviewer-verifier-independence`。

## 两段式顺序（`validation.md · QA Agent` 触发条件命中时）

同一次 fresh-context 运行内，顺序固定：

1. **盲扫**：只读 diff + `PLAN.md > # Acceptance Criteria` + `findConsumers` 结果，
   找 REVIEW.md 可能漏掉的 BLOCKER 级问题。**此步不得先读 REVIEW.md 草稿**——
   先读结论会把 fresh context 锚定成主审查的复读机，盲扫就失效了。
2. **对照**：再读 REVIEW.md 草稿，逐条判依据是否成立（按 [validation.md](validation.md) 的 `## Checks` 表；V9 的触发判定由主审查在 Validation 阶段给出，本 verifier 只核对产物是否有 `## Independent QA`），并把盲扫新发现标 `Missed`。

未命中触发条件时只做第 2 步（原职责）。

## 派生纪律（避免撞 Host 轮次上限）

- 单次派生先交付 **Phase A 最小报告**（探索 ≤10 轮）：盲扫发现 + 每条 file:line 即可；
  拿到结果后再按需补 Phase B，不要在一个派生里把探索和对照全展开。
- 接近 Host 轮次上限时，先输出已有结论并标 `[PARTIAL]`，不得静默超时。
- 主会话若未收到报告，可用 SendMessage 续跑；续跑只补未完成的部分，不重做已完成部分。

## Checks

> **检查项的唯一权威是 [validation.md](validation.md) 的 `## Checks` 表**——本文件不再重复维护一份。
>
> 本文件的职责是定义**验证对象与判定规则**，不是定义检查项。

## 判定

全部通过 → Accepted。V1 失败 → Rejected。V7 发现 drift → 输出独立 "Domain Terminology Drift" 章节。V8 发现 placement mismatch → 输出独立 "Placement Mismatch" 章节（🔴 BLOCKER，落错目录不可静默放过）。其余 🟡 Accepted + adjusted confidence。
