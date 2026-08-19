# Delivery — Refactorer

> @template: delivery

## Actions

写入 `.project-knowledge/reports/REFACTOR.md`：
- **变更清单**（每个重构动作 + commit hash）
- **改善指标**（圈复杂度/行数/重复率/依赖深度 Before→After）
- **测试结果**（通过数/失败数/跳过数）
- **失败记录**（若有 revert，记录原因+教训）

## Exit

- `REFACTOR.md` 写入成功
- state.json 更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败 | 重试一次 |
