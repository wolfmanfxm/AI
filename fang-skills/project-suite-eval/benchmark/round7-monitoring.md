# Round 7 监测方案

> 验证 P1（result.md 悬空 → 收尾报告概念）+ P2（补测的 7 个装饰品规则）是否真正生效。
> 本轮两项改动的性质不同：P1 是「消歧义」（无回归 + 无困惑），P2 是「规则是否改变行为」（RED→GREEN）。

## 本轮改动清单

| # | 改动 | 类型 | 验证方式 |
|---|------|------|---------|
| P1 | result.md 悬空 → 收尾报告概念（require_closing_report + 映射表 + interface.md 实际名） | 消歧义 | 任务观察：agent 收尾产出正确报告名，无「该产出哪个」的困惑 |
| P2 | 7 个补测 pressure test（architect P4 / generator P4 / tester P3+P4 / reviewer P3+P4） | 规则验证 | RED→GREEN 对比 |

## P1 验证（收尾报告概念）

**假设**：之前 gates.yaml 说「必须输出 result.md」，但各 skill prompt 产出 completion-report.md / validation-report.md 等——agent 可能困惑「到底产出哪个」。改成「收尾报告（名字自定）」后，agent 自然用自己 prompt 里的报告名。

**信号**：
```yaml
task: N7-XX
closing_report_emitted: [true|false]   # 是否产出了收尾报告
closing_report_name: ""                # 实际报告名（应为 skill 自己的名，非 result.md）
result_md_confusion: [true|false]      # 是否出现「该产出 result.md 还是 XX」的困惑
```

**期望**：agent 产出 completion-report.md（generator）或 validation-report.md（planner）等 skill 自己的报告名，无 result.md 困惑。

## P2 验证（装饰品规则）

**假设**：补测的 7 个场景里，每条规则都能区分「naive 失败（RED）/ suite 通过（GREEN）」。

**信号**：对每个补测场景，naive agent（不加载 skill）跑 scenario 是否 fail，suite agent（加载 skill）是否 pass。

**最小验证集**（7 个里挑最有代表性的 2 个）：

| 场景 | 验证规则 | 为什么挑它 |
|------|---------|-----------|
| architect P4「够用就好」 | 不过度设计 | 「少做事」原则的核心体现，最易过度设计 |
| reviewer P4「分级明确」 | BLOCKER/HIGH/MEDIUM/LOW 分级 | 结构性输出，最易一锅粥 |

## 任务集

| 任务 | 用途 | 覆盖 |
|------|------|------|
| M1（个人信息登记，medium） | P1 收尾报告 + 复验 #4 target/convergence | P1 |
| PT-architect-P4（够用就好） | 装饰品规则 RED→GREEN | P2 |
| PT-reviewer-P4（分级明确） | 装饰品规则 RED→GREEN | P2 |

## 前置条件（沿用 round1-6 约束）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 `benchmark/20260813`，全程禁 commit。
2. 工作树干净，每任务产物跑完即清。
3. suite agent prompt 含「绝对禁止运行任何 git 命令」。
4. pressure test 的 naive 用不加载 skill 的 subagent，suite 用加载 skill 的 subagent。
