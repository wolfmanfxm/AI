# Verifier — Planner

> 独立验证 Candidate PLAN。不参与规划过程。

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 9 模块完整 | 每个 Section 非空且 ≥3 行 | 返回补全 |
| V2 | 依赖无循环 | Task Deps 图中无 A→B→A | ❌ Rejected |
| V3 | AC 可验证 | 每条 AC 含 pass/fail 条件 | 🟡 降级 confidence |
| V4 | Decision→Task | 每个 Decision 标注影响哪些 Task | 补充映射 |
| V5 | 估时合理 | 单任务 ≤8h，总估时 ≤ 可用工时 | 🟡 标注风险 |
| V6 | 复用准确 | Reuse Analysis 引用的组件/API 真实存在 | 修正引用 |
| V7 | Context 一致 | 引用的 context.json 字段与项目一致 | 修正引用 |
| V8 | Decision 语义合法 | ① 每个 D-XX 是「选择题/问句」：含 question/option/choice 语义（「还是 / 选哪种 / 归属哪个 / A:… / B:…」等），而非陈述句；② 不含实现/新增/修改/删除/构建/重构/开发/搭建/编写等实现动词；③ 模糊未知项标为 Gap 而非 Decision | 反例改写为 Task 或降级为 Gap |

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
