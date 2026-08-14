# Benchmark 续接指南

> 本文件是跨 session 的进度记录。新 session 从这里继续。

## 状态：✅ 已完成（2026-08-14）

20 个任务全部跑完（native + suite 严格隔离），综合分析见 [analysis.md](analysis.md)。

## 目标项目

- 路径：`/Users/fangxiangming/Work/Ly/东风汽金/code/afc-newcore-web-code`
- 技术栈：Vue 3.4 + Element Plus 2.13 + TypeScript 5.4
- git 分支：`benchmark/20260813`（本地，**不 push**）

## 任务进度（20/20 完成）

| 任务 | 状态 | 记录文件 |
|------|------|---------|
| S1-S5 | ✅ | S1.yaml ~ S5.yaml |
| M1 | ✅ | M1.yaml（native+suite 纯净重跑） |
| M2/M3/M4/M5/M6 | ✅ | M2~M6.yaml |
| C1-C5 | ✅ | C1~C5.yaml |
| L1-L4 | ✅ | L1~L4.yaml |
| Domain Model 验证 | ✅ | domain-model-validation.md |
| 综合分析 | ✅ | analysis.md |

## 核心约束（本 benchmark 已全程遵守，除 L2 native 一次事故）

1. 禁止 git commit / push ✅（L2 native 一次跨界 git 操作，已恢复，记录在 L2.yaml）
2. 每任务 native/suite 严格隔离 ✅
3. 结果记录在 project-suite 的 `benchmark/results/` ✅
4. 代码产物跑完即清 ✅（最终 code 项目工作树干净）

## 关键结论（详见 analysis.md）

1. **suite 的收益不在 token/复用率，而在**：Decision Record（可追溯）、边界纪律（反 gold-plate）、证据密度（量化）、长任务护栏（不跨界不碰 git）。
2. **suite token 开销平均 +12.8%**，远非"2x"；简单任务开销最高（+16%），目标模糊任务可能为负（M2/S2 suite 反而省 30%+）。
3. **domain drift 真实存在**：native 引入 personInfo（应为 customer），suite 的 Context Resolver 归属更准但未纠正术语（缺 vocabulary.yaml）。
4. **L2 native 事故**是"长任务护栏"的强证据：native 跨界软链 node_modules + 触碰 git，suite 严守沙箱。

## 遗留（全部已闭环 ✅）

1. ✅ `vocabulary.yaml` → 重跑 M1 验证 drift 纠正（见 domain-drift-verification.md）。
2. ✅ requirement_coverage 口径统一（metrics.md 新增「Requirement Coverage Rubric」）。
3. ✅ 歧义任务补 `target_hint`（tasks.yaml v1.1）。注：已有 20 结果是无 target_hint 下跑的，落点发散本身是发现，target_hint 供未来重跑。
