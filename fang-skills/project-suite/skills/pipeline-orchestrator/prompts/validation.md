# Validation — Pipeline Orchestrator

> @engine: validation

## Checks

| # | Check | Method | On Failure |
|---|-------|--------|------------|
| V1 | 全链路产出完整 | pipeline 中每个 Skill 的产出文件存在 | 返回 Orchestrate 补执行 |
| V2 | 上下文传递正确 | 下游消费的上游产出文件存在且 valid | 标注 broken chain |
| V3 | Confidence 链完整 | 每个 Skill 的 confidence 已记录 | 标注缺失 |
| V4 | Pipeline state 一致 | pipeline-state.json 与实际执行一致 | 修正 state |

## QA Agent

全链路 pipeline → spawn 独立 agent 检查：
1. 每个 Skill 的产出是否满足下游的 `interface.inputs`
2. 是否有跳过的 Skill 影响了后续 Skill 的输入完整性
3. 整体 confidence 链是否健康

→ [qa-pattern](../../../workflow-engine/references/qa-pattern.md)

## Exit

无 CRITICAL 发现（全链路产出完整、上下文传递链未断裂）
