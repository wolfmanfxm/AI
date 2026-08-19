# Convergence — Suite Primitive v1.0.0

> Suite 一级「停止条件」原语。每个 Skill 产出时回答同一个问题：**证据是否足够，足以让我停下来（不再做更多）？** 不做大型 convergence 引擎，只统一一个结果字段，所有 Skill 都可返回。

## 定位：Decision Protocol（不是 Execution Control）

Convergence 是**决策协议**——它让所有 Skill 用同一种语言表达「我已经做够了」，供 Host 解读。

```
Skill
  ↓ 判断 evidence
convergence = { status, evidence, next_action }
  ↓ Host interprets
通常停止当前 Skill（Suite 不保证 Host 一定停止）
```

**Suite 只保证一件事**：所有 Skill 用统一的语言表达收敛状态。**Suite 不保证 Host 一定执行 handoff**——是否交接下游，是 Host 的能力（见 [host-capability.md](../../runtime/contracts/host-capability.md)）。

```
Analyzer   → sufficient → 不再分析
Planner    → sufficient → 不再追问
Architect  → sufficient → 不再造第二方案
Generator  → sufficient → 不再生成
Reviewer   → sufficient → ACCEPT
```

收敛不是「做更多」，是「做够就停」。这是 project-suite 的「少做事」原则在结果层的统一表达。

## 统一结果字段

每个 Skill 在**收尾 stage（delivery 或 validation）** 产出收敛判定（经 stage 模板注入，见 [stage-templates](../../workflow-protocol/references/stage-templates/)），写入收尾报告（`completion-report.md` / `validation-report.md` 等，名字由 skill 自定）：

```yaml
convergence:
  status: sufficient | insufficient | blocked
  evidence: [<支撑判断的证据，至少 1 条，须绑定 Exit Criteria>]
  next_action: handoff | continue | investigate | blocked
```

### status 语义

| status | 含义 | 触发下游 |
|--------|------|---------|
| **sufficient** | 证据足够，产出可信，无需继续本 Skill 的工作 | 下游正常执行 |
| **insufficient** | 证据不足，但知道缺什么 | 补充证据（追问/再分析/再生成一轮） |
| **blocked** | 缺关键输入，无法继续，硬阻断 | 回到上游补输入，不猜 |

### next_action 语义（明确「停什么」）

| next_action | 含义 |
|-------------|------|
| **handoff** | 当前 Skill 已完成，可以交给下游（交接，不是「停止一切」） |
| **continue** | 当前 Skill 还有可执行的一步（本 Skill 内再推进） |
| **investigate** | 需要查明一个未知点（追问/查证），而非继续盲做 |
| **blocked** | 缺关键输入，回上游补，不猜 |

> `handoff` 语义天然明确：当前 Skill 完成 → 交下游。比旧的 `stop` 稳——`stop` 有「停 skill / stage / pipeline」的歧义，`handoff` 只表达「当前 Skill 的活儿干完了」。

## 可信度约束：Exit Criteria → Evidence → Convergence

> `sufficient` 不能是 agent 主观判断，必须绑定 Exit Criteria（见 skill 的 verifier/validation 检查项）。

```
Exit Criteria（skill 的 verifier 检查项）
     ↓ 逐项核对
Evidence（每条 criteria 的通过证据）
     ↓ 汇总
Convergence（status 由 evidence 决定，非主观）
```

**规则**：`sufficient` 的每一条 evidence 必须对应一个已通过的 Exit Criteria。不允许单独写一句 `sufficient` 而无 evidence 支撑。反例见下方「反例」表。

## 波次验证：每个执行波次必须有 Outcome + Verification

> 借鉴 GSD「任务切片必须可验证」：不允许只以「任务完成」作为完成条件。每个执行波次（wave）必须有独立的 Outcome + Verification。

| 波次元素 | 要求 | 缺失时的行为 |
|---------|------|-------------|
| **Outcome** | 波次的产出是什么（可观察的产物，如「PLAN.md 9 模块齐」「3 个测试用例通过」） | 无 Outcome → 不算完成 |
| **Verification** | 如何验证 Outcome 达成（可执行的检查，如 grep / 测试 / 文件存在性） | 无 Verification → 收敛判定退回 insufficient |

