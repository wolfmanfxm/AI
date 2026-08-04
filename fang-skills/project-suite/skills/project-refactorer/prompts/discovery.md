# Discovery — Refactorer

> @engine: discovery

## Actions

1. 识别坏味道：长函数（>50行）/ 重复代码 / 过深嵌套（>3层）/ God Class / 魔数
2. 确认测试覆盖：
   - 有现有测试 → 跑一遍看是否全绿
   - 无测试 → 先加表征测试（characterization test，记录当前行为）
3. 选重构手法：提取函数/提取组件/内联/简化条件/重命名/拆分模块 等 → [prompts/extract-method.md](extract-method.md)
4. CHECKPOINT — 展示坏味道清单 + 重构策略 + 测试状态

## Exit

- 坏味道清单已确认
- 测试全绿（或有表征测试保护）
- 重构策略已选定
- 用户确认重构范围

## Failure

| Condition | Action |
|-----------|--------|
| 无测试覆盖 | 先写表征测试 → 标注 `⚠️ 无测试保护`，缩小范围到纯提取/重命名 |
| 现有测试失败（重构前就不绿） | 🔴 BLOCK — 停止重构，建议先 `/project-tester` 修复 |

## CHECKPOINT

🔴 CHECKPOINT
