# Session Retro — Suite Primitive v1.0.0

> Suite 一级「会话复盘」原语。一次编码会话结束后，复盘的不是业务代码，而是 **agent 自身的工作环境**——找出怎样让下次少走弯路。借鉴 Matt Pocock retro 思想。
> **disable-model-invocation**：用户点名触发，不自动调用。高信号场景才跑（见「触发条件」）。

## 定位：生产者 / 消费者

| 角色 | Skill | 职责 |
|------|-------|------|
| **Consumer** | pipeline-orchestrator（delivery 阶段，可选） / 用户点名独立触发 | 会话结束后走本复盘 |
| **Carrier（发现去路）** | check-\*.sh / confidence.yaml / reviewer rules / Instinct / steering / tool-adapters | retro 发现按类别路由到这些现有消费者，不新建平行体系 |

> 使用方式：在 orchestrator delivery 阶段 `[引用](../../../shared/primitives/session-retro.md)`，或用户点名「复盘 / retro」时直接走本原语。

## 为什么是 Suite 一级

本套件已有丰富的**设计时**验证（Existential Gate / Reuse Check / Confidence Gate），但缺一条**会话事后**的反向边：

```
现有 loop：Task → Project Knowledge（关于代码库）→ Instinct（关于代码库）
缺失边：  Session defect → Environment improvement（关于 agent 自身的检查 / 导航 / steering）
```

retro 补的就是这条反向边。它的核心动作不是改业务代码，而是问：「这次会话里，有没有一个本该提前发现问题的检查，没被运行或没被接入？」

> 这正是本套件反复出现的失败模式——「声明存在、但运行路径上无 consumer 执行」——把同一把刀递回给 agent 自身的检查体系：**一个已存在但没接进 pipeline 的 check，本身就是 finding。**

## 触发条件

不每次都跑（避免变负担）。仅以下高信号场景触发：

| 场景 | 信号 |
|------|------|
| 一次 defect 经历**多轮才修复成功** | 环境有障碍，值得复盘 |
| defect 属于「**声明但无 consumer**」类型（只改 declaration 不改 consumer / 规范已声明但无执行者） | 本套件最高频的假阳性，必复盘 |
| 用户点名「复盘 / retro / 复盘这次会话」 | 显式触发 |

低信号场景（单轮修好的普通 defect）直接跳过。

## 七类检查

每一类：先说「查什么」，再说「先查现有 carrier」原则，最后说「发现路由到哪」。

### 1. Navigation（导航）

> **查什么**：agent 找对文件是否费了太长时间？文件间是否有隐藏依赖？是否该加一个导航指针？
> **先查现有**：`.project-knowledge/graph.json`（模块/组件节点）+ `.project-knowledge/index.md`（导航表）+ analyzer 产出的 INDEX。
> **路由**：发现「找信息耗时」→ 在 knowledge index 补 / 修导航指针；隐藏依赖 → 标注到 graph.json 边。
> _触发信号：会话中长时间搜索才找到某条信息。_

### 2. Automated checks（自动检查）⚠️ 先查现有

> **查什么**：agent 犯的错，是否有现成检查本该拦住？
> **先查现有（retro 核心纪律）**：先读本仓库已有的检查命令——`shared/scripts/check-*.sh`（12 个）、`check-conformance.sh`、`command-guard.sh`、`confidence.yaml` gate 条件。**一个已存在但没接进 pipeline / 静默失效的 check，本身就是 finding，不是「再发明一个」的理由。** 仓库完全无 guardrail（无 pre-commit、无 CI 跑 lint/typecheck/test）本身就是 finding。
> **路由**：现有 check 未接线 → 接进 conformance gate；现有 check 静默失效 → 修；确无对应 check → 加到 `check-*.sh` 或 `confidence.yaml` gate 条件。
> _触发信号：agent 犯了一个本可被自动检查拦住的错。_

### 3. Coding standards（编码规范）⚠️ 先分类

> **查什么**：reviewer 是否漏抓了一个错？该加规则还是该加检查？
> **先分类（retro 核心纪律）**：违规分两类，处置路径不同——
>
> | 分类 | 特征 | 处置 |
> |------|------|------|
> | **机械性** | 固定语法模式、禁用 API、import 形状、文件位置规则 | **永远优先做成确定性 check**（`check-*.sh` / pre-commit / CI）。Default to building the check over writing the rule。不写进 doc 规则。 |
> | **判断性** | 跨文件一致性、「匹配周围风格」、无 guardrail 能替代 | 进 reviewer 的 `execution.md` 规则 或 analyzer Phase 7 Instinct（Always/Prefer/Avoid/Never → Playbook）。**在 review 时读，不在实现时读。** |
>
> **路由**：机械性 → `check-*.sh`（同类别 2 的 carrier）；判断性 → reviewer `execution.md` 规则 / Instinct。
> _触发信号：reviewer 漏抓了一个错。_

### 4. Global AGENTS.md（全局 steering）

> **查什么**：steering 文件（`CLAUDE.md` / skill 的 `SKILL.md` description）是否过大？是否有本该降级为检查或规范的具体指令还堆在 steering 里？
> **原则**：`CLAUDE.md` / `SKILL.md` description 被推入每个 agent 的 context，应**极度精简**，通常只放**导航指针**指向其它文件。具体规则降级到 reviewer 规则 / check；背景知识降级到 `docs/`。
> **路由**：过大 steering → 把具体指令降级到 check（机械）/ reviewer 规则（判断）/ docs，steering 只留导航指针。
> _触发信号：steering 文件明显过大。_

