# Round 6 监测方案

> 验证本轮 session 的架构改动真实效果。重点：#2 双阈值消除 + #4 target 放置决议。
> 与 round5 不同：本轮多数是「消除多头权威」的架构清理，行为层变化小、重在回归；#4 是唯一的行为优化，需真跑任务验证。

## 本轮改动清单

| # | 改动 | 类型 | 验证方式 |
|---|------|------|---------|
| #1 | knowledge-list → context-package（上一轮已收口） | 架构 | 静态：grep 无正常路径残留（已完成） |
| #2 | 双阈值消除：删 confidence_min + quality_gate，gate 唯一权威 rules.yaml | 架构清理 | 静态已验 + 回归（gate 路由仍正常） |
| #3 | convergence 统一协议（new primitive） | 新协议 | 静态：接入 skill-io.md result.md（已完成） |
| #4 | planner target 放置决议 | **行为** | 真跑 M1：落点 customerManage 而非 baseData |
| #5 | skill-ir 生成器修复（2 bug） | 修复 | 静态：10 skill-ir 已同步（已完成） |
| #6 | 技术栈污染清理（3 处） | 清理 | 静态：grep 无残留（已完成） |

## 最小验证集（suite-only，不需 native 双跑）

| 任务 | 用途 | 覆盖改动 | 关键信号 |
|------|------|---------|---------|
| **M1（个人信息登记）** | #4 target 放置决议 | #4（核心）+ #2 回归 | planner 显式产出 target 决议，落点 customerManage/customerIndividual 而非 baseData/personalInfo |
| **S1（按钮改色）** | #2 双阈值回归 | #2 | gate 路由 Quick Path 仍正常，无 confidence_min 报错 |

## #4 target 放置决议（核心验证）

**假设**：planner 加了「放置决议（target）」字段（module/domain/placement/confidence/evidence）后，规划「个人信息登记」时会显式对齐 domain model（vocabulary.yaml 的 `customerIndividual` + `person→correct_to: customerIndividual`），把落点定到 `customerManage/customerIndividual`，而不是 round5 的错误落点 `baseData/personalInfo`。

**背景**：round5 M1 暴露 suite 错放 baseData/personalInfo。本轮 vocabulary.yaml 已含 `customerIndividualRegister` artifact（naming: customerIndividualRegister），且 `customerManage/customerIndividual/` 目录已存在。这是验证 target 决议「对齐 domain model」的完美场景。

**信号**：
```yaml
task: N6-M1
target_emitted: [true | false]        # planner 是否显式产出 target 放置决议
target_module: ""                     # 决议的 module
target_domain: ""                     # 决议的 domain（应 = customerIndividual）
final_location: ""                    # generator 实际落点
location_correct: [true | false]      # 是否 customerManage 而非 baseData
domain_aligned: [true | false]        # 是否对齐 vocabulary.yaml
```

**期望**：target_module=customerManage，target_domain=customerIndividual，location_correct=true（对比 round5 的 baseData/personalInfo 错误）。

## #2 双阈值消除（回归验证）

**假设**：删 skill.yaml confidence_min + skill-policy.yaml quality_gate 后，gate 判定逻辑无回归——因为 gate 唯一权威 rules.yaml 的 `gate`，而 confidence_min 本来就不被 agent 运行时直接消费（是 machine-readable routing 元数据）。

**信号**：S1 跑 suite，看 Complexity Gate 是否仍正确路由（trivial/simple → Quick Path），且无「找不到 confidence_min」类报错。

**期望**：gate_route=Quick Path，ran_cleanly=true。若报错或路由异常，说明删字段影响了 gate 判定。

## 前置条件（沿用 round1-5 约束）

1. 目标项目 `/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`，分支 `benchmark/20260813` 固定，全程禁 commit（`git -C <绝对路径>`）。
2. 工作树干净（已确认 status --short 为空）。
3. command-guard-hook 只在 benchmark 上下文挂，不全局。
4. 每任务产物跑完即清（`git -C <绝对路径> clean -fd` + 撤销 tracked 改动）。
5. suite agent prompt 含「绝对禁止运行任何 git 命令」。
