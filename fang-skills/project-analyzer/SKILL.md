---
name: project-analyzer
description: >
  分析软件项目并生成可复用的项目知识库，覆盖 7 个维度（标准模式）。
  触发词见 references/trigger-words.md。
  产出: .project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
---

## Quick Start

收到用户请求 → 按意图路由：

```
"分析/扫描/刷新"              → Analysis Flow（protocol/phase-1-discovery.md）
"继续分析/resume"             → Phase 2 Resume（protocol/phase-2-execution.md）
"新增/创建/实现/开发前检查"    → Development Flow（protocol/development-flow.md）
```

## Analysis Flow

```
analysis-config.json 不存在     → Phase 1: [protocol/phase-1-discovery.md]
manifest status = completed      → 询问: 🔁全量刷新 / 📝增量更新 / ❌取消
manifest status = interrupted/
  partial / in_progress          → Phase 2 Resume: [protocol/phase-2-execution.md]
```

| 阶段 | 执行文件 |
|------|---------|
| Phase 1 发现 | [protocol/phase-1-discovery.md](protocol/phase-1-discovery.md) |
| Phase 2 执行 | [protocol/phase-2-execution.md](protocol/phase-2-execution.md) |
| Phase 2 收尾 | [protocol/phase-2-finish.md](protocol/phase-2-finish.md) |

## Development Flow

→ [protocol/development-flow.md](protocol/development-flow.md)

## References

| 资源 | 路径 |
|------|------|
| 维度 Prompts | [prompts/](prompts/) |
| 阶段协议 | [protocol/](protocol/) |
| 能力边界与覆盖策略 | [references/capability-matrix.md](references/capability-matrix.md) |
| 运行时约束与故障恢复 | [protocol/runtime-protocol.md](protocol/runtime-protocol.md) |
| 反例与禁止操作 | [references/anti-patterns.md](references/anti-patterns.md) |
| 步骤异常处理 | [references/exceptions.md](references/exceptions.md) |
| Schemas | [schema/](schema/) |
| 模板与示例 | [templates/](templates/) · [examples/](examples/) |
