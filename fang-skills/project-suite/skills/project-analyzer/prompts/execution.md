# Execution — Analyzer

> @engine: execution

## Actions

按 scope、mode 并行 spawn agent（每个维度一个独立 agent）。反例 → [references/anti-patterns.md](../references/anti-patterns.md)

### 维度表

| 维度 | 指南 | 输出 |
|------|------|------|
| 架构 | [prompts/architecture.md](architecture.md) | `overview.md` + `modules.md` `tech-stack.md` |
| 组件 | [prompts/components.md](components.md) | `catalog.md` |
| 编码 | [prompts/coding-style.md](coding-style.md) | `vue.md` `typescript.md` `naming.md` |
| UI | [prompts/ui-pattern.md](ui-pattern.md) | `table.md` `form.md` `dialog.md` |
| API | [prompts/api-pattern.md](api-pattern.md) | `overview.md` `request.md` |
| 模式 | [prompts/patterns.md](patterns.md) | `crud.md` 等 |
| 观察 | [prompts/observations.md](observations.md) | `statistics.md` |
| 变更 | [prompts/change-analysis.md](change-analysis.md) | `change-log.md`（详尽必选） |

### Agent 协调规则

- **禁止提前返回**：spawn 子 agent 必须等待全部完成后才返回
- **写入时机**：全部子任务完成 → 验证完整性 → 一次性写入所有产出文件
- **写入后验证**：`ls -la` 确认每个文件存在且 >100 bytes
- **写入失败处理**：重试一次 → 仍失败标注 `❌ FAILED: [原因]`，主流程兜底补写

### Agent Prompt 组装

每个维度 agent prompt 按 4 部分组装：
1. 任务描述（该维度分析什么）
2. 项目上下文（框架/路径别名/分层/命名空间）
3. 产出要求（路径/Evidence Header/最小节）
4. 失败处理（超时/空返回 → 标注 + 重试）

→ 详细模板：[prompts/output-format.md](output-format.md)

## Exit

- 所有维度 agent 返回结果（completed 或 gracefully failed）
- 产出文件已验证存在（每个 ≥100 bytes）
- `manifest.subtasks` 全部标记 completed/failed

## Failure

| Condition | Action |
|-----------|--------|
| 子 agent 超时 | 重试一次（同 agent 同 prompt）→ 仍失败标注 `❌ FAILED: [维度名] agent timeout`，主流程用已有信息补写该维度 |
| 子 agent 返回空 | 标注 `❌ FAILED: [维度名] empty response`，主流程补写 |
| 写入文件失败（权限/磁盘满） | 重试一次 → 仍失败标注 `❌ FAILED: [原因]`，不阻塞其他维度 |
| `.claude/CLAUDE.md` 不存在 | 直接生成 `.project-knowledge/`，路径别名/命名空间从 package.json + tsconfig 推断 |

## CHECKPOINT

Execution 维度表是所有 agent 的调度依据。可以按依赖分 Wave：架构 → 组件+API → 编码+UI+模式 → 观察+变更。