**规则**：
- 每个波次结束，收敛判定必须引用**该波次**的 Outcome + Verification 结果，而非笼统的「任务完成了」。
- `sufficient` 的 evidence 中，至少一条指向「本波次 Outcome 的验证结果」。
- 只有「做完」没有「验证过」→ 标 `insufficient → continue`，补验证而非假装完成。

这与 systematic-debugging 的「Reproduce→Regression」互补：convergence 管「波次是否验证完成」，debugging 管「波次内的问题如何定位」。

## Done 的定义（Evidence over Claims）

> 「没有证据不得进入 Done」。不是 agent 说「done」就算 done，而是满足三段：

```
Done = Outcome satisfied
     + Evidence exists
     + No blocking contradiction
```

| 条件 | 含义 | 缺失时的行为 |
|------|------|-------------|
| **Outcome satisfied** | 波次的产出目标达成（见上「波次验证」） | 不算完成 |
| **Evidence exists** | 每个 Outcome 有可验证的证据（grep / 测试 / 文件存在性） | 不算完成 |
| **No blocking contradiction** | 无 BLOCKER 级矛盾（如自相矛盾、依赖断裂） | 标 blocked，不进入 Done |

**规则**：`next_action: handoff` 只允许在 Done 三段都满足时出现。任何一段不满足，收敛判定退回 `insufficient → continue` 或 `blocked`，不假装 Done。

## 与 Confidence 的关系

Confidence 是「产出可靠度」（0-100），Convergence 是「是否该停」（三态）。两者正交，分工明确：

- **Convergence 决定「够不够继续」**，**Confidence Gate 决定「够不够交付」**——分开记，不混用。

按 Skill 类型区分「低 confidence 能否 sufficient」：

| Skill 类型 | 低 confidence + sufficient 的后果 | 规则 |
|-----------|--------------------------------|------|
| Knowledge / Planning（analyzer / planner / architect） | 产出是「建议」，下游可裁决 | 可 sufficient，但标注假设 |
| Code / Test / Release（generator / tester / reviewer / releaser / refactorer / documenter） | 产出是「交付物」，错了影响下游或生产 | confidence 低于 gate 阈值 → **不能 sufficient**，必须 execute 补到阈值 |

统一表述：

- confidence 高 + convergence sufficient → 直接交付
- confidence 低 + convergence sufficient → 仅 Knowledge/Planning 类可（标注假设）；Code/Test/Release 类改为 insufficient → execute
- convergence insufficient / blocked → 无论 confidence 多高，都不该假装完成

## 各 Skill 的收敛判据

| Skill | sufficient 判据 | insufficient / blocked 判据 |
|-------|----------------|---------------------------|
| analyzer | 知识缺口已闭合 / 命中 Reuse Fast Path | 关键模块未扫描 → investigate |
| planner | 9 模块齐 + AC 可验证 | 需求信息缺失 → insufficient（追问） |
| architect | 所有 Decision 已 resolve，无第二方案必要 | 技术选型证据冲突 → investigate |
| generator | 代码通过 verifier 检查 | verifier 失败 → execute（修复一轮） |
| reviewer | 无 BLOCKER 级发现 → ACCEPT | 有 BLOCKER → execute（返回修复） |
| tester | AC 覆盖率 100% 且通过 | 覆盖不足 → execute（补测试） |
| refactorer | 测试通过 + 行为不变 | 测试失败 → blocked（先加表征测试） |
| documenter | 文档溯源完整 | 源码无法定位 → investigate |
| releaser | 全链路 gate 通过 | 上游 blocker → blocked |

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 证据不足仍标 sufficient「差不多够了」 | insufficient + 明确缺什么 |
| 造第二个/第三个方案再比较（无谓消耗） | 第一方案 sufficient → handoff |
| convergence 与 confidence 混用 | 分开记：confidence 评可靠度，convergence 评是否停 |
| blocked 时猜一个输入继续做 | blocked + 回到上游补输入 |
