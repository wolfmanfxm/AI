# Pressure Testing — Skill 的 TDD 验证机制

> 核心问题：**如何证明一条 Skill 规则真的改变了 Agent 行为，而不是装饰品？**

答案借鉴 Superpowers 的做法：把 Skill 开发当 TDD。判定标准只有一条——

> **如果没观察到 Agent 在「没有 Skill」时失败，就不知道这条规则是否真的有必要。**

## RED → GREEN → Refactor

| 阶段 | 动作 | 产物 |
|------|------|------|
| **RED** | 写一个「反例场景」——朴素 Agent（不加载该 Skill）会做错的真实任务 | 一个 scenario + naive_failure |
| **GREEN** | 写/改 Skill 规则，让加载 Skill 的 Agent 在该场景下做对 | 一条机制（mechanism）+ assertion |
| **Refactor** | 观察 Agent 仍漏掉什么，补规则，回到 RED | 新增/修正规则 |

## 一个 pressure test 的结构

每个反例场景回答四个问题（存于 `project-suite-eval/benchmark/pressure-tests/<skill>.yaml`，**不在 skill 目录内**——测试验证数据与 skill 本身能力无关，遵循「评估证据与治理契约分离」原则，见 benchmarks.md）：

| 字段 | 含义 |
|------|------|
| `scenario` | 具体任务 prompt（喂给 Agent） |
| `naive_failure` | 朴素 Agent 会怎么错（RED 的证据） |
| `skill_mechanism` | 哪条规则阻止了这个错误（GREEN 的机制） |
| `assertion` | 怎么判定 pass / fail |

## 运行方式（三阶段对比）

1. **Baseline**：不加载 Skill，跑 `scenario` → 记录 `naive_failure` 是否发生。
2. **Suite**：加载 Skill，跑 `scenario` → 检查 `assertion` 是否满足。
3. **判定**：

| naive 失败 | suite 通过 | 结论 |
|-----------|-----------|------|
| ✅ 失败 | ✅ 通过 | 规则有效，保留 |
| ✅ 失败 | ❌ 不通过 | 规则不够，补规则 |
| ❌ 不失败 | ✅ 通过 | 规则是装饰品，**删** |
| ❌ 不失败 | ❌ 不通过 | 场景本身无效，改场景 |

## 优先级

- **必须有**：analyzer / planner / architect / generator / tester / reviewer（核心 SDLC 链路）。
- **可选**：refactorer / documenter / releaser / orchestrator。

## 反例场景从哪来

1. 每条「核心原则」和「反例黑名单」都应该至少有一个 pressure test 对得上——没有测试的规则默认视为装饰品。
2. 从真实 benchmark 里找「Agent 做错了、Skill 本该拦住」的案例，反推成 scenario。
3. 场景要**具体到能复现**（给出真实文件结构/需求），不要抽象到「写一个功能」。