### 5. Tool economy（工具经济）

> **查什么**：agent 是否做了可精简的高成本工具调用？是否有 token 低效的自定义工具（CLI / MCP / adapter）？
> **先查现有**：`runtime/tool-adapters/`（Filesystem/Browser/Git/Network/Design）+ `command-guard.md`。
> **路由**：高成本调用 → 精简调用方式；adapter 模式 token 低效 → 标注到 tool-adapters 修订建议。
> _触发信号：agent 做了一次明显昂贵的工具调用。_
> ⚠️ 本类是本套件的小缺口——无显式 token 经济审计机制，发现优先交用户确认是否补。

### 6. No-ops（空指令）⚠️ 本套件招牌失败模式

> **查什么**：steering 文件里是否有**不改变 agent 行为**的指令？（声明了、写了、但运行路径上不执行。）
> **这是本套件最高频的假阳性来源**。CLAUDE.md 列的三条坑全是 No-ops：
> - 基座 `store.replaceState` 被注释（声明回填、运行时不执行）
> - fsc 的 `IS_MOCK` 整个 `if` 块被注释（声明守卫、运行时不执行）
> - fsc 没接 `$flowNodeConfig`（基座下发、opr 接了、fsc 没接 = 声明有 consumer、实际无）
>
> **路由**：死指令 → 删除，或接进真实 consumer（check / reviewer 规则 / 运行路径）。**不留「声明但无 consumer」的指令。**
> _触发信号：steering 文件大而臃肿，或 defect 属于「声明无 consumer」类型。_

### 7. Information access（信息获取）

> **查什么**：是否有本可获取但 agent 拿不到的关键信息？（dev server 日志未 tee、第三方服务无只读访问。）
> **先查现有**：`runtime/tool-adapters/` 的 Network / Browser adapter 能否补上。
> **路由**：关键信息不可达 → tee 日志、加只读访问（经 adapter），交用户确认。
> _触发信号：会话中某关键信息不可得，导致盲做。_

## 横切规则

### 机械 vs 判断（分类先于处置）

> 处置前**先分类**。机械性问题永远优先做成确定性 check，不写进 doc 规则——「Default to building the check over writing the rule」。判断性问题才进 reviewer 规则 / Instinct。两者不可混用：机械性塞进 doc 等于又造一个 No-op；判断性塞进 check 则 check 永远抓不全。

### Implementation vs Review（上下文压力）

> 所有工作经两阶段：implementation（上下文压力最大——探索 + 写码 + 调试）与 review（压力最小——只收 diff，不探索不写码）。因此**编码标准在 review 时施加，不在 implementation 时**。本套件已如此（reviewer 是标准执行者），retro 产生的新规则也走 reviewer，不加到 implementation 阶段的 context。

### 查现有 carrier 先于造新 carrier

> 每一类都先读现有检查 / 导航 / steering，确认「是否已存在但未接线」。**一个已存在但未接线的 carrier 本身就是 finding**——这把刀既适用于被审查的代码，也适用于 agent 自身的检查体系。不先查就造新 check / 新规则，等于在检查层重犯「声明无 consumer」的病。

## 输出格式

每次 retro 产出一条发现记录（对齐 Decision Record，交用户确认，不自动扩展）：

```markdown
Retro[发现]: <类别> — <一句话问题>
  类别: <Navigation|Automated checks|Coding standards|Global AGENTS.md|Tool economy|No-ops|Information access>
  分类: <机械性|判断性|不适用>
  查现有: <先查到的现有 check / carrier，或「无」>
  路由: <check-*.sh / confidence.yaml / reviewer rules / Instinct / steering 修订 / tool-adapters>
  建议: <最小改动建议，交用户确认>
```

## 与现有机制的关系

| 现有机制 | retro 的关系 |
|---------|-------------|
| Existential Gate / Reuse Check | 设计时防「声明无 consumer」；retro 是**会话事后**补这条边的反向版 |
| Confidence Gate | retro 的机械性发现可成为新 gate 条件 |
| analyzer Phase 7 Instinct | retro 的判断性发现路由到这里（Always/Prefer/Avoid/Never） |
| Decision Record（ADR） | retro 发现作为修改建议交用户确认，不自动写 ADR |

## 反例

| ❌ 反模式 | ✅ 正确做法 |
|-----------|-----------|
| 跳过「查现有 check」直接造新 check | 先审 `check-*.sh` 是否已存在但未接线 |
| 机械性问题写成 doc 规则 | 机械性永远优先做成确定性 check |
| 判断性问题塞进 check | 判断性才进 reviewer 规则 / Instinct |
| retro 发现自动扩展规范 / 目录 | 交用户确认，不自动改 |
| 每个 session 都跑 retro | 仅高信号场景触发（多轮修复 / 声明无 consumer 类 defect） |
| No-ops 发现留着不动 | 删除或接进真实 consumer，不留「声明无 consumer」指令 |
| 把 retro 发现再造一份与测试报告重复的证据 | 引用现有 Confidence Gate / check 结果，不重造 |
