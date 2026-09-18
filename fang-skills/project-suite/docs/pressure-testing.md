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

每个反例场景回答四个问题（存于外部 eval 仓库 `benchmark/pressure-tests/<skill>.yaml`，**不在 skill 目录内**——测试验证数据与 skill 本身能力无关，遵循「评估证据与治理契约分离」原则，见 [eval-contract.md](eval-contract.md)）：

| 字段 | 含义 |
|------|------|
| `scenario` | 具体任务 prompt（喂给 Agent） |
| `naive_failure` | 朴素 Agent 会怎么错（RED 的证据） |
| `skill_mechanism` | 哪条规则阻止了这个错误（GREEN 的机制） |
| `assertion` | 怎么判定 pass / fail |

> **命名约定**：文件名默认是 skill 名（`<skill>.yaml`）。**suite 级场景**（不隶属单个 skill，
> 如跨 skill 路由歧义）用 `cross-skill-routing.yaml`，其 `skill:` 字段写 `cross-skill`。

## 三层工件与统一词汇

> 行为评估是三层流水线，各层字段名不同但指向同一件事。**判定结论的唯一入口是 ledger**（`mechanism-verification-ledger.md`，位于外部 eval 仓库，字段与位置见 [eval-contract.md](eval-contract.md)）——本文件的 `naive_failure` / `assertion` 是「设计时预测」，ledger 的 `native_baseline` / `pass_fail` 是「运行时记录」。

| 层 | 文件 | 字段 | 含义 |
|----|------|------|------|
| 设计（预测） | `pressure-tests/<skill>.yaml` | `scenario` / `naive_failure` / `skill_mechanism` / `assertion` | 反例场景 + 预测 naive 会怎么错 + 哪条规则拦住 + 怎么判 |
| 运行（观察） | `results/*.yaml` | `native:` / `suite:` 块 | naive vs suite 真实跑出的产出对比 |
| 记录（判定） | `mechanism-verification-ledger.md` | `hypothesis` / `native_baseline` / `suite_behavior` / `evidence` / `repeatability` / `pass_fail` | 机制是否改变行为 + 可复现性 |

> `naive_failure`（预测）与 `native_baseline`（观察）是同一件事的「事前/事后」两态，不强行合并命名——但**判断有效性的结论只写在 ledger**，pressure-tests 只做场景定义。

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

### 硬约束：还原只能在所有 agent 回报之后（2026-09-18 加）

在目标项目上跑压力测试会在工作树里产生真实改动，跑完必须还原（切回原分支、清除产出、还原 `.project-knowledge`）。
**还原本身会改变工作区** —— 若此时还有 agent 在跑，它会看到自己的文件被删、行号被整体位移，
被迫重做，该 run 即**受污染**，结论不应与未受扰的 run 同等采信。

> **实证**：round14 中主试方在 4 个 agent 里最后一个仍在运行时执行了还原
> （`git checkout` + `rm -rf` + 还原知识库），导致该 agent 第一版产出被清除、
> 消费方行号从 `:85` 位移到 `:622`、被迫全量重写。**该 run 判定为受污染。**

**协议要求**：
1. **还原前必须确认所有并发 agent 均已终止**（等回报，不靠猜时间）。
2. 还原后**再验证一次**工作树，而不是假设「还原动作执行了 = 状态已还原」——
   本轮第一次还原后又被后续写入产生残留，是下一轮才发现的。
3. 并发跑多个 agent 时，在监控文档里**预先声明文件归属**，避免误判为冲突写入。

## 优先级

- **必须有**：analyzer / planner / architect / generator / tester / reviewer（核心 SDLC 链路）。
- **可选**：refactorer / documenter / releaser / orchestrator。

## 反例场景从哪来

1. 每条「核心原则」和「反例黑名单」都应该至少有一个 pressure test 对得上——没有测试的规则默认视为装饰品。
2. 从真实 benchmark 里找「Agent 做错了、Skill 本该拦住」的案例，反推成 scenario。
3. 场景要**具体到能复现**（给出真实文件结构/需求），不要抽象到「写一个功能」。
