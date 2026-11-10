---
name: workflow-protocol
description: >
  project-suite 统一流程协议（Workflow Execution Protocol）。Skill 声明 stages: [...]，Host 按模板注入 Stage Contract。
  不重复 runtime/mechanisms/ 已有的 state machine / checkpoint / error recovery / confidence gate。
---

# Workflow Protocol

> Skill 声明 stages，Host 按模板注入 — Skill 只写 Actions/Exit/Failure，Entry/Input/Output/Recovery 由模板提供
> Suite 提供阶段契约（Protocol），Host 决定如何推进（见 [host-capability.md](../runtime/contracts/host-capability.md)）

## Knowledge Consumption（默认行为）

所有 Skill 启动时第一步：**Context Resolver** → 读 `knowledge-index.json` → 分桶 → 产出 `context-package.json` → 注入 curated knowledge。

```
Skill Discovery → Context Resolver → 读 knowledge-index.json → 分桶(constraints/knowledge/guidance) → context-package.json → 执行业务逻辑
```

- `.md` 为 Human View，`knowledge-index.json` + `graph.json` 为 Machine Source of Truth
- 知识（rules/decisions/patterns/components/api/experience/playbooks）走 Resolver 产出的 `context-package.json`；结构事实（组件/API/模块依赖）走 graph-query 直接查 `graph.json`
- ⚠️ Query API 是 Protocol：Resolver 未实现时，agent 降级读 knowledge-index.json/catalog.md 解析 query 语义
- ❌ **`knowledge-index.json` 缺失不是降级理由**：那是知识编译没做，不是 Resolver 不可用。
  先跑 `shared/scripts/knowledge-compiler.sh`；编译器拒绝（如 `compiler_enforced` 字段缺失）时，
  修数据或显式记录一次由用户确认的 degraded，**不得**把「绕过 Resolver 直接读 markdown」当成常规路径。

## 核心机制：Stage Template Injection

1. 在 `skill.yaml` 的 `interface.stages` 中声明阶段列表
2. SKILL.md 工作流表格引用 `prompts/<stage>.md`（业务逻辑）+ `@template:` 声明（模板）
3. Host 加载 `stage-templates/<name>.md`，自动注入 Entry/Input/Output/Recovery
4. Skill 只写 **Actions / Exit / Failure** 三个自定义字段

加载优先级：`@template:` 块 > 模板默认值 > skill.yaml interface。Skill 可覆盖模板任意字段。

### Workflow DSL（可选，机器可读）

Skill 可选择 `workflow.dsl.yaml`，Host 直接解析执行，跳过 prose 指令：

```yaml
stages:
  - { name: discovery, template: discovery, exit: [scope_confirmed], checkpoint: true, on_failure: ask }
  - { name: execution,  template: execution,  exit: [all_completed],   parallel: true,  retry: 1 }
  - { name: validation, template: validation, exit: [no_critical],     blocking: true }
```

→ [Schema](../shared/schemas/workflow.schema.json) · [Example](../runtime/registry/workflow.dsl.example.yaml)

### 模板目录

| 模板 | 适用 Skill |
|------|-----------|
| [discovery](references/stage-templates/discovery.md) | 全部 |
| [execution](references/stage-templates/execution.md) | 全部 |
| [validation](references/stage-templates/validation.md) | 全部 |
| [delivery](references/stage-templates/delivery.md) | analyzer, planner, architect, reviewer, refactorer, documenter, releaser |
| [code-audit](references/stage-templates/code-audit.md) | planner, architect |
| [graph-analysis](references/stage-templates/graph-analysis.md) | architect |

## Verification Contract（验证子流程，**非 Stage**）

> **Verify 不是 Stage。** 它是被某个 Stage 显式加载的**验证子流程**，不参与 stage progression。
> 因此三条硬约束：`stages` 里**不得**出现 `verify`；`stage-templates/` **不得**新增 `verify.md`；
> SKILL.md 工作流表**不得**出现 `Verify` 行（表行集合必须等于 `interface.stages`，见上方核心机制第 2 条）。

**检查项的唯一权威是各 skill 的 `prompts/validation.md`**（`## Checks` 表）。`prompts/verifier.md`
**不重复维护一份检查表**——它只定义**验证对象**（Candidate / 阶段产出）与**判定规则**，检查时引用同一张表。
（2026-09-18 收敛：此前 8/9 个 skill 的两个文件各有一份高度重复的检查表，改一处必忘另一处。）

`skill.yaml` 的 `verification.mode` 决定 `prompts/verifier.md` 的**加载点**（取值只有这三个）：

