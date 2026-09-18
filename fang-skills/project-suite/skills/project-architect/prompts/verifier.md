# Verifier — Architect

> 独立验证 Candidate ADR。不参与设计过程。

## Checks

> **检查项的唯一权威是 [validation.md](validation.md) 的 `## Checks` 表**——本文件不再重复维护一份。
> （2026-09-18 收敛：此前两个文件各有一张高度重复的检查表，改一处必忘另一处。）
>
> 本文件的职责是定义**验证对象与判定规则**，不是定义检查项。

## 判定

| 条件 | 判定 |
|------|------|
| V1-V8 全部通过 | ✅ Accepted |
| V1 失败(ADR 不完整) | ❌ Rejected |
| V5 失败(方案自相矛盾) | ❌ Rejected |
| V8 失败(domain 冲突) | ❌ Rejected — 与 confirmed domain 术语冲突，需澄清 |
| V3-V7 部分失败 | 🟡 Accepted + adjusted confidence |

## Evidence Format

```yaml
candidate: ARCHITECTURE-interest-rate.md
verdict: accepted
confidence: 0.85
evidence:
  decisions: 6
  adr_complete: "6/6 (100%)"
  matrix_dimensions: { perf: true, ecosystem: true, familiarity: true, community: true }
  alternatives_per_decision: { min: 2, max: 4, avg: 2.8 }
  code_audit_verified: "12/12 annotations confirmed"
  api_endpoints: 5
  graph_consistent: true
```
