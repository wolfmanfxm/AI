# Delivery — Planner

> @template: delivery

## Actions

> 前置：Discovery 已完成 Task Resolution，`task_id` 已知；后续所有路径用它。

1. 写入 `.project-knowledge/proposals/PLAN-<task_id>.md`（完整 Contract，含 `# Knowledge Constraints` 块——rules/decisions/relevant_patterns 的机器可读 ID 清单）
2. 调用 `knowledge-resolver.sh <kd> "<candidates>" --task <task_id>` 生成 `runtime/tasks/<task_id>/context-package.json`（预消化知识包，Generator 直接消费），
   传入 `candidates` = `# Reuse Analysis` 命中的 source 路径/capability（只 hydrate 命中集 + Top-K）：
   ```json
   {
     "plan": "PLAN-<task_id>.md",
     "taskId": "<task_id>",
     "context": {
       "rules": [ { "rule": "form-component-standard", "type": "rule", "constraint": "所有表单必须用 <统一表单封装> + <字段组件>", "blocking": true } ],
       "knowledge": [ { "capability": "patterns", "source": "patterns/table.md", "enforcement": "recommended" } ],
       "guidance": [ { "type": "experience", "source": "experience/xxx.md", "enforcement": "advisory" } ]
     }
   }
   ```
   > `# Knowledge Constraints` 与 context-package.json 的 rules[]/knowledge[] **同源**——Generator 交叉核对，不重猜。
3. 提交 State 更新建议（history 带 task_id + confidence + suggested_next；Dispatcher 统一写入根 state.json）
4. 写终态记录 + 释放锁（一个入口）：
   ```bash
   bash shared/scripts/runtime-run.sh finish <project-root> --skill project-planner \
     --status completed --confidence <0-100> [--notes "..."]
   ```
   失败/取消/阻断同样走它：`--status failed|blocked|skipped --reason "..."`

## Exit

- `proposals/PLAN-<task_id>.md` 9 模块完整且已写入
- `runtime/tasks/<task_id>/context-package.json` 已生成（包内 taskId == 当前 task_id）
- State 更新建议已产出（history 带 task_id；根 state.json 由 Dispatcher 提交）

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败（权限/磁盘满） | 重试一次 → 仍失败标注 `❌ FAILED`，不阻塞其他产出 |
