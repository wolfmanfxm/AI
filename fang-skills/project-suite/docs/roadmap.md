# Roadmap

> project-suite 演进路线图。当前 Suite v1.1 Spec / Release v1.0。project-suite 是 Protocol 非 Engine（Suite 定义协议，Host 负责执行/强制，见下状态模型）。

## 定位

> project-suite 是 **Agent SDLC Framework**，不是 Skills 集合（区别于 Superpowers 的 composable / Matt Pocock 的小 Skill 路线）。复杂度在 Framework 层（runtime/mechanisms + registry + gates + profiles + shared/primitives），Skill 保持薄（~50 行）。**新增能力 → Framework 层，不散落进 SKILL.md。**

## 复杂度按需启用（反自动化原则）

> **不要为了自动化而自动化。复杂任务才启用复杂机制。** 这是 project-suite 区别于「把 mandatory workflow / 固定 phase / grill / hooks / memory 全堆进去」的关键差异点。

```
Simple    → Skill（直接做，无额外流程税）
Medium    → Skill + Verify
Risky     → Challenge / Interview（决策风险高才追问）
Complex   → Plan + Checkpoint + Verify
Persistent knowledge → Promotion（值得跨项目才晋升）
```

**原则**：机制是「按需启用」的阶梯，不是「全部强制」的流水线。简单任务背全流程 = 流程税，这正是 round3/4 暴露、complexity-gate 要解决的。每个机制都有「何时触发」的入口（complexity-gate 的 Quick/Standard/Full、interview 的 confidence 分级、architect 的决策风险分级），而不是无差别执行。

## 状态模型（避免「假完成」）

> `[x]` 只表示「协议/实现完成」，不代表「在真实环境被 Host 强制执行」。project-suite 是 Protocol，不是 Engine——Protocol 自己没有 Enforced 能力，强制能力是 Host 的（见 [host-capability.md](../runtime/contracts/host-capability.md)）。四态标注：

| 状态 | 含义 | 当前实例 |
|------|------|---------|
| **Specified** | Protocol 已定义（有规范/契约文档） | Runtime（Protocol 非 Engine）、Convergence |
| **Implemented** | 有 reference implementation / adapter / script | Complexity Gate、Command Guard（有脚本，无真 hook） |
| **Host-Supported** | 某个 Host 能正确解释/执行（如 Claude Code Hook） | Command Guard（Claude Code PreToolUse Hook） |
| **Validated** | Benchmark 验证行为符合预期 | depth_profiles 深度、知识缺口（round4 实测） |

> 关键：**没有「Enforced」这个状态**——Suite 不假装有强制能力。强制是 Host 的 `host_capabilities`（advisory/enforced），不是 Suite 的状态。

## 版本

> **Suite v1.1 Spec / Release v1.0**。版本号只此一处，其余不重复声明。

| 版本 | 日期 | 说明 |
|------|------|------|
| **Spec v1.1** | 2026-08 | 当前规范版本（SUITE_SPEC.md）。新增 Stage Template Injection、interface 统一、Governed-ready |
| **Release v1.0** | 2026-08 | 当前发布版本（suite-manifest.yaml）。Knowledge Consumption 闭环 + Protocol 定位修正（Protocol 非 Engine） |

### 历史版本（归档）

| 版本 | 日期 | 关键变化 |
|------|------|---------|
| v0.9.0 | 2026-08 | Analyzer v3.0 (8-Phase), Candidate/Verify 9/9, Knowledge Promotion, Workflow DSL, Pipeline Orchestrator, Event Bus, Memory Layer, Governed-ready |
| v0.8.0 | 2026-08 | Stage Contract + Validation + QA Sub-Agent, Interface 统一 |
| v0.7.0 | 2026-07 | 9-module PLAN Contract, Dispatcher Pattern, Knowledge Lifecycle v2.0, capabilities.yaml |
| v0.5-0.6 | 2026-06/07 | 职责边界, Capability Registry, DAG Scheduler, Context Protocol |

## 当前优先级（未完成项）

> 从「功能清单」转「问题驱动」。方向性修正：**project-suite 是 Protocol，不是 Engine**——不做 Runtime Engine、Convergence Engine、Scheduler Engine、强制 Stop。目标从「执行完整性」改为「协议完整性」：把 Protocol 边界定义严谨，不假装有强制能力（见 [host-capability.md](../runtime/contracts/host-capability.md)）。

### P0 — Protocol Integrity（协议完整性）

- [ ] Benchmark 验证 Protocol 行为（pressure test 的 RED 假设：额外动作型 vs 判断型）

> 已完成：Protocol Contract 一致性（check-consistency.sh）、Host Capability Contract、Exit Criteria→Evidence→Convergence。

### P2 — Knowledge Consumption

- [ ] Context Resolver 跨项目
- [ ] Knowledge Decay
- [ ] Knowledge Score

### P3 — Knowledge Automation

- [ ] Instinct Registry

> 已完成：Complexity Gate 三路径、depth_profiles 统一、知识缺口入口、prompt 瘦身、Convergence 统一协议（Decision Protocol）。