| mode | 含义 | 加载规则 |
|------|------|---------|
| `direct-verify` | 产出即终态，验证在 Validation 阶段做 | `verifier.md` **必须存在**；`validation.md` **必须加载**它 |
| `candidate-verify-accept` | 产出先成为 Candidate，验证通过才 Accept | `verifier.md` **必须存在**；Candidate 所在 Stage（通常 `execution.md`）**必须加载**它；且 verifier 必须在 Candidate 被 Accept / 下游消费**之前**完成 |
| `none` | 本 Skill 不产出需要独立验证的业务产物（如纯编排型） | `verifier.md` 可选；**不得**被要求 |

```
direct-verify                      candidate-verify-accept
  Execution                          Execution ─┬─ Candidate produced
      ↓                                       ├─ Verifier
  Validation                                  └─ Accepted / Rejected / Adjusted
   ├─ validation.md                               ↓
   └─ verifier.md   ← 加载点                  Validation
      ↓                                          ↓
  Delivery                                   Delivery
```

> ⚠️ **为什么必须写死这条**：2026-09-18 实测——8 个 SKILL.md 在工作流表里写了 `Verify` 行，
> 而 **10/10** 的 `skill.yaml` 的 `stages` 都不含 `verify`、`stage-templates/` 也没有 `verify.md`。
> Host 按下面的 `for each stage in interface.stages` 推进 → 这 8 个 `prompts/verifier.md`
> **运行时永不被加载**。这是「声明存在、但执行路径上找不到入口」的断链，与 `constraint` 字段
> 写了却读不到、`verification.mode` 声明了却零消费者属同一族。
>
> **通用原则**：任何「声明存在的行为」，都必须能沿 Host 的真实执行路径找到入口；
> 仅有文件、配置、计数、静态 ✅ 都不算可执行。

## Execution Guidance（阶段推进协议）

> **Host 按 Workflow Protocol 推进阶段** — Suite 定义阶段契约和推进规则，Host（Agent）决定实际如何执行。
> project-suite 是 Protocol，不是 Engine。本 Skill 提供阶段契约，不假装自己驱动阶段推进。
> 强制推进能力是 Host 的（见 [host-capability.md](../runtime/contracts/host-capability.md) 的 `stage_progression`）。

遵循 [execution-driver.md](references/execution-driver.md) 的阶段推进协议：

```
for each stage in interface.stages:
  ENTRY → LOAD(template+prompt) → EXECUTE(Actions) → EXIT(check) → ADVANCE
```

Skill 通过 `runtime/config/skill-policy.yaml` 的 `stage_config` **声明**每个 stage 的行为偏好（checkpoint/retry/parallel/blocking）。这些是**给 Host 的推进建议**，Host 决定是否强制执行。默认值即可覆盖 90% 场景。

## Terminal Record（终态记录契约）

> **每一次运行，在所有退出路径上，恰好写一行终态记录。** 这不是「Delivery 的一个步骤」，
> 而是运行的结束条件——运行在 Discovery 后结束，同样算一次运行。

适用范围：任何声明了 `stages` 的 Skill 运行，包括 Discovery 后短路（monitor-only / drift-check /
用户取消）、resume 跳过、门禁阻断、异常终止，以及被 hook 自动收尾的运行。

唯一入口（不要分别调用底层脚本）：

```bash
# Discovery 开始：任务解析/创建 + 单写者锁 + 运行指针
# 必须有运行身份：Claude Code 注入 CLAUDE_CODE_SESSION_ID；其他宿主显式传 --session-id
bash shared/scripts/runtime-run.sh start <project-root> --skill <name> \
  (--task-id <id> | --new-task --goal "...") [--slug ...] [--session-id <id>]

# 任意退出点：一行 timeline + 释放锁（**不关闭长期 Task**）
bash shared/scripts/runtime-run.sh finish <project-root> --skill <name> --status <status> \
  [--confidence <0-100>] [--reason "..."] [--notes "..."] [--session-id <id>] [--auto-finalized]
```

| status | 含义 | confidence |
|--------|------|-----------|
| `completed` | 产出完成且通过门禁 | **必填**（真实评分） |
| `degraded` | 产出可用但有已知缺口 / hook 自动收尾 | 0（未评估） |
| `blocked` | 门禁或前置条件阻断 | 0 |
| `failed` | 不可恢复错误 | 0 |
| `skipped` | 在产出前结束（monitor-only / 用户取消 / 无执行） | 0 |

**禁止**：
- 只写成功路径（失败/取消的运行会在指标里彻底消失）
- 直接调 `timeline-append.sh` / `writer-lock.sh`——`runId` 会与 `start` 不一致，甚至重复记账
- 用 prose 声明「已记录」而不调用脚本：审计以实际 `tool_use` 为准

