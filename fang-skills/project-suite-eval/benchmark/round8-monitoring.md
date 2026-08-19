# Round 8 监测方案

> 验证「Protocol 非 Engine」定位修正（round8 改动）是否真生效 + 是否引入回归。
> 本轮改动性质：命名/语义清理（handoff、auto-promote→confirm、orchestrator 去 auto-advance、目录改名）。
> 重点：这些是「改声明」，要验证「agent 行为是否真的跟着变了」，而非只改了 yaml。

## 本轮改动清单

| # | 改动 | 类型 | 验证点 |
|---|------|------|--------|
| 1 | next_action: stop → handoff | 语义 | agent 收尾产出 `handoff` 而非旧 `stop` |
| 2 | auto-promote → human confirmation | 行为 | agent 不再自动晋升 personal，等人工确认 |
| 3 | orchestrator 去 auto-advance | 行为 | orchestrator 建议而非「自动执行」 |
| 4 | workflow-engine→workflow-protocol、runtime/engine→runtime/mechanisms | 命名 | agent 能否找到改名后的路径（无「找不到 workflow-engine」报错） |

## 最小验证集

| 任务 | 用途 | 关键信号 |
|------|------|---------|
| M1（个人信息登记，medium） | 综合回归 + #1 handoff | 收尾报告 next_action 是 handoff 还是 stop；落点仍正确 |
| 新「补充分析某模块」 | #2 auto-promote 回归 | 分析后是否产出 Promote 建议但不自动晋升 |

## #1 handoff 语义验证

**假设**：convergence.md / stage 模板改成 `handoff/continue/investigate/blocked` 后，agent 收尾时产出 `handoff`（交下游），而非旧 `stop`（语义有「停一切」歧义）。

**信号**：
```yaml
task: N8-XX
convergence_next_action: ""   # 应为 handoff，不是 stop
used_old_stop: [true|false]   # 是否还写 stop
```

**期望**：`next_action: handoff`，无 stop 残留。

## #2 auto-promote 回归验证

**假设**：background.yaml 加了 promotion_confirm（human-confirmation）+ checkpoint 后，agent 不再自动把 personal candidate 晋升到 Vault，而是产「建议」等人工确认。

**信号**：
```yaml
task: N8-XX（分析类）
auto_promoted: [true|false]       # 是否自动晋升了
produced_recommendation: [true|false]  # 是否产出 Promote/Keep/Reject 建议
waited_confirmation: [true|false] # 是否等人工确认
```

**期望**：produced_recommendation=true，auto_promoted=false（只建议不自动晋升）。

## 前置条件（沿用 round1-7 约束）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 `benchmark/20260813`，全程禁 commit。
2. 工作树干净，每任务产物跑完即清。
3. suite agent prompt 含「绝对禁止运行任何 git 命令」。
4. suite agent prompt 必须显式给目标项目路径（round7 教训：否则 agent 误写主项目）。
