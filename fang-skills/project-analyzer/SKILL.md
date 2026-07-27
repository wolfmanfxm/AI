---
name: project-analyzer
description: >
  分析软件项目并生成可复用的项目知识库，覆盖 8 个维度（标准模式 7 个 + 详尽模式 +1）。
  触发词见 references/trigger-words.md。
  产出: .project-knowledge/ + Knowledge Vault。仅写知识文件，不修改源码。
  不做: 业务需求分析、运行时分析、安全审计、性能基准、部署验证、代码重构、测试生成。
  mode: Production · owner: fangxm · review: 大版本发布前
  input_files: file-backed fixture [SKILL.md, protocol/*.md, prompts/*.md, references/*.md, schema/*.json, templates/**/*]
  output_contract: .project-knowledge/ + Knowledge Vault 同步
  rollback_boundary: git revert 到上一稳定版本, 已生成知识文件不受影响
---

## Quick Start

收到用户请求 → 按意图路由：

```
"分析/扫描/刷新"              → Analysis Flow（protocol/phase-1-discovery.md）
"继续分析/resume"             → Phase 2 Resume（protocol/phase-2-execution.md）
"新增/创建/实现/开发前检查"    → Development Flow（protocol/development-flow.md）
未匹配                         → 不触发本 skill，交由 trigger-words.md 排除规则判断
```

## Analysis Flow

```
analysis-config.json 不存在     → 🔴 CHECKPOINT: Phase 1 确认配置 → [protocol/phase-1-discovery.md]
manifest status = completed      → 🔴 CHECKPOINT: 询问 → 🔁全量刷新 / 📝增量更新 / ❌取消
manifest status = interrupted/
  partial / in_progress          → 🔴 CHECKPOINT: 确认恢复 → Phase 2 Resume: [protocol/phase-2-execution.md]
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
| Agent 接口契约 | [agents/interface.yaml](agents/interface.yaml) |
| 知识版本与生命周期 | [protocol/knowledge-protocol.md](protocol/knowledge-protocol.md) · [protocol/knowledge-lifecycle.md](protocol/knowledge-lifecycle.md) |
| 能力边界与覆盖策略 | [references/capability-matrix.md](references/capability-matrix.md) |
| 运行时约束与故障恢复 | [protocol/runtime-protocol.md](protocol/runtime-protocol.md) |
| 反例与禁止操作 | [references/anti-patterns.md](references/anti-patterns.md) |
| 步骤异常处理 | [references/exceptions.md](references/exceptions.md) |
| 触发词与排除规则 | [references/trigger-words.md](references/trigger-words.md) |
| 测试用例与验证 | [test-prompts.json](test-prompts.json) · [trigger_eval.py](trigger_eval.py) |
| Schemas | [schema/](schema/) |
| 模板与示例 | [templates/](templates/) · [examples/](examples/) |
| 信任与质量 | [reports/trust-report.md](reports/trust-report.md) · [reports/output_quality_scorecard.md](reports/output_quality_scorecard.md) |
| 变更记录 | [CHANGELOG.md](CHANGELOG.md) |
