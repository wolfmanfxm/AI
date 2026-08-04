# Delivery — Planner

> @engine: delivery

## Actions

1. 写入 `.project-knowledge/proposals/PLAN-<feature>.md`（完整 9 模块 Contract）
2. 生成 `context-package.json`（预消化知识包，Generator 直接消费，无需读全量文件）：
   ```json
   {
     "plan": "PLAN-<feature>.md",
     "capabilities": ["VueConvention", "TablePattern", "FormPattern", "ApiPattern"],
     "knowledge": [...],
     "components": [...],
     "api": [...],
     "rules": [...]
   }
   ```
3. 写入 state.json（confidence + suggested_next）
4. 写入 timeline.json

## Exit

- `PLAN-<feature>.md` 9 模块完整且已写入
- `context-package.json` 已生成
- state.json 已更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败（权限/磁盘满） | 重试一次 → 仍失败标注 `❌ FAILED`，不阻塞其他产出 |
