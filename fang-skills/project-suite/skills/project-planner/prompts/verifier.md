# Verifier — Planner

> 独立验证 Candidate PLAN。不参与规划过程。

## Checks

> **检查项的唯一权威是 [validation.md](validation.md) 的 `## Checks` 表**——本文件不再重复维护一份。
> （2026-09-18 收敛：此前两个文件各有一张高度重复的检查表，改一处必忘另一处。）
>
> 本文件的职责是定义**验证对象与判定规则**，不是定义检查项。

## 判定

| 条件 | 判定 |
|------|------|
| V1-V8 全部通过 | ✅ Accepted |
| V2 失败(循环依赖) | ❌ Rejected — 重新设计 |
| Confidence < 40% | ❌ Rejected — 仅输出 Goal+Scope+Gap List |
| V3-V8 部分失败 | 🟡 Accepted + adjusted confidence |

## Evidence Format

```yaml
candidate: PLAN-interest-rate-adjustment.md
verdict: accepted
confidence: 0.82
evidence:
  sections: { goal: true, scope: true, context: true, reuse: true, decision: 6, tasks: 10, deps: "acyclic", risk: 6, ac: 8 }
  ac_verifiable: "8/8 (100%)"
  decisions_bound: "6/6 (100%)"
  task_estimates: { total_days: 12, max_single: 2.5 }
  reuse_verified: "8/8 references exist"
```
