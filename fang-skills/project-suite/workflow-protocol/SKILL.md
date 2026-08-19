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

所有 Skill 启动时第一步：**Context Resolver** → 按 skill.yaml 的 `context_contract.query` 语义类型 → 查询 `graph.json` → 注入 curated knowledge。

```
Skill Discovery → Context Resolver → 读 query 语义类型（patterns/components/architecture/api）→ Query graph.json → 注入 Top-K → 执行业务逻辑
```

- `.md` 为 Human View，`graph.json` 为 Machine Source of Truth
- 每个 Skill 在 `context_contract.query` 声明知识类型（语义），Context Resolver 消费（不直接读 .md）
- ⚠️ Query API 是 Protocol：Resolver 未实现时，agent 降级读 graph.json/catalog.md 解析 query 语义

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
