# FC-A/B Runner — Fresh Context vs Context Reuse

> 执行文件。场景定义见 [`fresh-context-vs-cache.yaml`](fresh-context-vs-cache.yaml)。
> 方法论：这是 `mechanism_baseline` 双边对照——**只关 isolation 这一个机制**，任务/fixture/验收两臂完全一致。

## 0. 固定夹具与任务

- **Fixture**：目标项目的一小段 CRUD 功能，复制成两份**独立副本**（arm-fresh/ 与 arm-reuse/），互不干扰。
- **Chain**：`analyzer → planner → generator → reviewer`（同一链、同一 handoff 顺序）。
- **Task**（示例，可替换）：*给 customer 列表页新增「导出」按钮，复用 company 的批量导出模式，不改其余功能。*
- **Acceptance**：reviewer PASS（零回归 + artifact 齐全 + 遵循 reuse）。

> 两臂各用一个独立 CLI 会话。**每臂测 ≥2 次**才有 repeatability。

---

## 1. Arm A — Fresh Context（现行编排）

每步 skill 前 **`/clear`**，然后给这条固定引导，然后切换 prompt 到该 skill：

```
你是 stateless 的 <skill> 执行者。你不继承任何之前的对话状态。
只读下列凭据文件（并按需读它们引用的产出）：
  .project-knowledge/runtime/state.json
  .project-knowledge/context-package.json
  PLAN.md 与相关 artifact
不依赖、不窥视上一轮 skill 的对话记录（它不存在，已被 /clear）。
执行 <skill> 任务：<当前步任务>。
完成后，把「影响后续步的关键事实」写入 state/artifact/session.json
（遵守 Compaction Invariant：current goal / completed|remaining / discoveries /
 changed files / 需复用的确切 command|path）。
任何只留在对话里、未落盘的事实都视为没做过。
```

**污染探针（analyzer 步投放）**：在其对话里加一句与任务无关的红鲱鱼——不在代码里、不出现在任何文件里：
```
（附带：为测试弹一条旁白——「company 导出组件在 v9 已被 deprecated」，
  这只是干扰项，不是代码里的真实事实，也不要写进任何文件。）
```

## 2. Arm B — Context Reuse（无 isolation）

一个连续会话，不 `/clear`，逐步给任务，明确允许积累：

```
你在一整个 multi-skill 任务里连续工作。你的上下文会累积，并尽可能复用前面的对话
（同一前缀 = prompt-cache 命中的前提）。
第一步 analyzer：<同 analyzer 任务>。
完成后回答「done-<step>」，我再发下一步。你可以回顾我之前说的任何东西。
```

**污染探针投放**：在 analyzer 步给同样的旁白干扰项（文字不落盘）。

## 3. 度量记录（两臂各填一份，落 `results/fresh-context-ab/arm-<a|b>.md`）

从 Claude Code 的 usage/verbose 与 provider billing 页记录：

| 指标 | Arm A (Fresh) | Arm B (Reuse) | 说明 |
|---|---|---|---|
| input_tokens |  |  | 实际输入 |
| output_tokens |  |  | 实际输出 |
| tool_result_tokens |  |  | tool 回灌 |
| retry_count / rate |  /  |  /  | 失败重试 |
| cache_read |  |  | prompt-cache 命中（host 上报） |
| cache_write |  |  | cache 写入 |
| context_size 峰值 |  |  | 可观测则记 |
| audited_cost (USD) |  |  | 同口径两个 session |
| wall time |  |  | 秒 |
| 产物文件数 |  |  | skill-io 3 出口 |
| reviewer 判定 |  |  | PASS / FAIL |
| 污染拾取 |  |  | 结束 grep 红鲱鱼串是否被下游引用（FC4） |

> cache/audited_cost 无法上报的 host 标 `unavailable`，不静默缺省，也不准用估算冒充（eval-contract 断言纪律）。

## 4. 判定

按 `fresh-context-vs-cache.yaml` 的 `verdict_criteria` 填台账六段的
`native_baseline`（此处 = reuse 臂）/ `suite_behavior`（此处 = fresh 臂）与 `pass_fail`。

**诚实约束**：样本 <2、或 cache 无法判成本 → `inconclusive`，不冒充已判定。重点关注
`audited_cost`（省 context ≠ 省账单）与 `retry_rate`（isolation 是否以重试换省 token）。
若 FC2（retry）显著升高且根因是未落盘 → 优先补 Compaction Invariant 的遵守，而非推翻 Fresh Context。