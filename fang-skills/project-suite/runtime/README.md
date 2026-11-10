# Runtime 协议导航

> 所有运行时协议的入口索引。理解 Skill 如何被调度、如何通信、如何恢复。

## 目录总览

| 目录 | 说明 |
|------|------|
| [mechanisms/](mechanisms/) | 执行引擎 — State · Checkpoint · Error · Confidence · Event · Approval · **Task Identity** · **Single Writer** |
| [registry/](registry/) | 能力注册 — Capability · Stage · Workflow · Routing · Extractor |
| [memory/](memory/) | 四级记忆 — Session · Project · Suite · Decision |
| [tool-adapters/](tool-adapters/) | 工具适配 — Filesystem · Browser · Git · Network · Design |
| [context/](context/) | 上下文协议 — context.json + priority + resolution + merge |
| [state/](state/) | 状态管理 — state.json + knowledge lifecycle |
| [contracts/](contracts/) | 接口契约 — Skill I/O + Context Package + Graph Query |
| [config/](config/) | 运行配置 — Scheduler + Gates |
| [metrics/](metrics/) | 指标追踪 — Timeline + Knowledge Health |
| [protocols/](protocols/) | 编排路由 — Orchestration + Routing |
| [artifacts/](artifacts/) | 产出物类型注册 |

## 快速导航

| 我想做什么 | 核心文件 |
|-----------|---------|
| 新增一个 Skill | [capabilities.yaml](registry/capabilities.yaml) → [skill-io.md](contracts/skill-io.md) |
| 了解 Skill 如何执行 | [state-machine.md](mechanisms/state-machine.md) → [execution-driver.md](../workflow-protocol/references/execution-driver.md) |
| 中断后恢复 | [checkpoint.md](mechanisms/checkpoint.md) → [error-recovery.md](mechanisms/error-recovery.md) |
| 多任务隔离 / 选任务 | [task-identity.md](mechanisms/task-identity.md) → [task-registry.sh](../shared/scripts/task-registry.sh) |
| 防止两个 Analyzer 互相覆盖 | [single-writer.md](mechanisms/single-writer.md) → [writer-lock.sh](../shared/scripts/writer-lock.sh) |
| 记录一次执行指标 | [metrics/timeline.md](metrics/timeline.md) → [runtime-run.sh](../shared/scripts/runtime-run.sh)（start / renew / finish） |
| 所有退出路径都留下终态记录 | [workflow-protocol/SKILL.md](../workflow-protocol/SKILL.md) 的 Terminal Record |
| 新增 Pipeline 模式 | [workflow-library.yaml](registry/workflow-library.yaml) |
| 新增能力类型 | [capabilities.yaml](registry/capabilities.yaml) → [capability-routing.yaml](registry/capability-routing.yaml) |
| 新增 Extractor | [extractor-registry.yaml](registry/extractor-registry.yaml) |
| 查询项目知识 | [graph-query.md](contracts/graph-query.md) → [knowledge-resolver.md](knowledge-resolver.md) |
| 理解整体架构 | [orchestration.md](protocols/orchestration.md) → [scheduler.md](mechanisms/scheduler.md) |
