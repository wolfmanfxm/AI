# Validation — Reviewer

> @template: validation

> reviewer 的 Validation 是**元审查** — 检查审查本身的质量

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 五轴全覆盖 | 每轴至少 1 条记录（含 PRAISE 或 PASS 标注） | 补全未覆盖轴 |
| V2 | file:line 有效 | 每个发现标注的路径+行号对应文件存在 | 修正引用 |
| V3 | AC 逐条对照 | AC 表逐条 ✅/❌/⚠️，无遗漏 | 补全遗漏 AC |
| V4 | 分级合理 | BLOCKER 有明确阻断理由（不为空且不泛泛），无 LOW 误标 BLOCKER | 调整分级 |
| V5 | Scope 边界 | 标注超出 PLAN.md `# Scope` 的变更项 | 补充 `[SCOPE CREEP]` |
| V6 | 修复可操作 | 每个 finding 的修复建议具体可执行 | 标注 `[VAGUE]` |
| V7 | Terminology Drift | 代码中同一概念是否用了多个词（Customer/CustomerInfo/Client 混用），对照 `.project-knowledge/architecture/glossary.md`；**页面/API 命名是否偏离其「产物 artifact」表的 `naming` 前缀**（「退款记录」用了泛化 RefundRecord 而非 glossary 的 `orderRefundRecord`） | 报 `Terminology Drift`，标注统一术语 |
| V8 | Placement Correctness | **Plan 的 target 决议（module/domain/placement）与实际修改/新建路径是否一致**——Planner 判断正确但 Generator 未遵循时，最终落错目录（如 Plan target 是 `<目标模块>` 但代码落在 `<错误模块>`）。对照 PLAN.md 每个 Task 的「放置决议」字段 vs 实际 diff 文件路径 | 报 `Placement Mismatch`，标注 Plan target vs 实际路径，阻断（视为 BLOCKER，因为落错目录难回退） |
| V9 | 独立 QA 触发判定 | 按 `## QA Agent` 的触发条件判定是否应跑；命中 → REVIEW.md 存在 `## Independent QA`、Phase A 未读 REVIEW.md 草稿、且由 `Agent`/`Task` 派生的独立执行者完成 | 补跑；无法派生 → 标 `[QA NOT INDEPENDENT: 同上下文替代]`；确实无法跑 → `[QA SKIPPED: 原因]`，不得静默跳过 |

## QA Agent（独立盲扫 + 对照）

**触发条件**（任一）：

| 条件 | 来源 |
|------|------|
| Risk Assessment = HIGH，或上游 confidence < 70 | [discovery.md](discovery.md) 的审查强度判定（**不含** graph 影响节点>5） |
| 本次变更为 one-way | schema / 数据迁移 / 公开 API 契约 / 权限与认证边界 / 并发与锁 |
| BLOCKER > 0 | 本审查结果 |
| 变更文件 > 10 | diff 统计 |

> 触发挂的是**已有的风险判定**，不另立一套风险分级。风险高但 diff 小的改动（例如 2 个文件的权限校验）
> 同样必跑——「主审查没报 BLOCKER」不是跳过独立审查的理由，恰恰是它要防的情况。
> 反向也成立：四个条件都不命中时不触发独立 QA，独立审查是成本项，不是仪式。
>
> ⚠️ **不要把 graph 的「影响节点>5」算进 QA 触发**：它是模块级粗粒度信号：2 行按钮换位
> 也能算出 7 个消费者节点并误触发 QA。graph 仍可用于决定**审查深度**，但不适合当成本闸门。
> 证据：eval ledger · `reviewer-risk-qa`（pressure test `project-reviewer#P5`）。

**执行者**：本 skill 的 [verifier](verifier.md)——`candidate-verify-accept` 使它在每轮审查中**已以
fresh context 运行**，两段式在同一轮内完成，**不额外 spawn 第三个 agent**。verifier 不可用时才 spawn 独立 agent。
> ⚠️ 「独立」必须可观测：用 `Agent` / `Task` 工具派生执行者。同一上下文里模拟盲扫不算 Independent QA；
> 无法派生时产出 `[QA NOT INDEPENDENT: 同上下文替代]`，不得声称已完成；Host 不保证一定派生。

**两段式（顺序不可颠倒）**：

1. **盲扫（Phase A）** — 输入只有 diff + `PLAN.md > # Acceptance Criteria` + `findConsumers` 结果，
   **不读 REVIEW.md 草稿**。问：「这个 diff 里是否存在 REVIEW.md 可能漏掉的 BLOCKER 级问题？」
2. **对照（Phase B）** — 再读 REVIEW.md 草稿：逐条判定依据是否成立、修复建议是否可操作，
   并把 Phase A 的新发现标为 `漏报 (Missed)`。

**输出**：`REVIEW.md` 增 `## Independent QA` 三节——`Missed`（盲扫新发现）/ `Confirmed`（原 finding 成立）/
`Rejected`（依据不成立）。只报告，不自动修改；`Missed` 中的 BLOCKER 计入 Exit 判定。

→ 通用方法、输入约束、成本：[qa-pattern](../../../workflow-protocol/references/qa-pattern.md)

## Output

REVIEW.md（含 validation notes + `## Independent QA`）

## Exit

无 CRITICAL 发现：BLOCKER 判定无误、分级合理、AC 无遗漏，**且 Independent QA 的 `Missed` 中无未处理 BLOCKER**
（有 → 标 BLOCKED/NEEDS_FIX，不得以「主审查没发现」为由放行）。