> **`finish` 只结束 Run，不结束 Task。** 单次 Skill 完成不等于整个长期任务完成；
> `meta.status` 的 `completed` / `abandoned` 必须由编排方或用户显式
> `task-registry.sh set-status` 决定。`finish` 自动关任务会让同一任务的后续 Skill
> 在 Task Resolution 时找不到 active 任务，从而新建一个任务、切断 resume。
>
> Host 若声明 [`run_lifecycle`](../runtime/contracts/host-capability.md) 能力，应在**会话结束**时
> （Claude Code 用 `SessionEnd`，不是每轮触发的 `Stop`）对**本 session** 仍有运行指针的 skill 执行
> `finish --auto-finalized`，把「模型忘了收尾」变成可观测的 `degraded` 行。
> **Host 不负责 Start**：唯一调用 `runtime-run.sh start` 的是 Skill Discovery（Task Resolution 之后）；
> Hook / 宿主事件不创建 Task / Run。
> 收尾必须带 `--session-id`：指针记录了启动它的 session，别的 session 不得代收。
> Claude Code 会自动注入 `CLAUDE_CODE_SESSION_ID`，Skill 直接调 `finish` 即可；其他宿主必须显式传。
> 指针有 sessionId 而调用方没有 session 时 `finish` / `renew` / `start` 一律 fail-closed；
> **`start` 本身也要求 session 非空**——没有身份的 Run 无法被安全收尾，直接拒绝。
>
> **Dispatcher 类 Skill 例外**：`pipeline-orchestrator` 协调多个 Task，本身不创建自己的 Run，
> 因此不执行 Run 登记、不调用 `start`；但它必须在 Discovery 绑定一个目标 `task_id`
> （选择已有任务或经用户确认后新建），通过 `PS_TASK_ID` 传给后续 Skill，并只做路由与
> 根 `state.json` 的串行提交。判断标准：这个 Skill 有没有「属于自己的一个 Run」——
> 没有就按 Dispatcher 类处理，但仍要绑定目标 Task。

## 三大能力

| 能力 | 路径 |
|------|------|
| Stage Template Injection | 本文件 — Skill 声明 stages，Host 按模板注入阶段契约 |
| Validation | [references/validation.md](references/validation.md) — 5类检查 + validation-report |
| QA Sub-Agent | [references/qa-pattern.md](references/qa-pattern.md) — Main→QA→Reviewer 三明治 |

## 反例黑名单

> 禁止: ① 重复runtime/mechanisms已有能力 ② 替代SUITE_SPEC作为唯一权威 ③ 模板覆盖Skill全部字段 → [stage-contract.md](references/stage-contract.md)

## 与 runtime/mechanisms/ 的关系

workflow-protocol **不重复** runtime/mechanisms/ 已有能力：

| 能力 | 路径 |
|------|------|
| 状态机 / 断点续传 / 异常恢复 / 置信度门禁 | [runtime/mechanisms/](../runtime/mechanisms/) |

## 降级策略

模板文件不存在或无法加载 → Skill 自带完整 Contract 表格作为 Backward Compatibility。

## Registry-Driven Orchestration

Host 读取 `runtime/registry/` 自动发现 + 意图路由：

```
用户意图 → capability-routing.yaml (intent匹配)
         → capabilities.yaml (能力→Skill映射)
         → stage-library.yaml (验证合法性)
         → workflow-library.yaml (可选 pipeline)

skill.yaml produces/consumes → DAG auto-computed
```

新增 Skill 只需声明 `produces/consumes` + 在 capability-routing 注册 intent 映射。

## 引用索引

| 资源 | 路径 |
|------|------|
| Execution Driver | [references/execution-driver.md](references/execution-driver.md) |
| Stage Contract 规范 | [references/stage-contract.md](references/stage-contract.md) |
| Stage Templates | [references/stage-templates/](references/stage-templates/) |
| Stage Library | [../runtime/registry/stage-library.yaml](../runtime/registry/stage-library.yaml) |
| Workflow Library | [../runtime/registry/workflow-library.yaml](../runtime/registry/workflow-library.yaml) |
| Capability Registry | [../runtime/registry/capabilities.yaml](../runtime/registry/capabilities.yaml) |
| Validation 框架 | [references/validation.md](references/validation.md) |
| Event Bus | [../runtime/mechanisms/event-bus.md](../runtime/mechanisms/event-bus.md) + [show-events.sh](../shared/scripts/show-events.sh) |
| QA Sub-Agent 模式 | [references/qa-pattern.md](references/qa-pattern.md) |
| State Machine / Checkpoint / Error Recovery / Confidence Gate | [../runtime/mechanisms/](../runtime/mechanisms/) |
