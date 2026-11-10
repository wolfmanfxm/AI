# Delivery — Pipeline Orchestrator

> @template: delivery

## Actions

1. 写入 `runtime/tasks/<task_id>/pipeline-state.json`（完整执行记录 + 每个 Skill 的 status/confidence）
2. 生成 `runtime/tasks/<task_id>/pipeline-report.md`：
   - Pipeline 名称 + 执行时间
   - 每个 Skill 的状态（completed/skipped/failed）+ confidence
   - 全链路 confidence 趋势
   - 上下文传递链完整性
   - 建议的下一步操作
3. 作为 Dispatcher **串行提交**根 `state.json`（追加 pipeline 执行历史；同一项目同一时刻一个写者）

4. （可选，用户点名触发）**Session Retro** — 仅在高信号场景（多轮修复才成功的 defect / 「声明但无 consumer」类 defect / 用户点名复盘）执行。按 [Session Retro 原语](../../../shared/primitives/session-retro.md) 的七类检查 agent 自身工作环境，发现作为修改建议交用户确认，不自动扩展规范、目录或 Runtime。

## Exit

- `runtime/tasks/<task_id>/pipeline-report.md` 写入成功
- `runtime/tasks/<task_id>/pipeline-state.json` 更新为 completed
- 根 `state.json` 已由 Dispatcher 串行提交（history 带 task_id）

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
