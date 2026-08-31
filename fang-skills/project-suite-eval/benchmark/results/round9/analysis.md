# Round 9 分析 — 声明收口 + lifecycle policy-only 验证

> 验证最近几轮「声明收口 + finish-workflow 不自动 Accepted」改动的真实效果。
> 本轮是轻量验证（suite-only，不跑 native 对比）：1 个 generator（命名无回归）+ 1 个 analyzer（不自动 Accepted）。

## 结果总览

| # | 改动 | 判定 | 证据 |
|---|------|------|------|
| 1 | 命名收口（Engine→Protocol/Routing、删 query-api、knowledge-query.md→knowledge-access.md、graph_refresh→skill_ir_refresh、删 decay schema） | ✅ 无回归 | G1 `naming_regression=false`，9 个被引用子文件逐一校验无断链 |
| 2 | finish-workflow「occurrences ≥3 → 标记可晋升候选（不自动 Accepted）」+ promotion-rules 去「自动」 | ✅ 生效 | A1 `auto_accepted=false`，occurrences≥3 文件保持 `candidate` |
| 3 | resolver 健壮性（basename 匹配 + garbage 告警） | ✅ 静态已验 | check-e2e-smoke 第 5 段 2 项断言；本轮未单独跑 |

## #1 命名收口无回归（G1）

**任务**：实现批量导入组件（模板下载 + 文件选择上传 + 校验结果反馈）。

**结果**：REUSE `ImportDialog` 零改动（复现 N2-M3 的「复用判定零改动」行为），`decision_record` D1-D6，`requirement_coverage` 1.0。

**无回归关键证据**：全程无「knowledge-query.md / Knowledge Query / Decision Engine / Skill Resolver」等改名相关困惑；agent 逐一校验 `context-resolver.md`、`graph-query.md`、`reuse-check.md`、`command-guard.md`、`confidence.yaml`、`knowledge-scoring.md` 等 9 个被引用子文件均存在无断链。命名收口（round 4/5 的 Engine→Protocol、knowledge-query→knowledge-access、graph_refresh→skill_ir_refresh）未引入回归。

## #2 不自动 Accepted（A1）

**任务**：预置 `patterns/table.md`（occurrences=3, status=candidate），按 finish-workflow.md Phase B step 7 当前指令处理。

**结果**：

| 信号 | 值 |
|------|-----|
| `auto_accepted` | **false** |
| `final_status` | `candidate`（未自动晋升 Accepted） |
| 依据 | finish-workflow.md 原文「occurrences ≥3 → 标记可晋升候选（不自动 Accepted）；真正 Accepted 由 Reviewer/promotion-reviewer 验证后更新」 |

**结论**：agent 读了新指令后，不再把 occurrences≥3 自动晋升 Accepted，而是保持 `candidate` 并 defer 给 Reviewer。这是「改声明 → 改消费」的正面闭环（finish-workflow.md 既是声明也是 analyzer 的消费 prompt，改动即被消费）。

## 发现（语义缝隙，非本轮改动引入）

A1 指出：finish-workflow.md 写「标记**可晋升候选**」，但 `status` 枚举只有 `Artifact/Candidate/Accepted/Deprecated` 四值，「可晋升候选」不是第 5 个枚举值。agent 正确理解为「保持 candidate + 晋升资格」，但措辞略有歧义（像是要写一个新 status 值）。

**建议**：把 finish-workflow.md 的「标记可晋升候选」收紧为「保持 Candidate（标记为可晋升）」，避免 agent 误解为要写新枚举值。属 wording 收口，非行为 bug。

## 结论

- #1 命名收口：**无回归** ✅
- #2 不自动 Accepted：**生效** ✅

最近几轮「声明收口」改动（Engine→Protocol、删 query-api、knowledge-access、skill_ir_refresh、删 decay）均未引入回归；唯一行为改动「不自动 Accepted」真实生效，且是「改声明+改消费同步」的正面闭环（对照 round5 #1 的「改声明没改消费」）。
