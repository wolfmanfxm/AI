# Delivery — Refactorer

> @template: delivery

## Actions

写入 `.project-knowledge/reports/REFACTOR-<task_id>.md`：
- **变更清单**（每个重构动作 + commit hash）
- **改善指标**（圈复杂度/行数/重复率/依赖深度 Before→After）
- **测试结果**（通过数/失败数/跳过数）
- **失败记录**（若有 revert，记录原因+教训）

## Exit

- `REFACTOR-<task_id>.md` 写入成功
- 提交 State 更新建议（Dispatcher 统一提交根 state.json）

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
