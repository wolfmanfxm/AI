# Verifier — Reviewer

> 独立验证 Candidate findings。Fresh context，不参与审查过程。

## Checks

> **检查项的唯一权威是 [validation.md](validation.md) 的 `## Checks` 表**——本文件不再重复维护一份。
> （2026-09-18 收敛：此前两个文件各有一张高度重复的检查表，改一处必忘另一处。）
>
> 本文件的职责是定义**验证对象与判定规则**，不是定义检查项。

## 判定

全部通过 → Accepted。V1 失败 → Rejected。V6 发现 drift → 输出独立 "Domain Terminology Drift" 章节。V7 发现 placement mismatch → 输出独立 "Placement Mismatch" 章节（🔴 BLOCKER，落错目录不可静默放过）。其余 🟡 Accepted + adjusted confidence。
