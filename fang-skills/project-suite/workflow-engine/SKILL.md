---
name: workflow-engine
description: >
  project-suite 统一流程引擎。Skill 只声明 stages: [...]，Engine 注入 Stage Contract 模板。
  不重复 runtime/engine/ 已有的 state machine / checkpoint / error recovery / confidence gate。
---

# Workflow Engine

> Skill 声明 stages，Engine 注入模板 — Skill 只写 Actions/Exit/Failure，Entry/Input/Output/Recovery 由模板提供

## Knowledge Consumption（默认行为）

所有 Skill 启动时第一步：**Context Resolver** → 查询 `knowledge-graph.yaml` → 注入 curated knowledge。

```
Skill Discovery → Context Resolver → Query knowledge-graph.yaml → 注入 Top-K → 执行业务逻辑
```

- `.md` 为 Human View，`knowledge-graph.yaml` 为 Machine Source of Truth
- 所有 Skill 默认通过 Query API 消费知识，不直接读 .md 文件

## 核心机制：Stage Template Injection

1. 在 `skill.yaml` 的 `interface.stages` 中声明阶段列表
2. SKILL.md 工作流表格引用 `prompts/<stage>.md`（业务逻辑）+ `@engine:` 声明（模板）
3. Engine 加载 `stage-templates/<name>.md`，自动注入 Entry/Input/Output/Recovery
4. Skill 只写 **Actions / Exit / Failure** 三个自定义字段

加载优先级：`@engine:` 块 > 模板默认值 > skill.yaml interface。Skill 可覆盖模板任意字段。

### Workflow DSL（可选，机器可读）

Skill 可选择 `workflow.dsl.yaml`，Engine 直接解析执行，跳过 prose 指令：

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

## Execution Driver

> **Engine 驱动阶段推进** — 不依赖 Claude 自行判断何时进入下一阶段

遵循 [execution-driver.md](references/execution-driver.md) 的执行循环：

```
for each stage in interface.stages:
  ENTRY → LOAD(template+prompt) → EXECUTE(Actions) → EXIT(check) → ADVANCE
```

Skill 通过 `interface.stage_config` 控制每个 stage 的行为（checkpoint/retry/parallel/blocking/auto_advance）。默认值即可覆盖 90% 场景。

## 三大能力

| 能力 | 路径 |
|------|------|
| Stage Template Injection | 本文件 — Skill 声明 stages，Engine 注入模板 |
| Validation | [references/validation.md](references/validation.md) — 5类检查 + validation-report |
| QA Sub-Agent | [references/qa-pattern.md](references/qa-pattern.md) — Main→QA→Reviewer 三明治 |

## 反例黑名单

> 禁止: ① 重复runtime/engine已有能力 ② 替代SUITE_SPEC作为唯一权威 ③ 模板覆盖Skill全部字段 → [stage-contract.md](references/stage-contract.md)

## 与 runtime/engine/ 的关系

workflow-engine **不重复** runtime/engine/ 已有能力：

| 能力 | 路径 |
|------|------|
| 状态机 / 断点续传 / 异常恢复 / 置信度门禁 | [runtime/engine/](../runtime/engine/) |

## 降级策略

模板文件不存在或无法加载 → Skill 自带完整 Contract 表格作为 Backward Compatibility。

## Registry-Driven Orchestration

Engine 读取 `runtime/registry/` 自动发现 + 意图路由：

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
| Event Bus | [../runtime/engine/event-bus.md](../runtime/engine/event-bus.md) + [show-events.sh](../shared/scripts/show-events.sh) |
| QA Sub-Agent 模式 | [references/qa-pattern.md](references/qa-pattern.md) |
| State Machine / Checkpoint / Error Recovery / Confidence Gate | [../runtime/engine/](../runtime/engine/) |
