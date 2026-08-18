# Convergence — Suite Primitive v1.0.0

> Suite 一级「停止条件」原语。每个 Skill 产出时回答同一个问题：**证据是否足够，足以让我停下来（不再做更多）？** 不做大型 convergence-engine，只统一一个结果字段，所有 Skill 都可返回。

## 定位：统一停止条件

```
Analyzer   → sufficient → 不再分析
Planner    → sufficient → 不再追问
Architect  → sufficient → 不再造第二方案
Generator  → sufficient → 不再生成
Reviewer   → sufficient → ACCEPT
```

收敛不是「做更多」，是「做够就停」。这是 project-suite 的「少做事」原则在结果层的统一表达（见 docs/roadmap.md「Convergence」）。

## 统一结果字段

每个 Skill 在**收尾 stage（delivery 或 validation）** 产出收敛判定（经 stage 模板注入，见 [stage-templates](../../workflow-engine/references/stage-templates/)），写入收尾报告（`completion-report.md` / `validation-report.md` 等，名字由 skill 自定）：

```yaml
convergence:
  status: sufficient | insufficient | blocked
  evidence: [<支撑判断的证据，至少 1 条>]
  next_action: stop | execute | investigate
```

### status 语义

| status | 含义 | 触发下游 |
|--------|------|---------|
| **sufficient** | 证据足够，产出可信，无需继续本 Skill 的工作 | 下游正常执行 |
| **insufficient** | 证据不足，但知道缺什么 | 补充证据（追问/再分析/再生成一轮） |
| **blocked** | 缺关键输入，无法继续，硬阻断 | 回到上游补输入，不猜 |

### next_action 语义

| next_action | 含义 |
|-------------|------|
| **stop** | 本 Skill 到此为止，交下游（或交付） |
| **execute** | 还有可执行的一步（本 Skill 内再推进） |
| **investigate** | 需要查明一个未知点（追问/查证），而非继续盲做 |

## Pipeline 行为规则（让收敛改变执行，而非只做报告）

> 不做 Engine，只加三条声明规则。Runtime 是 Protocol，靠 agent 遵守（见 roadmap「Designed/Enforced」）：

| 收敛结果 | Pipeline 行为 |
|---------|--------------|
| `sufficient` + `stop` | 当前 Skill 完成，**不再重复当前 Skill**（即使下游发现小问题，也由下游修，不回本 Skill 重跑） |
| `blocked` | **不允许自动进入下游**——缺关键输入时，下游启动需先补齐 blocker，不猜 |
| `insufficient` | 只补缺失证据（一轮），补完即走；不因「还可以更好」无限循环 |

**规则**：Convergence 决定「够不够继续」，Confidence Gate 决定「够不够交付」。两者分开记，不混用（见下「与 Confidence 的关系」）。

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
| 造第二个/第三个方案再比较（无谓消耗） | 第一方案 sufficient → stop |
| convergence 与 confidence 混用 | 分开记：confidence 评可靠度，convergence 评是否停 |
| blocked 时猜一个输入继续做 | blocked + 回到上游补输入 |
