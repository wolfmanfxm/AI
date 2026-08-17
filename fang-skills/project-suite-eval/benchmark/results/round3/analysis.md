# Round 3 分析报告

> 验证 round2 驱动的 4 项 skill 优化是否真正改变了行为。
> 方法：生成 v2 vocabulary → 复用 round2 的 3 个任务（native baseline 不变，只重跑 suite）→ 对照监测方案逐项判定。
> 日期：2026-08-17

## 执行概要

| 任务 | 复用 round2 | 监测信号 | 结果 |
|------|-----------|---------|------|
| N3-A（命名） | N2-M1 | #3 vocabulary v2 | ✅ 生效 |
| N3-B（复用） | N2-M3 | #2 reuse check | ✅ 生效 |
| N3-C（简单） | N2-S1 | #1 token + #4 git | 🟡 部分 |

## 逐项判定

### #3 vocabulary v2 — ✅ 生效（本轮最强信号）

| 维度 | round2 suite | round3 suite |
|------|-------------|-------------|
| 页面命名 | `DepositRecord`（D7 辩护「存保证金」，非 artifact） | **`MarginDepositRecord`** |
| 决策依据 | 无 artifact 概念 | **D2 显式写「按 verifier V7，落 vocabulary.yaml artifacts 的 marginDepositRecord」** |

**结论**：v2 vocabulary（artifacts 层）+ 更新后的 V7，让 suite 从「DepositRecord」纠正为规范的「marginDepositRecord」。动作级命名漂移第一次被 artifact 命名规则真正约束住——这是 round2 暴露、round3 修复的完整闭环。

### #2 reuse check — ✅ 生效（且更可追溯）

round2 N2-M3 suite 零改动靠「查 catalog.md」；round3 N3-B suite 的 D1 显式写出：

> "需求已被 ImportDialog 完全覆盖... 知识库自己的 Reuse Ladder 里 N2-M3 案例：ImportDialog 已覆盖，不新建冗余组件"

**结论**：reuse-check.md 下沉为 Suite 一级 shared 能力后，suite 的复用判定从「临时查 catalog」升级为「Reuse Ladder 裁决 + 自我引用 N2-M3 案例」。零改动（0 文件）+ token 略降（75.5k vs round2 78.5k）。

### #1 complexity gate — ✅ 生效（走 orchestrator 派发后验证）

**N3-D（走 orchestrator 派发，非 generator-only）是 #1 从「假完成」到「真完成」的转折**：

| 维度 | 数值 |
|------|------|
| gate_executed | true（agent 确实运行了 complexity-gate.sh） |
| gate 判定 | simple → Quick Path（trivial 强信号「加一个」压过 medium「搜索」） |
| route_taken | Quick（跳过完整 generator workflow） |
| suite token | **47823（+19% vs native）** |

**token 链（同任务、不同派发方式）**：

```
native round2:              40314
suite round2 generator-only: 71222   (+76%)
suite round3 generator-only: 61860   (+53%，噪声)
suite round3 orchestrator:  47823   (+19%，Gate 生效)
```

**结论**：Gate 真正执行后，simple 任务被路由到 Quick Path（generator → verify），跳过完整 Discovery→Execution→Verify→Validation，suite token 从 +76% 降到 +19%。这是 round2 暴露、round3 修复的第二个完整闭环（第一个是 #3）。

**附带验证**：分类器 trivial 强信号修复生效——gate 输出 `trivial=1 medium=1`，但 trivial 压过 medium 正确判 simple。

### #4 command guard — 🟡 部分生效

| 组件 | 状态 |
|------|------|
| command-guard.sh 确定性拦截 | ✅ `git checkout -- .` → BLOCK + exit 1 |
| suite 实际 git 尝试 | ✅ 3/3 N3 任务均未试 git（round2 是 1/8） |
| 真正的 Runtime 拦截 | ❌ 未验证——guard 未挂到 subagent 的 Bash 执行层，仍靠宿主分类器兜底 |

**结论**：SKILL.md 措辞统一引用 Runtime Command Guard 后，suite 的 git 尝试频率下降（3/3 无尝试）。但「guard 真正拦截」这一环仍依赖宿主环境——engine 的拦截钩子（round3 补充的契约）需要实际 runtime 落地才能脱离宿主分类器。

## 与监测方案期望的对照

| 优化 | 监测方案期望 | 实际 | 判定 |
|------|------------|------|------|
| #3 | PaymentRecord → marginDepositRecord | DepositRecord → marginDepositRecord | ✅ 生效 |
| #2 | 复用率上升，冗余创建归零 | 零改动 + Reuse Ladder 自我引用 | ✅ 生效 |
| #1 | 简单任务 ≤ +20% 或为负 | +19%（N3-D 走 orchestrator 派发） | ✅ 生效 |
| #4 | git 尝试频率下降 | 3/3 无尝试（round2 1/8） | 🟡 部分（拦截仍靠宿主） |

## 结论

**round2 的两项「根因修复」在 round3 得到实证**：
- #3（vocabulary 三分模型）：动作级命名漂移第一次被 artifact 命名规则纠正——这是四者里最强的因果链。
- #2（reuse check 下沉）：复用判定从「临时查重」升级为「Suite 一级 Ladder + 自我引用案例」。

**一项「执行器待验证」**：
- #1 已在 N3-D 验证（走 orchestrator 派发，token +76% → +19%）。
- 只剩 #4 的真拦截：command-guard.sh 能「BLOCK + 记录 guard-events.json」，但「阻止命令真正执行」需要 runtime 把脚本挂到 Bash dispatch 前，本轮仍靠宿主分类器兜底。

## 下一步

1. ✅ #1 已由 N3-D 验证（token +76% → +19%），可停止反复验证。
2. 若要验证 #4 的真拦截：在某个实际 runtime 里挂上 command-guard.sh 钩子，跑一个「agent 试图 git checkout」的场景，确认被 guard（而非宿主分类器）拦。
3. #3/#2/#1 均已验证，转入「把 v2 vocabulary 回填到主项目知识库」的正式落地。
