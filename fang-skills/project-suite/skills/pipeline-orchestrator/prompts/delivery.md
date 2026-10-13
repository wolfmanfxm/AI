# Delivery — Pipeline Orchestrator

> @template: delivery

## Actions

1. 写入 `pipeline-state.json`（完整执行记录 + 每个 Skill 的 status/confidence）
2. 生成 `pipeline-report.md`：
   - Pipeline 名称 + 执行时间
   - 每个 Skill 的状态（completed/skipped/failed）+ confidence
   - 全链路 confidence 趋势
   - 上下文传递链完整性
   - 建议的下一步操作
3. 更新 `state.json`（追加 pipeline 执行历史）

4. （可选，用户点名触发）**Session Retro** — 仅在高信号场景（多轮修复才成功的 defect / 「声明但无 consumer」类 defect / 用户点名复盘）执行。按 [Session Retro 原语](../../../shared/primitives/session-retro.md) 的七类检查 agent 自身工作环境，发现作为修改建议交用户确认，不自动扩展规范、目录或 Runtime。

## Exit

- `pipeline-report.md` 写入成功
- `pipeline-state.json` 更新为 completed
- `state.json` 已追加

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
