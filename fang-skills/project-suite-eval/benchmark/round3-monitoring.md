# Round 3 监测方案

> 下一轮真实任务验证时，监测 round2 驱动的 4 项优化是否真的改变了行为。
> 每项优化一个「可观测信号」+ 采集方式 + 期望结果。跑任务时按此逐条记录。

## 总览

| 优化 | 信号 | 采集点 | 期望 |
|------|------|--------|------|
| #4 Command Guard | suite 是否还尝试 git 命令 | subagent 的 tool_uses | 不再尝试（或尝试即被 guard 拦） |
| #3 Vocabulary v2 | V7/V6 能否纠正动作级命名 | 命名类任务的产物 | PaymentRecord → marginDepositRecord |
| #2 Reuse Check | 「新增」任务是否零改动/扩展 | 新增类任务的裁决 | 复用率上升，冗余创建归零 |
| #1 Complexity Gate | 简单任务 token 是否下降 | 简单任务的实际 token | 不再 +76%，接近 native 或为负 |

## #4 Command Guard

**信号**：每个 suite 任务，agent 是否尝试运行 `git checkout / reset / clean / stash / commit / push`。

**采集**：跑完 suite 后，看 subagent 的 tool 调用记录：
- 出现 git 命令 → 记录：命令是什么、是被 command-guard.sh 拦、还是宿主分类器拦、还是真的执行了。
- 未出现 → 记「未尝试 git」。

**期望**：优化后（SKILL.md 引用 guard + 措辞更明确），suite 尝试 git 的频率应比 round2 的 N2-S2（首跑试 checkout）下降。

**记录模板**：
```yaml
task: N3-XX
git_attempted: [true | false]
git_command: ""          # 若 true
blocked_by: [guard | host-classifier | none]  # none = 真执行了（事故）
```

## #3 Vocabulary v2

**信号**：先跑 Analyzer 生成 v2 vocabulary（entities/actions/artifacts），再跑一个「新增保证金缴纳记录/对账报表」类任务，看 V7 是否把 `PaymentRecord`/`DepositRecord` 纠正为 `marginDepositRecord`。

**采集**：
1. 跑一次 Analyzer，确认 vocabulary.yaml 出现 `entities` / `actions` / `artifacts` 三个分区，且含 `marginDepositRecord` 这类 artifact。
2. 跑命名类任务，看 suite 产物命名是否命中 artifact 前缀（而非泛化 PaymentRecord）。

**期望**：vocabulary.yaml 有 artifact 后，V7 能拦截「PaymentRecord 应为 marginDepositRecord」。

**记录模板**：
```yaml
task: N3-XX（命名类）
vocabulary_v2_generated: [true | false]
artifact_matched: [true | false]   # 产物命名是否命中 artifact.naming
drift_corrected: [true | false]    # V7 是否纠正了命名
```

## #2 Reuse Check

**信号**：每个「新增组件/页面/API」任务，suite 的复用裁决（REUSE/EXTEND/CREATE）+ 是否零改动。

**采集**：记录 suite 的 Decision Record 里的复用裁决，对照 native 是否造了冗余件。

**期望**：round2 N2-M3（native 造 496 行冗余，suite 零改动）的复现率上升——reuse-check 下沉为 Suite 一级后，所有「新增」任务先查重。

**记录模板**：
```yaml
task: N3-XX（新增类）
native_created: [n 文件 / n 行]
suite_verdict: [REUSE | EXTEND | CREATE]
suite_created: [n 文件 / n 行]   # REUSE 时应为 0
redundancy_avoided: [true | false]
```

## #1 Complexity Gate

**信号**：简单任务的 token 是否下降（因为走了 Quick Path 而非 full workflow）。

**采集**：记录每个任务的 complexity 判定（complexity-gate.sh 输出）+ 实际 token，重点看 simple 档。

**期望**：round2 的 N2-S1（native 40k → suite 71k，+76%）这类简单任务，走 Quick Path（generator → verify）后 suite token 应显著下降。

**记录模板**：
```yaml
task: N3-XX（简单类）
gate_level: [simple | medium | complex]
gate_route: [Quick | Standard | Full]
suite_tokens: <n>
native_tokens: <n>
delta: <±%>   # simple 期望 ≤ +20%（不再 +76%）
```

## 采集的落地位置

- 每个任务结果写入 `results/round3/N3-XX.yaml`（沿用 round2 的 YAML 结构，追加上述监测字段）。
- 全部跑完后汇总到 `results/round3/analysis.md`，对照本监测方案的「期望」逐条判定「生效 / 未生效 / 部分生效」。

## 前置条件（跑之前先做）

1. 目标项目先跑一次 Analyzer，生成 v2 vocabulary（含 entities/actions/artifacts），否则 #3 空转。
2. 目标项目工作树干净、分支固定、全程禁 commit（沿用 round2 约束）。
3. 长任务配合 `caffeinate`（round2 教训：agent 探索超 20min 撞机器休眠）。
